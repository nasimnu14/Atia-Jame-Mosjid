import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_host.dart';
import '../../app/theme.dart';
import '../../shared/context_ext.dart';
import '../../shared/widgets/basics.dart';
import 'connect_google.dart';
import 'drive_client.dart';
import 'restore_service.dart';

/// Choose a backup in Google Drive and restore it (BAK-6). Used on the Backup
/// screen (Super Admin only) and on the first-launch screen (USR-3).
class RestorePanel extends StatefulWidget {
  const RestorePanel({super.key, this.firstLaunch = false});

  /// On the first-launch screen the user may need to connect first, and no
  /// automatic backup is made when they do.
  final bool firstLaunch;

  @override
  State<RestorePanel> createState() => _RestorePanelState();
}

class _RestorePanelState extends State<RestorePanel> {
  String? _account;
  List<DriveFile>? _backups;
  DriveFile? _selected;
  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_account == null) _refreshAccount();
  }

  Future<void> _refreshAccount() async {
    final a = await context.services.drive.accountEmail();
    if (mounted) setState(() => _account = a);
  }

  Future<void> _connect() async {
    final ok = await connectGoogleAccount(context, backUpAfterChange: false);
    if (ok) {
      await _refreshAccount();
      await _load();
    }
  }

  Future<void> _load() async {
    final l = context.l10n;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.services.restore.listBackups();
      if (!mounted) return;
      setState(() {
        _backups = list;
        _selected = list.isEmpty ? null : list.first;
      });
    } on DriveException catch (e) {
      if (mounted) setState(() => _error = l.restoreFailed(e.message));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    final l = context.l10n;
    final fmt = context.fmt;
    final file = _selected!;
    final when = fmt.dateTime(file.createdTime);
    final host = context.read<AppHost>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.restoreConfirmTitle),
        content: Text(l.restoreConfirmBody(when)),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA1272C),
            ),
            child: Text(l.restoreButton),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // The screens go away while the data is replaced; the result is shown on
    // the sign-in screen that follows.
    await host.replaceData((services) async {
      try {
        final outcome = await services.restore.restore(
          file,
          closeDatabase: () => services.db.close(),
        );
        final done = outcome.photosMissing == 0
            ? l.restoreDone(fmt.integer(outcome.photosRestored))
            : l.restoreDoneMissing(
                fmt.integer(outcome.photosRestored),
                fmt.integer(outcome.photosMissing),
              );
        return '$done ${l.restoreSignInNext}';
      } on RestoreException catch (e) {
        return l.restoreFailed(switch (e.problem) {
          RestoreProblem.damaged ||
          RestoreProblem.notABackup => l.restoreDamaged,
          RestoreProblem.tooNew => l.restoreTooNew,
          RestoreProblem.notConnected => l.restoreNeedConnect,
        });
      } on DriveException catch (e) {
        return l.restoreFailed(e.message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    if (_account == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.restoreNeedConnect, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _connect,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
            child: Text(
              l.connectGoogle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.connectedAs(_account!),
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        if (_backups == null)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _loading ? null : _load,
              child: Text(l.loadBackups),
            ),
          )
        else if (_backups!.isEmpty)
          MessageBanner(l.noBackupsFound, kind: BannerKind.info)
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.whichBackup,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<DriveFile>(
                      initialValue: _selected,
                      isExpanded: true,
                      items: [
                        for (final f in _backups!)
                          DropdownMenuItem(
                            value: f,
                            child: Text(fmt.dateTime(f.createdTime)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _selected = v),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _selected == null ? null : _restore,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA1272C),
                ),
                child: Text(l.restoreButton),
              ),
            ],
          ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          MessageBanner(_error!, kind: BannerKind.error),
        ],
      ],
    );
  }
}
