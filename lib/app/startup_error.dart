import 'package:flutter/material.dart';

import '../data/db_opener.dart';
import 'theme.dart';

/// Shown when the database cannot be opened (for example, data from a newer
/// version, or an upgrade that failed and was rolled back). The data on disk
/// is left untouched. Shown in both languages because no setting can be read.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final String bn;
    final String en;
    if (error is DatabaseTooNewException) {
      bn =
          'এই সংস্করণের চেয়ে নতুন সংস্করণের ডেটা পাওয়া গেছে। অনুগ্রহ করে অ্যাপের সর্বশেষ সংস্করণ ইনস্টল করুন। আপনার ডেটা অক্ষত আছে।';
      en =
          'The data on this computer was made by a newer version of the app. Please install the latest version. Your data is untouched.';
    } else if (error is MigrationFailedException) {
      bn =
          'ডেটা আপগ্রেড করা যায়নি। আগের ডেটা ফিরিয়ে রাখা হয়েছে। আগের সংস্করণ আবার ইনস্টল করুন, অথবা ডেভেলপারকে জানান।';
      en =
          'The data upgrade failed and the previous data was put back. Reinstall the previous version, or tell the developer.';
    } else {
      bn = 'অ্যাপ চালু করা যায়নি।';
      en = 'The app could not start.';
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.cancelledText,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    bn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    en,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    '$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
