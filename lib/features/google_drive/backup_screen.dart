import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../shared/context_ext.dart';
import '../../shared/permissions.dart';
import '../../shared/widgets/basics.dart';
import 'connect_google.dart';
import 'restore_panel.dart';

/// Google account, the 4-hourly backup and restore (BAK-1 to BAK-8). Admin and
/// Super Admin only; restore is for the Super Admin only.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  String? _account;
  DateTime? _last;
  DateTime? _next;
  String? _error;
  List<DriveLogData> _log = const [];
  StreamSubscription<void>? _sub;
  Timer? _tick;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sub == null) {
      final s = context.services;
      _sub = s.drive.logChanges.listen((_) => _load());
      // Keeps "next backup" fresh while the page is open.
      _tick = Timer.periodic(const Duration(seconds: 30), (_) => _load());
      _load();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final s = context.services;
    final account = await s.drive.accountEmail();
    final last = await s.backup.lastSuccess();
    final next = await s.backup.nextDue();
    final error = await s.backup.lastError();
    final log = await s.drive.recentLog(['backup'], limit: 6);
    if (!mounted) return;
    setState(() {
      _account = account;
      _last = last;
      _next = next;
      _error = error;
      _log = log;
      _loaded = true;
    });
  }

  Future<void> _connect() async {
    await connectGoogleAccount(context);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final role = context.appWatch.user!.role;
    if (!_loaded) {
      return PageScaffold(title: l.backupTitle, child: const SizedBox.shrink());
    }
    final connected = _account != null;
    final configured = context.services.drive.auth.isConfigured;

    Widget tile(
      String label,
      String value, {
      bool good = false,
      double size = 17,
    }) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: good ? AppColors.incomeSoft : AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: good ? const Color(0xFF0B4A3C) : AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    return PageScaffold(
      title: l.backupTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.googleAccountTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      connected ? l.connectedAs(_account!) : l.notConnected,
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      l.googleAccountNote,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                connected
                    ? OutlinedButton(
                        onPressed: _connect,
                        child: Text(l.changeAccount),
                      )
                    : FilledButton(
                        onPressed: _connect,
                        child: Text(l.connectGoogle),
                      ),
              ],
            ),
          ),
          if (!configured) ...[
            const SizedBox(height: 12),
            MessageBanner(l.googleNotConfigured),
          ],
          const SizedBox(height: 18),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.autoBackupTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth >= 720 ? 3 : 1;
                    final w = (c.maxWidth - (cols - 1) * 14) / cols;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: w,
                          child: tile(
                            l.lastGoodBackup,
                            _last == null
                                ? l.backupNever
                                : fmt.dateTime(_last!),
                            good: _last != null,
                          ),
                        ),
                        SizedBox(
                          width: w,
                          child: tile(
                            l.nextBackup,
                            !connected
                                ? '—'
                                : (_next == null ||
                                      _next!.isBefore(context.services.now()))
                                ? l.statusNotYet
                                : fmt.dateTime(_next!),
                          ),
                        ),
                        SizedBox(
                          width: w,
                          child: tile(
                            l.backupIncludes,
                            l.backupIncludesValue,
                            size: 15,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  MessageBanner(l.backupFailedNote(_error!)),
                ],
                const SizedBox(height: 14),
                Text(
                  l.backupAppClosedNote,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                if (_log.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l.recentBackups,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final e in _log)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 190,
                            child: Text(
                              fmt.dateTime(e.at),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          e.ok
                              ? StatusPill(l.logOk)
                              : StatusPill.cancelled(l.logFailed),
                          const SizedBox(width: 10),
                          if (!e.ok && e.error != null)
                            Expanded(
                              child: Text(
                                e.error!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (can(role, Permission.restoreBackup)) ...[
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(24),
              borderColor: const Color(0xFFE5B3B5),
              borderWidth: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l.restoreTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      StatusPill.neutral(l.superOnlyChip),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.restoreWarning,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6E1519),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const RestorePanel(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
