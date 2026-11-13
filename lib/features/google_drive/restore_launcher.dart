import 'package:flutter/material.dart';

import '../../shared/context_ext.dart';
import '../../shared/widgets/basics.dart';
import '../sign_in/language_switch.dart';
import 'restore_panel.dart';

/// The first-launch "restore from a Google Drive backup" screen (USR-3, BAK-6).
Future<void> openRestoreFlow(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => const RestoreScreen()));

class RestoreScreen extends StatelessWidget {
  const RestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.setupRestoreTitle),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: LanguageSwitch()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.setupRestoreDesc,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const RestorePanel(firstLaunch: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
