import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/context_ext.dart';
import 'sync_client.dart';

/// Shown after a sync: what was sent and that the entries are now view-only
/// (SYN-5, SYN-7, SYN-10).
class SyncDoneScreen extends StatelessWidget {
  const SyncDoneScreen({super.key, required this.report});
  final SyncReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    Widget item(String title, String note) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 20, color: AppColors.income),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  note,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 88,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                l.syncDoneTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.syncDoneSub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.mutedStrong,
                ),
              ),
              const SizedBox(height: 20),
              if (report.entriesSent > 0) ...[
                item(
                  l.syncDoneSent(
                    fmt.integer(report.entriesSent),
                    fmt.integer(report.photosSent),
                  ),
                  l.syncDoneKinds(
                    fmt.integer(report.income),
                    fmt.integer(report.expense),
                  ),
                ),
                item(l.syncDoneReadOnly, l.syncDoneReadOnlyNote),
              ],
              item(l.syncDoneAccounts, l.syncDoneAccountsNote),
              const Spacer(),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                child: Text(l.backHome, style: const TextStyle(fontSize: 17)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
