import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:atia_masjid_accounts/app/app.dart';
import 'package:atia_masjid_accounts/app/app_services.dart';
import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/data/db_opener.dart';
import 'package:atia_masjid_accounts/data/photo_storage.dart';
import 'package:atia_masjid_accounts/features/sync/sync_client.dart';
import 'package:atia_masjid_accounts/features/sync/sync_offer.dart';
import 'package:atia_masjid_accounts/features/sync/sync_receiver.dart';
import 'package:atia_masjid_accounts/features/sync/sync_server.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:atia_masjid_accounts/data/repositories/settings_repository.dart';
import 'package:atia_masjid_accounts/features/google_drive/drive_client.dart';
import 'package:atia_masjid_accounts/features/updates/update_installer.dart';
import 'package:atia_masjid_accounts/features/updates/update_service.dart';
import 'package:atia_masjid_accounts/features/entries/photo_picker.dart';
import 'package:atia_masjid_accounts/shared/file_saver.dart';
import 'package:atia_masjid_accounts/shared/password_hasher.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Runs the real app on an in-memory database. Real async work (database,
/// password hashing in an isolate) happens inside `tester.runAsync`.
class AppHarness {
  AppHarness(this.tester, this.services, this.dir, [this._reopen]);
  final WidgetTester tester;
  final AppServices services;
  final Directory dir;
  final Future<AppServices> Function()? _reopen;

  static Future<AppHarness> start(
    WidgetTester tester, {
    Size size = const Size(1400, 900),
    PhotoPicker? picker,
    FileSaver? saver,
    DateTime? now,
    DriveAuth? driveAuth,
    UpdateService Function(SettingsRepository settings)? updatesBuilder,
    UpdateInstaller? updateInstaller,
    bool? isPhone,
    Future<SyncHost> Function(SyncReceiver receiver)? syncHostFactory,
    SyncClient Function(
      AppDatabase db,
      PhotoStorage photos,
      SettingsRepository settings,
    )?
    syncClientBuilder,

    /// Keep the database in a real file (needed for the restore flow).
    bool onDisk = false,
  }) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('atia_widget_');
    final fileSaver = saver ?? FakeFileSaver();
    Future<AppServices> build() async => AppServices.fromDatabase(
      onDisk
          ? await openAppDatabase(
              dir,
              // In the same isolate, so nothing needs real time to pass.
              factory: (f) => AppDatabase(NativeDatabase(f)),
            )
          : AppDatabase(NativeDatabase.memory()),
      dir,
      hasher: const PasswordHasher(logRounds: 4),
      now: now == null ? DateTime.now : () => now,
      photoPicker: picker ?? const PlatformPhotoPicker(),
      fileSaver: fileSaver,
      driveAuth: driveAuth,
      updatesBuilder: updatesBuilder,
      updateInstaller: updateInstaller,
      isPhone: isPhone ?? false,
      useCameraScanner: false,
      syncHostFactory: syncHostFactory,
      syncClientBuilder: syncClientBuilder,
    );
    final services = (await tester.runAsync(build))!;
    final h = AppHarness(tester, services, dir, onDisk ? build : null);
    addTearDown(() async {
      await tester.runAsync(() => h.currentServices.close());
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    return h;
  }

  /// The services in use now (they are replaced after a restore).
  late AppServices currentServices = services;

  Future<AppServices> _wrapReopen() async {
    currentServices = await _reopen!();
    return currentServices;
  }

  final _shotKey = GlobalKey();

  Future<void> launch() async {
    await _loadFonts();
    await tester.pumpWidget(
      RepaintBoundary(
        key: _shotKey,
        child: AtiaApp(
          services: services,
          reopen: _reopen == null ? null : _wrapReopen,
        ),
      ),
    );
    await settle();
  }

  static Future<void> _loadFonts() => loadTestFonts();

  /// Saves a PNG of the screen to `$SHOT_DIR/NAME.png` when SHOT_DIR is set
  /// (used to look at screens by eye; does nothing otherwise).
  Future<void> shot(String name) async {
    final dir = Platform.environment['SHOT_DIR'];
    if (dir == null) return;
    await settle(2);
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(dir).createSync(recursive: true);
      File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  /// Runs real async work (a database or Drive call) and then pumps, so screens
  /// that listen for changes finish reloading inside the test's fake clock
  /// before the next real-async call (otherwise they would hold the database
  /// lock and the test would wait forever).
  Future<T?> run<T>(Future<T> Function() work) async {
    // First let any reload a screen started after the previous UI action finish.
    await settle(3);
    final r = await tester.runAsync(work);
    await settle(4);
    return r;
  }

  /// Pumps until [finder] matches something (or gives up after [maxRounds]).
  Future<void> settleUntil(Finder finder, {int maxRounds = 300}) async {
    for (var i = 0; i < maxRounds && finder.evaluate().isEmpty; i++) {
      await settle(1);
    }
  }

  /// Lets real async work finish, then renders.
  Future<void> settle([int rounds = 4]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> tapText(String text) async {
    final f = find.text(text).first;
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await settle();
  }

  Future<void> enter(Finder f, String text) async {
    await tester.enterText(f, text);
    await tester.pump();
  }
}

/// Like `testWidgets`, but unmounts the app at the end and lets Drift's
/// stream clean-up timers run, so the test does not fail on pending timers.
void testApp(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, timeout: const Timeout(Duration(seconds: 90)), (
    tester,
  ) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}

/// A photo picker for tests: hands back the bytes it was given.
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker(this.photos);
  List<Uint8List> photos;
  @override
  Future<List<Uint8List>> pick(
    BuildContext context, {
    required int maxCount,
  }) async => photos.take(maxCount).toList();
}

bool _fontsLoaded = false;

/// The bundled Bangla font and the Material icon font, so screenshots and PDFs
/// look like the real app instead of boxes.
Future<void> loadTestFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  final hind = FontLoader('HindSiliguri');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    hind.addFont(
      Future.value(
        File(
          'assets/fonts/HindSiliguri-$w.ttf',
        ).readAsBytesSync().buffer.asByteData(),
      ),
    );
  }
  await hind.load();
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      final l = FontLoader('MaterialIcons')
        ..addFont(Future.value(icons.readAsBytesSync().buffer.asByteData()));
      await l.load();
    }
  }
}

/// A file saver for tests: remembers what would have been saved.
class FakeFileSaver implements FileSaver {
  final saved = <({String name, String extension, Uint8List bytes})>[];

  /// When true, behaves like the user pressing Cancel in the save dialog.
  bool cancel = false;

  @override
  Future<String?> save(
    BuildContext context, {
    required String suggestedName,
    required Uint8List bytes,
    required String extension,
    required String mimeType,
  }) async {
    if (cancel) return null;
    saved.add((name: suggestedName, extension: extension, bytes: bytes));
    return '/fake/$suggestedName.$extension';
  }
}

/// An update installer for tests: remembers what it was asked to install.
class FakeUpdateInstaller implements UpdateInstaller {
  final installed = <UpdateInfo>[];
  Object? failWith;

  @override
  Future<void> install(
    UpdateInfo info, {
    required void Function(double progress) onProgress,
  }) async {
    onProgress(0.5);
    if (failWith != null) {
      throw failWith!;
    }
    installed.add(info);
    onProgress(1);
  }
}

/// A sync server stand-in for screens: no network port; tests push events.
class FakeSyncHost implements SyncHost {
  FakeSyncHost() {
    _offer = _make();
  }
  final _events = StreamController<SyncEvent>.broadcast();
  late SyncOffer _offer;
  SyncOffer get offer => _offer;
  bool started = false;
  bool stopped = false;
  int made = 0;

  SyncOffer _make() => SyncOffer.generate(
    host: '192.168.1.20',
    port: 40000 + (made++),
    desktopName: 'PC',
  );

  @override
  Stream<SyncEvent> get events => _events.stream;

  void emit(SyncEvent e) => _events.add(e);

  @override
  Future<SyncOffer> start() async {
    started = true;
    return _offer;
  }

  @override
  SyncOffer newOffer() {
    _offer = _make();
    _events.add(OfferChanged(_offer));
    return _offer;
  }

  @override
  Future<void> stop() async => stopped = true;
}

/// An HTTP client that hands requests straight to a shelf handler (no socket).
class InProcessHttp extends http.BaseClient {
  InProcessHttp(this.handler);
  final shelf.Handler handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().toBytes();
    final res = await handler(
      shelf.Request(
        request.method,
        request.url,
        body: body,
        headers: request.headers,
      ),
    );
    final out = await res.read().expand((c) => c).toList();
    return http.StreamedResponse(
      Stream.value(out),
      res.statusCode,
      contentLength: out.length,
      headers: res.headers,
    );
  }
}
