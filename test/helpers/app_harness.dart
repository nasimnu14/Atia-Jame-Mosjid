import 'dart:io';
import 'dart:ui' as ui;

import 'package:atia_masjid_accounts/app/app.dart';
import 'package:atia_masjid_accounts/app/app_services.dart';
import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/shared/password_hasher.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the real app on an in-memory database. Real async work (database,
/// password hashing in an isolate) happens inside `tester.runAsync`.
class AppHarness {
  AppHarness(this.tester, this.services, this.dir);
  final WidgetTester tester;
  final AppServices services;
  final Directory dir;

  static Future<AppHarness> start(WidgetTester tester,
      {Size size = const Size(1400, 900)}) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('atia_widget_');
    final services = (await tester.runAsync(() => AppServices.fromDatabase(
        AppDatabase(NativeDatabase.memory()), dir,
        hasher: const PasswordHasher(logRounds: 4))))!;
    final h = AppHarness(tester, services, dir);
    addTearDown(() async {
      await tester.runAsync(() => services.close());
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    return h;
  }

  final _shotKey = GlobalKey();

  Future<void> launch() async {
    await _loadFonts();
    await tester.pumpWidget(RepaintBoundary(
        key: _shotKey, child: AtiaApp(services: services)));
    await settle();
  }

  static bool _fontsLoaded = false;

  /// The bundled Bangla font and the Material icon font, so screenshots look
  /// like the real app instead of boxes.
  static Future<void> _loadFonts() async {
    if (_fontsLoaded) return;
    _fontsLoaded = true;
    final hind = FontLoader('HindSiliguri');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      hind.addFont(Future.value(File('assets/fonts/HindSiliguri-$w.ttf')
          .readAsBytesSync()
          .buffer
          .asByteData()));
    }
    await hind.load();
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final icons = File(
          '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
      if (icons.existsSync()) {
        final l = FontLoader('MaterialIcons')
          ..addFont(Future.value(icons.readAsBytesSync().buffer.asByteData()));
        await l.load();
      }
    }
  }

  /// Saves a PNG of the screen to `$SHOT_DIR/NAME.png` when SHOT_DIR is set
  /// (used to look at screens by eye; does nothing otherwise).
  Future<void> shot(String name) async {
    final dir = Platform.environment['SHOT_DIR'];
    if (dir == null) return;
    await settle(2);
    final boundary = _shotKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(dir).createSync(recursive: true);
      File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  /// Lets real async work finish, then renders.
  Future<void> settle([int rounds = 4]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> tapText(String text) async {
    await tester.tap(find.text(text).first);
    await settle();
  }

  Future<void> enter(Finder f, String text) async {
    await tester.enterText(f, text);
    await tester.pump();
  }
}

/// Like `testWidgets`, but unmounts the app at the end and lets Drift's
/// stream clean-up timers run, so the test does not fail on pending timers.
void testApp(String description, Future<void> Function(WidgetTester tester) body) {
  testWidgets(description, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
