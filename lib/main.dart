import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/app_services.dart';
import 'app/startup_error.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // App data lives in the per-user app-data folder, never in the install
    // folder, so installing an update cannot touch it (plan rule 1).
    final dir = await getApplicationSupportDirectory();
    final services = await AppServices.open(dir);
    runApp(
      AtiaApp(
        services: services,
        reopen: () => AppServices.open(dir),
        // Backups and Excel uploads run on the computer, not the phone.
        runDriveJobs: Platform.isWindows || Platform.isMacOS,
        checkUpdates: true,
        seedBuiltInAdmin: Platform.isWindows || Platform.isMacOS,
      ),
    );
  } catch (e) {
    runApp(StartupErrorApp(error: e));
  }
}
