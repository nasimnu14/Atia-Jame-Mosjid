import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_service.dart';

class UpdateException implements Exception {
  UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Installs a downloaded update (UPD-2). Screens use this interface so tests
/// never download or install anything.
abstract class UpdateInstaller {
  Future<void> install(
    UpdateInfo info, {
    required void Function(double progress) onProgress,
  });
}

/// Starts a program that keeps running after this app exits.
typedef DetachedStart =
    Future<void> Function(String executable, List<String> args);

/// What happens for each platform:
///
/// - Windows: download the installer from the GitHub release, check its
///   SHA-256 if the release has one, start it (it closes this app, updates the
///   program files and starts the app again). The data lives in the app-data
///   folder, so the installer cannot touch it (UPD-3).
/// - Android (APK build): download the APK and hand it to Android's package
///   installer; the user confirms. Never used by the Google Play build (UPD-6).
/// - macOS (test build only): opens the release page.
///
/// Not proven on a real Windows PC or phone while building (see
/// docs/progress/accounts-app.md, Known gaps).
class PlatformUpdateInstaller implements UpdateInstaller {
  PlatformUpdateInstaller({
    http.Client? client,
    UpdatePlatform? platform,
    DetachedStart? startDetached,
    Future<Directory> Function()? tempDir,
    Future<void> Function(String apkPath)? openApk,
    Future<void> Function(String url)? openUrl,
    void Function()? exitApp,
  }) : _client = client ?? http.Client(),
       _platform = platform ?? UpdatePlatform.current,
       _startDetached = startDetached ?? _defaultStart,
       _tempDir = tempDir ?? getTemporaryDirectory,
       _openApk = openApk ?? _defaultOpenApk,
       _openUrl = openUrl ?? _defaultOpenUrl,
       _exitApp = exitApp ?? (() => exit(0));

  final http.Client _client;
  final UpdatePlatform _platform;
  final DetachedStart _startDetached;
  final Future<Directory> Function() _tempDir;
  final Future<void> Function(String) _openApk;
  final Future<void> Function(String) _openUrl;
  final void Function() _exitApp;

  static Future<void> _defaultStart(String exe, List<String> args) async {
    await Process.start(exe, args, mode: ProcessStartMode.detached);
  }

  static Future<void> _defaultOpenApk(String path) async {
    final r = await OpenFilex.open(
      path,
      type: 'application/vnd.android.package-archive',
    );
    if (r.type != ResultType.done) {
      throw UpdateException(r.message);
    }
  }

  static Future<void> _defaultOpenUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Future<void> install(
    UpdateInfo info, {
    required void Function(double progress) onProgress,
  }) async {
    if (_platform == UpdatePlatform.macos ||
        _platform == UpdatePlatform.other) {
      await _openUrl(info.releaseUrl);
      return;
    }
    final url = info.assetUrl;
    if (url == null) {
      // The release has no installer for this platform: show the release page.
      await _openUrl(info.releaseUrl);
      return;
    }
    final bytes = await _download(url, onProgress);
    if (info.sha256Url != null) {
      await _verify(bytes, info.sha256Url!);
    }
    final dir = await _tempDir();
    final file = File(
      p.join(dir.path, info.assetName ?? p.basename(Uri.parse(url).path)),
    );
    await file.writeAsBytes(bytes, flush: true);
    if (_platform == UpdatePlatform.windows) {
      await _startDetached(file.path, const [
        '/SILENT',
        '/NORESTART',
        '/CLOSEAPPLICATIONS',
        '/RESTARTAPPLICATIONS',
      ]);
      _exitApp();
    } else {
      await _openApk(file.path);
    }
  }

  Future<Uint8List> _download(
    String url,
    void Function(double) onProgress,
  ) async {
    try {
      final res = await _client.send(http.Request('GET', Uri.parse(url)));
      if (res.statusCode != 200) {
        throw UpdateException('Download failed (${res.statusCode})');
      }
      final total = res.contentLength ?? 0;
      final out = BytesBuilder(copy: false);
      var got = 0;
      await for (final chunk in res.stream) {
        out.add(chunk);
        got += chunk.length;
        if (total > 0) {
          onProgress(got / total);
        }
      }
      onProgress(1);
      return out.takeBytes();
    } on SocketException {
      throw UpdateException('No internet connection');
    } on http.ClientException catch (e) {
      throw UpdateException('Download failed: ${e.message}');
    }
  }

  Future<void> _verify(Uint8List bytes, String shaUrl) async {
    final res = await _client.get(Uri.parse(shaUrl));
    if (res.statusCode != 200) {
      throw UpdateException('Could not read the checksum (${res.statusCode})');
    }
    // "<hex>  filename" or just "<hex>".
    final expected = res.body.trim().split(RegExp(r'\s+')).first.toLowerCase();
    final actual = sha256.convert(bytes).toString();
    if (expected != actual) {
      throw UpdateException(
        'The downloaded file is damaged (checksum does not match)',
      );
    }
  }
}
