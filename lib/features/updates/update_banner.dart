import 'package:flutter/material.dart';

import '../../shared/context_ext.dart';
import '../../shared/widgets/basics.dart';
import 'update_dialog.dart';

/// Shown on the dashboard when the daily check found a newer version.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return ListenableBuilder(
      listenable: s.updates,
      builder: (context, _) {
        final info = s.updates.available;
        if (info == null) {
          return const SizedBox.shrink();
        }
        final l = context.l10n;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                child: MessageBanner(
                  l.updateBanner(context.fmt.digits(info.version.toString())),
                  kind: BannerKind.info,
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () async {
                  final installed = await s.updates.currentVersion();
                  if (context.mounted) {
                    await showUpdateDialog(context, info, installed);
                  }
                },
                child: Text(l.updateBannerAction),
              ),
            ],
          ),
        );
      },
    );
  }
}
