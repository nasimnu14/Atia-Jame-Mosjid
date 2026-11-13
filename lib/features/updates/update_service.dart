import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/repositories/settings_repository.dart';
import 'app_version_number.dart';

enum UpdatePlatform {
  windows,
  macos,
  android,
  other;

  static UpdatePlatform get current {
    if (Platform.isWindows) {
      return UpdatePlatform.windows;
    }
    if (Platform.isMacOS) {
      return UpdatePlatform.macos;
    }
    if (Platform.isAndroid) {
      return UpdatePlatform.android;
    }
    return UpdatePlatform.other;
  }
}

/// A newer version found on GitHub Releases (UPD-1).
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.notesBn,
    required this.notesEn,
    required this.releaseUrl,
    this.assetUrl,
    this.assetName,
    this.sha256Url,
  });
  final AppVersion version;
  final String notesBn;
  final String notesEn;

  /// The release page (always set).
  final String releaseUrl;

  /// The installer for this platform (Windows .exe, Android .apk), if the
  /// release has one.
  final String? assetUrl;
  final String? assetName;

  /// A `<asset>.sha256` file next to the installer, if the release has one.
  final String? sha256Url;
}

enum UpdateStatus { upToDate, available, failed, notConfigured, disabled }

class UpdateCheck {
  const UpdateCheck(this.status, {this.info, this.error});
  final UpdateStatus status;
  final UpdateInfo? info;
  final String? error;
}

/// Looks for a newer version on GitHub Releases (UPD-1).
///
/// The repository comes from `--dart-define=GITHUB_REPO=owner/name`. The
/// Google Play build (`--dart-define=PLAY_STORE_BUILD=true`) never checks and
/// never downloads: it updates only through Google Play (UPD-6).
class UpdateService extends ChangeNotifier {
  UpdateService({
    required this.settings,
    required this.currentVersion,
    this.repo = const String.fromEnvironment('GITHUB_REPO'),
    this.playStoreBuild = const bool.fromEnvironment('PLAY_STORE_BUILD'),
    UpdatePlatform? platform,
    http.Client? client,
    this.now = DateTime.now,
  }) : platform = platform ?? UpdatePlatform.current,
       _client = client ?? http.Client();

  final SettingsRepository settings;

  /// The installed version, e.g. "1.2.0".
  final Future<String> Function() currentVersion;
  final String repo;
  final bool playStoreBuild;
  final UpdatePlatform platform;
  final http.Client _client;
  final DateTime Function() now;

  /// Set when the last check found a newer version.
  UpdateInfo? available;
  bool _checking = false;

  bool get isConfigured => repo.isNotEmpty;

  /// The Google Play version of the Android app must not update itself.
  bool get isDisabledByStore =>
      playStoreBuild && platform == UpdatePlatform.android;

  /// Whether a new version can be installed from inside the app.
  bool get canInstallInApp =>
      !isDisabledByStore &&
      (platform == UpdatePlatform.windows ||
          platform == UpdatePlatform.android);

  Future<DateTime?> lastChecked() =>
      settings.getDateTime(SettingKey.lastUpdateCheckAt);

  /// Asks GitHub for the latest release and compares it with the installed
  /// version.
  Future<UpdateCheck> check() async {
    if (isDisabledByStore) {
      return const UpdateCheck(UpdateStatus.disabled);
    }
    if (!isConfigured) {
      return const UpdateCheck(UpdateStatus.notConfigured);
    }
    if (_checking) {
      return UpdateCheck(
        available == null ? UpdateStatus.upToDate : UpdateStatus.available,
        info: available,
      );
    }
    _checking = true;
    try {
      final res = await _client
          .get(
            Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
            headers: const {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 404) {
        // No release published yet.
        await settings.setDateTime(SettingKey.lastUpdateCheckAt, now());
        available = null;
        notifyListeners();
        return const UpdateCheck(UpdateStatus.upToDate);
      }
      if (res.statusCode != 200) {
        return UpdateCheck(
          UpdateStatus.failed,
          error: 'GitHub answered ${res.statusCode}',
        );
      }
      final json =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final latest = AppVersion.tryParse('${json['tag_name']}');
      final installed = AppVersion.tryParse(await currentVersion());
      if (latest == null || installed == null) {
        return UpdateCheck(
          UpdateStatus.failed,
          error:
              'Unreadable version: ${json['tag_name']} / ${await currentVersion()}',
        );
      }
      await settings.setDateTime(SettingKey.lastUpdateCheckAt, now());
      if (latest > installed) {
        available = parseRelease(json, latest);
        notifyListeners();
        return UpdateCheck(UpdateStatus.available, info: available);
      }
      available = null;
      notifyListeners();
      return const UpdateCheck(UpdateStatus.upToDate);
    } on SocketException {
      return const UpdateCheck(
        UpdateStatus.failed,
        error: 'No internet connection',
      );
    } on http.ClientException catch (e) {
      return UpdateCheck(
        UpdateStatus.failed,
        error: 'No internet connection ($e)',
      );
    } catch (e) {
      return UpdateCheck(UpdateStatus.failed, error: '$e');
    } finally {
      _checking = false;
    }
  }

  /// At start-up: look once a day, quietly (a failure is not shown).
  Future<void> checkIfDue() async {
    final last = await lastChecked();
    if (last != null && now().difference(last) < const Duration(hours: 24)) {
      return;
    }
    await check();
  }

  /// Turns the GitHub release JSON into an [UpdateInfo] for this platform.
  @visibleForTesting
  UpdateInfo parseRelease(Map<String, dynamic> json, AppVersion version) {
    final assets = [
      for (final a in (json['assets'] as List? ?? const []))
        (name: '${a['name']}', url: '${a['browser_download_url']}'),
    ];
    bool wants(String name) {
      final n = name.toLowerCase();
      return switch (platform) {
        UpdatePlatform.windows => n.endsWith('.exe'),
        UpdatePlatform.android => n.endsWith('.apk'),
        UpdatePlatform.macos => n.endsWith('.zip') && n.contains('mac'),
        UpdatePlatform.other => false,
      };
    }

    final asset = assets.where((a) => wants(a.name)).firstOrNull;
    final sha = asset == null
        ? null
        : assets.where((a) => a.name == '${asset.name}.sha256').firstOrNull;
    final (bn, en) = splitNotes('${json['body'] ?? ''}');
    return UpdateInfo(
      version: version,
      notesBn: bn,
      notesEn: en,
      releaseUrl: '${json['html_url'] ?? 'https://github.com/$repo/releases'}',
      assetUrl: asset?.url,
      assetName: asset?.name,
      sha256Url: sha?.url,
    );
  }

  /// Release notes are written as two sections, "## বাংলা" and "## English".
  /// Without those headings the whole text is used for both languages.
  @visibleForTesting
  static (String bn, String en) splitNotes(String body) {
    final text = body.replaceAll('\r\n', '\n').trim();
    final head = RegExp(r'^#{1,3}\s*(.+)$', multiLine: true);
    String? bn, en;
    final matches = head.allMatches(text).toList();
    for (var i = 0; i < matches.length; i++) {
      final title = matches[i][1]!.toLowerCase();
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final section = text.substring(matches[i].end, end).trim();
      if (title.contains('বাংলা') ||
          title.contains('bangla') ||
          title.contains('bengali')) {
        bn = section;
      } else if (title.contains('english')) {
        en = section;
      }
    }
    return (bn ?? en ?? text, en ?? bn ?? text);
  }
}
