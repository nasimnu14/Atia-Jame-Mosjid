import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'drive_client.dart';

/// The real Google Drive connection (BAK-1, BAK-8).
///
/// NOT verified against real Google in development: no Google credentials were
/// available. It follows Google's documented desktop ("installed app") OAuth
/// flow. See docs/setup-notes.md for creating the Google Cloud project and the
/// OAuth client, and for the one-time check to do with a real account.
///
/// Only the `drive.file` permission is requested: the app can see only the
/// files it created itself (plan Section 1, Risk 3).
class GoogleDriveAuth implements DriveAuth {
  GoogleDriveAuth({
    this.clientId = const String.fromEnvironment('GOOGLE_CLIENT_ID'),
    this.clientSecret = const String.fromEnvironment('GOOGLE_CLIENT_SECRET'),
    FlutterSecureStorage? storage,
  }) : _storage =
           storage ??
           const FlutterSecureStorage(
             // The macOS test build is unsigned, so it cannot use the shared
             // data-protection keychain.
             mOptions: MacOsOptions(usesDataProtectionKeychain: false),
           );

  /// Set at build time: `--dart-define=GOOGLE_CLIENT_ID=...`.
  final String clientId;
  final String clientSecret;
  final FlutterSecureStorage _storage;

  static const _key = 'google_drive_credentials';
  static const _scopes = [drive.DriveApi.driveFileScope];

  @override
  bool get isConfigured => clientId.isNotEmpty;

  ClientId get _id =>
      ClientId(clientId, clientSecret.isEmpty ? null : clientSecret);

  @override
  Future<DriveClient?> restore() async {
    if (!isConfigured) return null;
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final creds = AccessCredentials.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final client = autoRefreshingClient(_id, creds, http.Client());
      client.credentialUpdates.listen(_save);
      return await _wrap(client);
    } on DriveException catch (e) {
      // No internet is not a lost sign-in: say so, so it is tried again later.
      if (e.offline) rethrow;
      return null;
    } catch (_) {
      return null; // revoked or expired: the user connects again
    }
  }

  @override
  Future<DriveClient> connect() async {
    if (!isConfigured) {
      throw DriveException('Google sign-in is not set up in this build.');
    }
    try {
      final client = await clientViaUserConsent(_id, _scopes, (url) async {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      });
      await _save(client.credentials);
      client.credentialUpdates.listen(_save);
      return await _wrap(client);
    } on SocketException {
      throw DriveException('No internet connection', offline: true);
    } catch (e) {
      throw DriveException('Google sign-in failed: $e');
    }
  }

  @override
  Future<void> disconnect() => _storage.delete(key: _key);

  Future<void> _save(AccessCredentials c) =>
      _storage.write(key: _key, value: jsonEncode(c.toJson()));

  Future<DriveClient> _wrap(AuthClient client) async {
    final api = drive.DriveApi(client);
    final about = await _guard(
      () => api.about.get($fields: 'user(emailAddress)'),
    );
    return GoogleDriveClient(api, about.user?.emailAddress ?? '');
  }
}

Future<T> _guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on SocketException {
    throw DriveException('No internet connection', offline: true);
  } on http.ClientException {
    throw DriveException('No internet connection', offline: true);
  } on drive.DetailedApiRequestError catch (e) {
    throw DriveException('Google Drive: ${e.message ?? e.status}');
  }
}

/// [DriveClient] on top of Google's Drive v3 API.
class GoogleDriveClient implements DriveClient {
  GoogleDriveClient(this._api, this.accountEmail);
  final drive.DriveApi _api;
  @override
  final String accountEmail;

  static const _folderMime = 'application/vnd.google-apps.folder';

  static String _q(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

  @override
  Future<String> ensureFolder(
    String name, {
    String? parentId,
  }) => _guard(() async {
    final parent = parentId == null ? '' : " and '${_q(parentId)}' in parents";
    final found = await _api.files.list(
      q: "name = '${_q(name)}' and mimeType = '$_folderMime' and trashed = false$parent",
      spaces: 'drive',
      $fields: 'files(id)',
    );
    final id = found.files?.firstOrNull?.id;
    if (id != null) return id;
    final made = await _api.files.create(
      drive.File(
        name: name,
        mimeType: _folderMime,
        parents: parentId == null ? null : [parentId],
      ),
      $fields: 'id',
    );
    return made.id!;
  });

  @override
  Future<DriveFile> upload({
    required String folderId,
    required String name,
    required Uint8List bytes,
    required String mimeType,
  }) => _guard(() async {
    final f = await _api.files.create(
      drive.File(name: name, parents: [folderId]),
      uploadMedia: drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: mimeType,
      ),
      $fields: 'id,name,createdTime,size',
    );
    return _toFile(f);
  });

  @override
  Future<List<DriveFile>> list(String folderId) => _guard(() async {
    final out = <DriveFile>[];
    String? page;
    do {
      final r = await _api.files.list(
        q: "'${_q(folderId)}' in parents and trashed = false and mimeType != '$_folderMime'",
        orderBy: 'createdTime desc',
        pageSize: 1000,
        pageToken: page,
        spaces: 'drive',
        $fields: 'nextPageToken,files(id,name,createdTime,size)',
      );
      out.addAll((r.files ?? const []).map(_toFile));
      page = r.nextPageToken;
    } while (page != null);
    return out;
  });

  @override
  Future<Uint8List> download(String fileId) => _guard(() async {
    final media =
        await _api.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  });

  @override
  Future<void> delete(String fileId) => _guard(() => _api.files.delete(fileId));

  static DriveFile _toFile(drive.File f) => DriveFile(
    id: f.id!,
    name: f.name ?? '',
    createdTime: f.createdTime ?? DateTime.now(),
    size: f.size == null ? null : int.tryParse(f.size!),
  );
}
