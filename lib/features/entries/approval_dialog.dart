import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../shared/context_ext.dart';
import '../../shared/error_text.dart';
import '../../shared/permissions.dart';
import '../../shared/widgets/basics.dart';
import 'entry_text.dart';

/// Who may carry out an edit or cancel.
class Authority {
  const Authority.own() : approver = null;
  const Authority.approvedBy(User this.approver);

  /// Null when the signed-in user has the permission themselves.
  final User? approver;
}

/// EDT-1 / EDT-2: an Admin or Super Admin goes straight on. A User must have
/// an Admin or the Super Admin approve on the spot with their own username
/// and password. Returns null if the user backs out.
Future<Authority?> requireAuthority(
  BuildContext context,
  Entry entry,
  Permission permission,
) async {
  final me = context.app.user!;
  if (can(me.role, permission)) return const Authority.own();
  final approver = await showDialog<User>(
    context: context,
    builder: (_) => _ApprovalDialog(entry: entry),
  );
  return approver == null ? null : Authority.approvedBy(approver);
}

class _ApprovalDialog extends StatefulWidget {
  const _ApprovalDialog({required this.entry});
  final Entry entry;

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    final fmt = context.fmt;
    final svc = context.services.users;
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final approver = await svc.authorizeApprover(_user.text, _pass.text);
      // The dialog may have been closed with Back while the password was
      // being checked: do not close some other page instead.
      if (!mounted) return;
      nav.pop(approver);
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
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.approvalTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l.approvalBody, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entrySummaryLine(l, fmt, widget.entry),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: l.adminUsername,
                  controller: _user,
                  autofocus: true,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: l.adminPassword,
                  controller: _pass,
                  obscure: true,
                  onSubmitted: (_) => _approve(),
                  validator: (v) => (v ?? '').isEmpty ? l.fieldRequired : null,
                ),
                const SizedBox(height: 8),
                Text(
                  l.approvalNote,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5B6B65),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  MessageBanner(_error!, kind: BannerKind.error),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l.back),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _busy ? null : _approve,
                      child: Text(l.approve),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
