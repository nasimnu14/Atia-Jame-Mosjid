import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/context_ext.dart';
import '../../shared/widgets/basics.dart';
import 'update_installer.dart';
import 'update_service.dart';

/// "A new version is available": what changed, what is kept safe, and the
/// button to install (UPD-1, UPD-2). Before installing, all data is backed up
/// (UPD-4); data and settings are untouched (UPD-3).
Future<void> showUpdateDialog(
  BuildContext context,
  UpdateInfo info,
  String installed,
) => showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => _UpdateDialog(info: info, installed: installed),
);

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.info, required this.installed});
  final UpdateInfo info;
  final String installed;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

enum _Phase { idle, backingUp, downloading }

class _UpdateDialogState extends State<_UpdateDialog> {
  _Phase _phase = _Phase.idle;
  double _progress = 0;
  String? _error;

  Future<void> _install() async {
    final l = context.l10n;
    final s = context.services;
    setState(() {
      _phase = _Phase.backingUp;
      _error = null;
    });
    try {
      // A copy of the data first, always; and a Google Drive backup if an
      // account is connected (it must never stop the update when offline).
      s.backup.snapshotLiveFile('pre-update-${widget.info.version}');
      await s.backup.runBackup(reason: 'before update');
      if (!mounted) {
        return;
      }
      setState(() => _phase = _Phase.downloading);
      await s.updateInstaller.install(
        widget.info,
        onProgress: (p) {
          if (mounted) {
            setState(() => _progress = p);
          }
        },
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } on UpdateException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.idle;
          _error = l.updateFailed(e.message);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.idle;
          _error = l.updateFailed('$e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.services;
    final info = widget.info;
    final notes = fmt.bangla ? info.notesBn : info.notesEn;
    final canInstall = s.updates.canInstallInApp && info.assetUrl != null;
    final busy = _phase != _Phase.idle;

    Widget safety(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: AppColors.income,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.updateAvailableTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.updateVersionLine(
                  fmt.digits(info.version.toString()),
                  fmt.digits(widget.installed),
                ),
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    '${l.whatChanged}: ${notes.isEmpty ? '—' : notes}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedStrong,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              safety(l.updateSafety1),
              safety(l.updateSafety2),
              safety(l.updateSafety3),
              if (!canInstall) ...[
                const SizedBox(height: 4),
                MessageBanner(l.updateNoInstaller, kind: BannerKind.info),
              ],
              if (busy) ...[
                const SizedBox(height: 12),
                Text(
                  _phase == _Phase.backingUp
                      ? l.updateBackingUp
                      : l.updateDownloading(
                          fmt.digits('${(_progress * 100).round()}%'),
                        ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: _phase == _Phase.downloading ? _progress : null,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                MessageBanner(_error!, kind: BannerKind.error),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    child: Text(l.later),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: busy ? null : _install,
                    child: Text(canInstall ? l.updateNow : l.openReleasePage),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
