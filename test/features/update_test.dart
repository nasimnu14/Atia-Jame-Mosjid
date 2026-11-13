import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:atia_masjid_accounts/data/repositories/settings_repository.dart';
import 'package:atia_masjid_accounts/features/updates/app_version_number.dart';
import 'package:atia_masjid_accounts/features/updates/update_installer.dart';
import 'package:atia_masjid_accounts/features/updates/update_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/test_env.dart';

String release(
  String tag, {
  String body = '',
  List<(String, String)> assets = const [],
}) => jsonEncode({
  'tag_name': tag,
  'html_url': 'https://github.com/o/r/releases/tag/$tag',
  'body': body,
  'assets': [
    for (final (n, u) in assets) {'name': n, 'browser_download_url': u},
  ],
});

void main() {
  group('version numbers', () {
    AppVersion v(String s) => AppVersion.tryParse(s)!;
    test('parse, with or without v and build / pre-release parts', () {
      expect(v('1.2.3').toString(), '1.2.3');
      expect(v('v1.2.3').toString(), '1.2.3');
      expect(v('1.2.3+45').toString(), '1.2.3');
      expect(v('2.0.0-beta.1').preRelease, 'beta.1');
      expect(AppVersion.tryParse('banana'), isNull);
      expect(AppVersion.tryParse('1.2'), isNull);
    });
    test('compare numbers, not text', () {
      expect(v('1.10.0') > v('1.9.0'), isTrue);
      expect(v('1.0.10') > v('1.0.9'), isTrue);
      expect(v('2.0.0') > v('1.99.99'), isTrue);
      expect(v('1.3.0') > v('1.3.0'), isFalse);
      expect(v('1.2.0') == v('v1.2.0+9'), isTrue);
    });
    test('a pre-release is older than the final version', () {
      expect(v('1.3.0') > v('1.3.0-beta.2'), isTrue);
      expect(v('1.3.0-beta.2') > v('1.3.0-beta.1'), isTrue);
      expect(v('1.3.0-beta.1') > v('1.2.9'), isTrue);
    });
  });

  group('checking GitHub Releases (UPD-1)', () {
    Future<UpdateService> service(
      TestEnv env,
      String body, {
      int status = 200,
      String installed = '1.2.0',
      UpdatePlatform platform = UpdatePlatform.windows,
      String repo = 'o/r',
      bool play = false,
      Future<http.Response> Function(http.Request)? handler,
    }) async {
      return UpdateService(
        settings: env.settingsRepo,
        currentVersion: () async => installed,
        repo: repo,
        playStoreBuild: play,
        platform: platform,
        client: MockClient(
          handler ??
              (r) async => http.Response.bytes(utf8.encode(body), status),
        ),
        now: () => env.clock,
      );
    }

    test(
      'a newer release is reported, with this platform\'s installer',
      () async {
        final env = await TestEnv.create();
        final s = await service(
          env,
          release(
            'v1.3.0',
            assets: [
              ('Atia-Setup-1.3.0.exe', 'https://x/win.exe'),
              ('Atia-Setup-1.3.0.exe.sha256', 'https://x/win.sha'),
              ('atia-1.3.0.apk', 'https://x/a.apk'),
              ('atia-macos-1.3.0.zip', 'https://x/m.zip'),
            ],
          ),
        );
        final r = await s.check();
        expect(r.status, UpdateStatus.available);
        expect(r.info!.version.toString(), '1.3.0');
        expect(r.info!.assetUrl, 'https://x/win.exe');
        expect(r.info!.sha256Url, 'https://x/win.sha');
        expect(s.available, isNotNull);
        expect(await s.lastChecked(), env.clock);

        final android = await service(
          env,
          release(
            'v1.3.0',
            assets: [
              ('a.apk', 'https://x/a.apk'),
              ('w.exe', 'https://x/w.exe'),
            ],
          ),
          platform: UpdatePlatform.android,
        );
        expect((await android.check()).info!.assetUrl, 'https://x/a.apk');
      },
    );

    test('the same or an older release means up to date', () async {
      final env = await TestEnv.create();
      expect(
        (await (await service(env, release('v1.2.0'))).check()).status,
        UpdateStatus.upToDate,
      );
      expect(
        (await (await service(env, release('v1.1.9'))).check()).status,
        UpdateStatus.upToDate,
      );
    });

    test(
      'a later check clears the "available" mark once the app is updated',
      () async {
        final env = await TestEnv.create();
        final s = await service(env, release('v1.3.0'));
        await s.check();
        expect(s.available, isNotNull);
        final updated = await service(
          env,
          release('v1.3.0'),
          installed: '1.3.0',
        );
        expect((await updated.check()).status, UpdateStatus.upToDate);
        expect(updated.available, isNull);
      },
    );

    test('no release published yet (404) is not an error', () async {
      final env = await TestEnv.create();
      expect(
        (await (await service(env, '', status: 404)).check()).status,
        UpdateStatus.upToDate,
      );
    });

    test(
      'failures are reported, never thrown: server error, no internet, rubbish',
      () async {
        final env = await TestEnv.create();
        expect(
          (await (await service(env, '', status: 500)).check()).status,
          UpdateStatus.failed,
        );
        final offline = await service(
          env,
          '',
          handler: (r) async => throw const SocketException('down'),
        );
        final r = await offline.check();
        expect(r.status, UpdateStatus.failed);
        expect(r.error, contains('internet'));
        expect(
          (await (await service(env, 'not json')).check()).status,
          UpdateStatus.failed,
        );
        expect(
          (await (await service(env, release('weekly-build'))).check()).status,
          UpdateStatus.failed,
        );
      },
    );

    test('not set up (no repository) says so and makes no request', () async {
      final env = await TestEnv.create();
      var called = false;
      final s = await service(
        env,
        '',
        repo: '',
        handler: (r) async {
          called = true;
          return http.Response('', 200);
        },
      );
      expect((await s.check()).status, UpdateStatus.notConfigured);
      expect(called, isFalse);
    });

    test(
      'UPD-6: the Google Play build of the phone app never checks or downloads',
      () async {
        final env = await TestEnv.create();
        var called = false;
        final s = await service(
          env,
          release('v9.9.9'),
          platform: UpdatePlatform.android,
          play: true,
          handler: (r) async {
            called = true;
            return http.Response('', 200);
          },
        );
        expect((await s.check()).status, UpdateStatus.disabled);
        expect(called, isFalse);
        expect(s.canInstallInApp, isFalse);
        // The Play flag does not affect the desktop.
        final desktop = await service(env, release('v1.3.0'), play: true);
        expect((await desktop.check()).status, UpdateStatus.available);
        expect(desktop.canInstallInApp, isTrue);
      },
    );

    test('checkIfDue looks once a day', () async {
      final env = await TestEnv.create();
      var calls = 0;
      final s = await service(
        env,
        '',
        handler: (r) async {
          calls++;
          return http.Response(release('v1.2.0'), 200);
        },
      );
      await s.checkIfDue();
      await s.checkIfDue();
      expect(calls, 1);
      env.clock = env.clock.add(const Duration(hours: 25));
      await s.checkIfDue();
      expect(calls, 2);
      expect(
        await env.settingsRepo.get(SettingKey.lastUpdateCheckAt),
        isNotNull,
      );
    });

    test(
      'release notes: Bangla and English sections, or the same text for both',
      () {
        final (bn, en) = UpdateService.splitNotes(
          '## বাংলা\nনতুন ছবি দেখার সুবিধা\n\n## English\nPhoto viewer improved\n',
        );
        expect(bn, 'নতুন ছবি দেখার সুবিধা');
        expect(en, 'Photo viewer improved');
        final (a, b) = UpdateService.splitNotes('Bug fixes');
        expect((a, b), ('Bug fixes', 'Bug fixes'));
        final (c, d) = UpdateService.splitNotes('## English\nOnly English');
        expect((c, d), ('Only English', 'Only English'));
      },
    );
  });

  group('installing (UPD-2)', () {
    final payload = Uint8List.fromList(
      List<int>.generate(5000, (i) => i % 256),
    );
    UpdateInfo info({String? sha}) => UpdateInfo(
      version: AppVersion.tryParse('1.3.0')!,
      notesBn: '',
      notesEn: '',
      releaseUrl: 'https://github.com/o/r/releases/tag/v1.3.0',
      assetUrl: 'https://x/Atia-Setup-1.3.0.exe',
      assetName: 'Atia-Setup-1.3.0.exe',
      sha256Url: sha,
    );

    MockClient files(String shaText) => MockClient.streaming((req, _) async {
      if (req.url.path.endsWith('.sha256')) {
        final b = utf8.encode(shaText);
        return http.StreamedResponse(
          Stream.value(b),
          200,
          contentLength: b.length,
        );
      }
      return http.StreamedResponse(
        Stream.fromIterable([payload.sublist(0, 2000), payload.sublist(2000)]),
        200,
        contentLength: payload.length,
      );
    });

    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('atia_upd_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test(
      'Windows: downloads, checks the checksum, starts the installer, exits the app',
      () async {
        String? started;
        List<String>? args;
        var exited = false;
        final progress = <double>[];
        final installer = PlatformUpdateInstaller(
          client: files('${sha256.convert(payload)}  Atia-Setup-1.3.0.exe'),
          platform: UpdatePlatform.windows,
          startDetached: (exe, a) async {
            started = exe;
            args = a;
          },
          tempDir: () async => tmp,
          exitApp: () => exited = true,
        );
        await installer.install(
          info(sha: 'https://x/Atia-Setup-1.3.0.exe.sha256'),
          onProgress: progress.add,
        );
        expect(
          File(started!).readAsBytesSync(),
          payload,
        ); // the real downloaded file
        expect(
          args,
          containsAll([
            '/SILENT',
            '/CLOSEAPPLICATIONS',
            '/RESTARTAPPLICATIONS',
          ]),
        );
        expect(exited, isTrue);
        expect(progress.last, 1.0);
        expect(progress.first, lessThan(1.0));
      },
    );

    test(
      'a download that does not match its checksum is refused and nothing starts',
      () async {
        var started = false;
        final installer = PlatformUpdateInstaller(
          client: files(
            '0000000000000000000000000000000000000000000000000000000000000000',
          ),
          platform: UpdatePlatform.windows,
          startDetached: (e, a) async => started = true,
          tempDir: () async => tmp,
          exitApp: () => fail('must not exit'),
        );
        await expectLater(
          installer.install(
            info(sha: 'https://x/a.sha256'),
            onProgress: (_) {},
          ),
          throwsA(
            isA<UpdateException>().having(
              (e) => e.message,
              'message',
              contains('checksum'),
            ),
          ),
        );
        expect(started, isFalse);
      },
    );

    test('a failed download throws a clear error', () async {
      final installer = PlatformUpdateInstaller(
        client: MockClient.streaming(
          (r, _) async => http.StreamedResponse(const Stream.empty(), 404),
        ),
        platform: UpdatePlatform.windows,
        tempDir: () async => tmp,
        exitApp: () => fail('must not exit'),
      );
      await expectLater(
        installer.install(info(), onProgress: (_) {}),
        throwsA(isA<UpdateException>()),
      );
      final offline = PlatformUpdateInstaller(
        client: MockClient.streaming(
          (r, _) async => throw const SocketException('down'),
        ),
        platform: UpdatePlatform.windows,
        tempDir: () async => tmp,
      );
      await expectLater(
        offline.install(info(), onProgress: (_) {}),
        throwsA(
          isA<UpdateException>().having(
            (e) => e.message,
            'm',
            contains('internet'),
          ),
        ),
      );
    });

    test(
      'Android: the APK is handed to the package installer, the app is not closed',
      () async {
        String? apk;
        final installer = PlatformUpdateInstaller(
          client: files(''),
          platform: UpdatePlatform.android,
          openApk: (path) async => apk = path,
          tempDir: () async => tmp,
          exitApp: () => fail('must not exit'),
        );
        await installer.install(info(), onProgress: (_) {});
        expect(File(apk!).readAsBytesSync(), payload);
      },
    );

    test(
      'macOS test build and releases without an installer only open the release page',
      () async {
        final opened = <String>[];
        final mac = PlatformUpdateInstaller(
          platform: UpdatePlatform.macos,
          openUrl: (u) async => opened.add(u),
        );
        await mac.install(info(), onProgress: (_) {});
        final noAsset = PlatformUpdateInstaller(
          platform: UpdatePlatform.windows,
          openUrl: (u) async => opened.add(u),
        );
        await noAsset.install(
          UpdateInfo(
            version: AppVersion.tryParse('1.3.0')!,
            notesBn: '',
            notesEn: '',
            releaseUrl: 'https://r',
          ),
          onProgress: (_) {},
        );
        expect(opened, [
          'https://github.com/o/r/releases/tag/v1.3.0',
          'https://r',
        ]);
      },
    );
  });
}
