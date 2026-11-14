import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'sync_crypto.dart';
import 'sync_offer.dart';
import 'sync_receiver.dart';

/// What the Sync screen needs from the desktop's sync server (so screens can be
/// tested without opening a network port).
abstract class SyncHost {
  Stream<SyncEvent> get events;
  Future<SyncOffer> start();

  /// A fresh code; the previous one stops working.
  SyncOffer newOffer();
  Future<void> stop();
}

sealed class SyncEvent {
  const SyncEvent();
}

/// A new QR code is ready (the old one was used or replaced).
class OfferChanged extends SyncEvent {
  const OfferChanged(this.offer);
  final SyncOffer offer;
}

class PhoneConnected extends SyncEvent {
  const PhoneConnected(this.phoneName);
  final String phoneName;
}

class EntryReceived extends SyncEvent {
  const EntryReceived(this.phoneName, this.entries, this.photos);
  final String phoneName;
  final int entries;
  final int photos;
}

class SyncFinished extends SyncEvent {
  const SyncFinished({
    required this.phoneName,
    required this.entries,
    required this.photos,
    required this.duplicates,
    required this.income,
    required this.expense,
  });
  final String phoneName;
  final int entries;
  final int photos;
  final int duplicates;
  final int income;
  final int expense;
}

class _Session {
  _Session(this.id, this.crypto, this.phoneName, this.lastSeen)
    : startedAt = lastSeen;
  final DateTime startedAt;
  final String id;
  final SyncCrypto crypto;
  final String phoneName;
  DateTime lastSeen;
  int entries = 0, photos = 0, duplicates = 0, income = 0, expense = 0;
}

/// The small server inside the desktop app that phones sync with. It runs only
/// while the Sync screen is open (plan Section 1) and only on the local network.
///
/// - The QR code carries a one-time key and token. The first phone to present
///   the token gets a session; the token is then spent and a new code is made,
///   so each QR code works for one sync only (SYN-3).
/// - Everything is sealed with the key (AES-GCM): nothing readable is sent
///   over the Wi-Fi, and any change is detected (Risk 7).
/// - Phones can send entries and fetch accounts. The server has no way to send
///   entries to a phone (SYN-6).
class SyncServer implements SyncHost {
  SyncServer({
    required this.receiver,
    required this.desktopName,
    required this.hostAddress,
    this.bindAddress,
    this.now = DateTime.now,
    this.sessionTtl = const Duration(minutes: 10),
    this.random,
  });

  final SyncReceiver receiver;
  final String desktopName;

  /// The address phones should use (shown in the QR code).
  final String hostAddress;

  /// Which address to listen on; all network cards by default.
  final InternetAddress? bindAddress;
  final DateTime Function() now;
  final Duration sessionTtl;
  final Random? random;

  HttpServer? _server;
  SyncOffer? _offer;
  final _sessions = <String, _Session>{};
  final _events = StreamController<SyncEvent>.broadcast();
  static const _maxBody = 64 * 1024 * 1024;

  @override
  Stream<SyncEvent> get events => _events.stream;
  bool get isRunning => _server != null;

  /// The code to show now.
  SyncOffer get offer => _offer!;
  int get port => _server!.port;

  /// Starts listening and makes the first code.
  @override
  Future<SyncOffer> start() async {
    _server = await shelf_io.serve(
      _handle,
      bindAddress ?? InternetAddress.anyIPv4,
      0,
    );
    return newOffer();
  }

  /// For tests: makes the first code without opening a network port; requests
  /// are then passed to [handler] directly.
  Future<SyncOffer> startInProcess() async => newOffer();

  /// The request handler (public so tests can call it without a socket).
  Handler get handler => _handle;

  /// A fresh code; the previous one stops working.
  @override
  SyncOffer newOffer() {
    _offer = SyncOffer.generate(
      host: hostAddress,
      port: _server?.port ?? 1,
      desktopName: desktopName,
      random: random,
    );
    _events.add(OfferChanged(_offer!));
    return _offer!;
  }

  @override
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _offer = null;
    _sessions.clear();
    await _events.close();
  }

  // ---------------------------------------------------------------- requests

  Future<Response> _handle(Request req) async {
    if (req.method != 'POST') {
      return Response(405);
    }
    final path = req.url.path;
    // Refuse a huge body before reading it (nothing is trusted yet).
    final declared = req.contentLength;
    if (declared != null && declared > _maxBody) {
      return Response(413);
    }
    final Uint8List body;
    try {
      body = await _readBody(req);
    } on _TooBig {
      return Response(413);
    }
    try {
      if (path == 'hello') {
        return await _hello(body);
      }
      final session = _session(req.headers['x-session']);
      if (session == null) {
        return Response(401);
      }
      final Map<String, dynamic> msg;
      try {
        msg = await session.crypto.openJson(body, aad: path);
      } on SyncAuthException {
        return Response(401);
      }
      session.lastSeen = now();
      switch (path) {
        case 'accounts':
          return await _reply(session, path, await receiver.accountsPayload());
        case 'entry':
          final r = await receiver.receiveEntry(msg);
          if (!r.alreadyHad) {
            session.entries++;
            session.photos += r.photos;
            if (r.duplicate) {
              session.duplicates++;
            }
            (msg['entry']['type'] == 'income')
                ? session.income++
                : session.expense++;
            await _record(session);
            _events.add(
              EntryReceived(session.phoneName, session.entries, session.photos),
            );
          }
          return await _reply(session, path, r.toJson());
        case 'done':
          _sessions.remove(session.id);
          await _record(session);
          _events.add(
            SyncFinished(
              phoneName: session.phoneName,
              entries: session.entries,
              photos: session.photos,
              duplicates: session.duplicates,
              income: session.income,
              expense: session.expense,
            ),
          );
          return await _reply(session, path, {'ok': true});
        default:
          return Response(404);
      }
    } on SyncRejectedException catch (e) {
      return Response(422, body: e.message);
    } catch (_) {
      return Response(500);
    }
  }

  /// SYN-3: only a phone that has scanned the current code, and only once.
  Future<Response> _hello(Uint8List body) async {
    final o = _offer;
    if (o == null) {
      return Response(401);
    }
    final crypto = SyncCrypto(o.key);
    final Map<String, dynamic> msg;
    try {
      msg = await crypto.openJson(body, aad: 'hello');
    } on SyncAuthException {
      return Response(401);
    }
    if (msg['token'] != o.token) {
      return Response(401);
    }
    // Spend the code at once, before anything else is awaited: a second phone
    // that used the same code at the same moment must be refused (SYN-3).
    if (!identical(_offer, o)) {
      return Response(401);
    }
    newOffer();
    final id = _newId();
    final phone = '${msg['phoneName'] ?? ''}'.trim();
    final session = _Session(
      id,
      crypto,
      phone.isEmpty ? 'Phone' : phone,
      now(),
    );
    _sessions[id] = session;
    await _record(session);
    _events.add(PhoneConnected(session.phoneName));
    return _reply(session, 'hello', {'session': id, 'desktop': desktopName});
  }

  Future<void> _record(_Session s) => receiver.recordSession(
    sessionId: s.id,
    phoneName: s.phoneName,
    startedAt: s.startedAt,
    entries: s.entries,
    photos: s.photos,
    duplicates: s.duplicates,
  );

  _Session? _session(String? id) {
    if (id == null) {
      return null;
    }
    final s = _sessions[id];
    if (s == null) {
      return null;
    }
    if (now().difference(s.lastSeen) > sessionTtl) {
      _sessions.remove(id);
      return null;
    }
    return s;
  }

  Future<Response> _reply(
    _Session s,
    String path,
    Map<String, dynamic> json,
  ) async => Response.ok(
    await s.crypto.sealJson(json, aad: 'res:$path'),
    headers: {'content-type': 'application/octet-stream'},
  );

  String _newId() {
    final r = random ?? Random.secure();
    return base64Url.encode(List<int>.generate(18, (_) => r.nextInt(256)));
  }

  Future<Uint8List> _readBody(Request req) async {
    final out = BytesBuilder(copy: false);
    await for (final chunk in req.read()) {
      out.add(chunk);
      if (out.length > _maxBody) {
        throw _TooBig();
      }
    }
    return out.takeBytes();
  }
}

class _TooBig implements Exception {}
