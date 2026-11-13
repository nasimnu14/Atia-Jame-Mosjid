import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/context_ext.dart';
import '../../shared/widgets/basics.dart';
import 'update_dialog.dart';
import 'update_service.dart';

/// "App and updates" card in Settings: the version, when it was last checked,
/// and the button to check now (UPD-1, UPD-2).
class UpdateCard extends StatefulWidget {
  const UpdateCard({super.key});

  @override
  State<UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends State<UpdateCard> {
  String? _version;
  DateTime? _lastChecked;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_version == null) {
      context.services.updates.currentVersion().then((v) {
        if (mounted) {
          setState(() => _version = v);
        }
      });
      context.services.updates.lastChecked().then((t) {
        if (mounted) {
          setState(() => _lastChecked = t);
        }
      });
    }
  }

  Future<void> _check() async {
    final l = context.l10n;
    final s = context.services;
    setState(() => _busy = true);
    final r = await s.updates.check();
    final last = await s.updates.lastChecked();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _lastChecked = last;
    });
    switch (r.status) {
      case UpdateStatus.available:
        await showUpdateDialog(context, r.info!, _version ?? '');
      case UpdateStatus.upToDate:
        showInfo(context, l.upToDateMsg);
      case UpdateStatus.failed:
        showError(context, l.updateCheckFailed(r.error ?? ''));
      case UpdateStatus.notConfigured:
        showError(context, l.updateNotSetUp);
      case UpdateStatus.disabled:
        showInfo(context, l.updateStoreOnly);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.appAndUpdate,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            l.version(fmt.digits(_version ?? '…')),
            style: const TextStyle(fontSize: 14, color: AppColors.text),
          ),
          const SizedBox(height: 2),
          Text(
            _lastChecked == null
                ? l.lastChecked(l.never)
                : l.lastChecked(fmt.dateTime(_lastChecked!)),
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _busy ? null : _check,
              child: Text(_busy ? l.checking : l.checkForUpdates),
            ),
          ),
        ],
      ),
    );
  }
}
