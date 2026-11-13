import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../data/tables.dart';
import '../../shared/context_ext.dart';
import '../../shared/error_text.dart';
import '../../shared/password_hasher.dart';
import '../../shared/role_text.dart';
import '../../shared/widgets/basics.dart';

/// Users (Super Admin only): add, change role, disable, reset password
/// (USR-4, USR-5, USR-6).
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final me = context.appWatch.user!;
    final svc = context.services.users;
    return PageScaffold(
      title: l.usersTitle,
      subtitle: l.usersSubtitle,
      actions: [
        FilledButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const AddUserDialog(),
          ),
          child: Text(l.addUser),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<User>>(
            stream: svc.watchAll(),
            builder: (context, snap) {
              final users = snap.data ?? const <User>[];
              return AppCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: c.maxWidth < 1100 ? 1100 : c.maxWidth,
                        child: Column(
                          children: [
                            _row(
                              header: true,
                              cells: [
                                Text(l.colName),
                                Text(l.username),
                                Text(l.colRole),
                                Text(l.colStatus),
                                Text(l.colLastSignIn),
                                Text(l.colActions),
                              ],
                            ),
                            for (final u in users)
                              _row(
                                cells: [
                                  Text(
                                    u.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(u.username),
                                  Text(roleName(l, u.role)),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: u.isActive
                                        ? StatusPill(l.statusActive)
                                        : StatusPill.neutral(l.statusDisabled),
                                  ),
                                  Text(
                                    u.lastSignInAt == null
                                        ? l.never
                                        : fmt.dateTime(u.lastSignInAt!),
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  if (u.id == me.id)
                                    Text(
                                      l.youChangeOwnPassword,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.muted,
                                      ),
                                    )
                                  else if (u.role == Role.superAdmin)
                                    const SizedBox.shrink()
                                  else
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _small(
                                          l.changeRole,
                                          () => _changeRole(context, u),
                                        ),
                                        _small(
                                          l.resetPassword,
                                          () => _reset(context, u),
                                        ),
                                        _small(
                                          u.isActive
                                              ? l.disableUser
                                              : l.enableUser,
                                          () => _toggle(context, u),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              l.usersNeverDeleted,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedStrong,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final r in Role.values.reversed.toList().reversed)
                SizedBox(
                  width: 300,
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roleName(l, r),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          roleCan(l, r),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row({required List<Widget> cells, bool header = false}) {
    const flex = [12, 8, 10, 8, 14, 38];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: header ? 10 : 12),
      decoration: BoxDecoration(
        color: header ? AppColors.background : null,
        border: header
            ? null
            : const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontSize: header ? 13 : 14,
          fontWeight: header ? FontWeight.w600 : FontWeight.w400,
          color: header ? AppColors.muted : AppColors.text,
        ),
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              Expanded(flex: flex[i], child: cells[i]),
              if (i < cells.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _small(String label, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      textStyle: const TextStyle(fontFamily: kFontFamily, fontSize: 13),
    ),
    child: Text(label),
  );

  Future<void> _toggle(BuildContext context, User u) async {
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.services.users;
    final me = context.app.user!;
    try {
      await s.setActive(me, u.id, !u.isActive);
    } catch (e) {
      if (context.mounted) showError(context, errorText(l, fmt, e));
    }
  }

  Future<void> _changeRole(BuildContext context, User u) async {
    await showDialog(
      context: context,
      builder: (_) => _ChangeRoleDialog(user: u),
    );
  }

  Future<void> _reset(BuildContext context, User u) async {
    await showDialog(
      context: context,
      builder: (_) => _ResetPasswordDialog(user: u),
    );
  }
}

class _RoleChoices extends StatelessWidget {
  const _RoleChoices({required this.value, required this.onChanged});
  final Role value;
  final ValueChanged<Role> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return RadioGroup<Role>(
      groupValue: value,
      onChanged: (r) => onChanged(r!),
      child: Column(
        children: [
          for (final r in const [Role.admin, Role.user])
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: r == value ? AppColors.primary : AppColors.border,
                ),
              ),
              child: RadioListTile<Role>(
                value: r,
                title: Text(
                  roleName(l, r),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  roleCan(l, r),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedStrong,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  Role _role = Role.user;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _user, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _add() async {
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    final fmt = context.fmt;
    final svc = context.services.users;
    final me = context.app.user!;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await svc.addUser(
        me,
        name: _name.text,
        username: _user.text,
        password: _pass.text,
        role: _role,
      );
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.userAdded)));
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
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l.fieldRequired : null;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.addUserTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: l.fullName,
                        controller: _name,
                        validator: required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledField(
                        label: l.username,
                        controller: _user,
                        validator: required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: l.password,
                        controller: _pass,
                        obscure: true,
                        validator: (v) {
                          if ((v ?? '').isEmpty) return l.fieldRequired;
                          if (PasswordHasher.isTooShort(v!)) {
                            return l.passwordTooShort(
                              fmt.integer(PasswordHasher.minLength),
                            );
                          }
                          if (PasswordHasher.isTooLong(v)) {
                            return l.passwordTooLong;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledField(
                        label: l.confirmPassword,
                        controller: _pass2,
                        obscure: true,
                        validator: (v) =>
                            v != _pass.text ? l.passwordsDontMatch : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l.colRole,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _RoleChoices(
                  value: _role,
                  onChanged: (r) => setState(() => _role = r),
                ),
                Text(
                  l.addUserNote,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
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
                      onPressed: _busy ? null : _add,
                      child: Text(l.add),
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

class _ChangeRoleDialog extends StatefulWidget {
  const _ChangeRoleDialog({required this.user});
  final User user;

  @override
  State<_ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<_ChangeRoleDialog> {
  late Role _role = widget.user.role;
  String? _error;

  Future<void> _save() async {
    final l = context.l10n;
    final fmt = context.fmt;
    final nav = Navigator.of(context);
    try {
      await context.services.users.changeRole(
        context.app.user!,
        widget.user.id,
        _role,
      );
      nav.pop();
    } catch (e) {
      setState(() => _error = errorText(l, fmt, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.changeRoleFor(widget.user.name)),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoleChoices(
              value: _role,
              onChanged: (r) => setState(() => _role = r),
            ),
            if (_error != null) MessageBanner(_error!, kind: BannerKind.error),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.back),
        ),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.user});
  final User user;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    final fmt = context.fmt;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.services.users.resetPassword(
        context.app.user!,
        widget.user.id,
        _pass.text,
      );
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.passwordChanged)));
    } catch (e) {
      setState(() => _error = errorText(l, fmt, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    return AlertDialog(
      title: Text(l.resetPasswordFor(widget.user.name)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledField(
                label: l.newPassword,
                controller: _pass,
                obscure: true,
                autofocus: true,
                validator: (v) {
                  if ((v ?? '').isEmpty) return l.fieldRequired;
                  if (PasswordHasher.isTooShort(v!)) {
                    return l.passwordTooShort(
                      fmt.integer(PasswordHasher.minLength),
                    );
                  }
                  if (PasswordHasher.isTooLong(v)) return l.passwordTooLong;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: l.confirmNewPassword,
                controller: _pass2,
                obscure: true,
                validator: (v) => v != _pass.text ? l.passwordsDontMatch : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                MessageBanner(_error!, kind: BannerKind.error),
              ],
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.back),
        ),
        FilledButton(onPressed: _save, child: Text(l.resetPassword)),
      ],
    );
  }
}
