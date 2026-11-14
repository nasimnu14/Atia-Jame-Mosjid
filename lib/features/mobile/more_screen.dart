import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/context_ext.dart';
import '../../shared/role_text.dart';
import '../../shared/widgets/basics.dart';
import '../reports/pdf_report_screen.dart';
import '../settings/settings_screen.dart';
import '../updates/update_card.dart';
import '../sync/sync_scan_screen.dart';

/// "More" on the phone: language, own password, sync, PDF, version, sign out.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String? _version;
  int _pending = 0;
  StreamSubscription<void>? _sub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sub == null) {
      final s = context.services;
      s.updates.currentVersion().then((v) {
        if (mounted) {
          setState(() => _version = v);
        }
      });
      _sub = s.entries.changes.listen((_) => _loadPending());
      _loadPending();
    }
  }

  Future<void> _loadPending() async {
    final n = await context.services.syncClient.pendingCount();
    if (mounted) {
      setState(() => _pending = n);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final user = context.appWatch.user!;
    Widget row(String label, String value, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          radius: 14,
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.incomeSoft,
                child: Text(
                  user.name.characters.first,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${roleName(l, user.role)} · ${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          radius: 14,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                row(
                  l.language,
                  context.appWatch.bangla ? l.langBangla : l.langEnglish,
                  () => context.app.setLanguage(!context.app.bangla),
                ),
                row(
                  l.changePassword,
                  '',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(l.myPassword)),
                        body: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // The desktop is the master copy of accounts (SYN-10).
                              MessageBanner(l.phonePasswordNote),
                              const SizedBox(height: 14),
                              const PasswordCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                row(
                  l.scanTitle,
                  _pending == 0 ? '' : l.pendingLeft(fmt.integer(_pending)),
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SyncScanScreen()),
                  ),
                ),
                row(
                  l.navPdf,
                  '',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PdfReportScreen()),
                  ),
                ),
                row(l.appVersionLabel, fmt.digits(_version ?? '…'), null),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // UPD-1, UPD-2: the phone too is told about a new version and can
        // install it from here.
        const UpdateCard(),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: context.app.signOut,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            foregroundColor: AppColors.cancelledText,
            side: const BorderSide(color: Color(0xFFE5B3B5)),
          ),
          child: Text(
            l.signOut,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
