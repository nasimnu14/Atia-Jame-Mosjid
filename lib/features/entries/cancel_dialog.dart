import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../shared/context_ext.dart';
import '../../shared/error_text.dart';
import '../../shared/widgets/basics.dart';
import 'entry_service.dart';
import 'entry_text.dart';

/// Cancel an entry with a reason (EDT-3). The entry is never deleted (EDT-4).
/// Returns true when it was cancelled.
Future<bool> showCancelEntryDialog(
    BuildContext context, Entry entry, User? approver) async {
  final done = await showDialog<bool>(
    context: context,
    builder: (_) => _CancelDialog(entry: entry, approver: approver),
  );
  return done == true;
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.entry, required this.approver});
  final Entry entry;
  final User? approver;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _reason = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final l = context.l10n;
    final fmt = context.fmt;
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = l.cancelReasonRequired);
      return;
    }
    final svc = context.services.entries;
    final me = context.app.user!;
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await svc.cancel(me, widget.entry.id, _reason.text, approver: widget.approver);
      nav.pop(true);
    } on EntryActionException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = switch (e.problem) {
          EntryActionProblem.alreadyCancelled => l.entryAlreadyCancelled,
          EntryActionProblem.notFound => l.entryNotFound,
          EntryActionProblem.reasonRequired => l.cancelReasonRequired,
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorText(l, fmt, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final who = widget.approver ?? context.app.user!;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.cancelTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Text(entrySummaryLine(l, fmt, widget.entry),
                    style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 12),
              Text(l.cancelBody,
                  style: const TextStyle(fontSize: 14, color: AppColors.mutedStrong)),
              const SizedBox(height: 12),
              LabeledField(
                label: '${l.cancelReasonLabel} *',
                controller: _reason,
                maxLines: 3,
                autofocus: true,
                errorText: _error == l.cancelReasonRequired ? _error : null,
              ),
              const SizedBox(height: 8),
              Text(l.cancellingAs(who.name),
                  style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              if (_error != null && _error != l.cancelReasonRequired) ...[
                const SizedBox(height: 12),
                MessageBanner(_error!, kind: BannerKind.error),
              ],
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(
                    onPressed: () => Navigator.pop(context, false), child: Text(l.back)),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _busy ? null : _cancel,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFA1272C)),
                  child: Text(l.cancelTitle),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
