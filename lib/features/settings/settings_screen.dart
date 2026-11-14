import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/context_ext.dart';
import '../../shared/error_text.dart';
import '../../shared/formatters.dart';
import '../../shared/money_parse.dart';
import '../../shared/password_hasher.dart';
import '../../shared/permissions.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/date_form_field.dart';
import '../sign_in/language_switch.dart';
import '../updates/update_card.dart';

/// Language, opening balance, approver list, own password, app version
/// (GEN-3, BAL-1, BAL-2, EXP-7, USR-7).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = context.appWatch.user!.role;
    final cards = <Widget>[
      _LanguageCard(l: l),
      if (can(role, Permission.setOpeningBalance)) const _OpeningBalanceCard(),
      if (can(role, Permission.manageApprovers)) const _ApproversCard(),
      const PasswordCard(),
      const UpdateCard(),
    ];
    return PageScaffold(
      title: l.settingsTitle,
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth >= 760 ? 2 : 1;
          final w = (c.maxWidth - (cols - 1) * 18) / cols;
          return Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              for (final card in cards) SizedBox(width: w, child: card),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.chip});
  final String title;
  final String? chip;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      if (chip != null) StatusPill.neutral(chip!),
    ],
  );
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l.language),
        const SizedBox(height: 6),
        Text(
          l.languageDesc,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        const LanguageSwitch(),
      ],
    ),
  );
}

class _OpeningBalanceCard extends StatefulWidget {
  const _OpeningBalanceCard();

  @override
  State<_OpeningBalanceCard> createState() => _OpeningBalanceCardState();
}

class _OpeningBalanceCardState extends State<_OpeningBalanceCard> {
  final _amount = TextEditingController();
  DateTime? _date;
  final _dateKey = GlobalKey<DateFormFieldState>();
  String? _amountError;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    context.services.settings.openingBalance().then((ob) {
      if (!mounted) return;
      setState(() {
        if (ob != null) {
          _amount.text = context.fmt.number(ob.amount);
          _date = ob.date;
        } else {
          _date = dateOnly(DateTime.now());
        }
      });
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final fmt = context.fmt;
    final svc = context.services.settings;
    final me = context.app.user!;
    final messenger = ScaffoldMessenger.of(context);
    final parsed = parseAmountAllowZero(_amount.text);
    final dateError = _dateKey.currentState?.validate();
    setState(
      () => _amountError = parsed.isOk
          ? null
          : amountProblemText(l, parsed.problem!),
    );
    if (!parsed.isOk || dateError != null || _date == null) return;
    try {
      await svc.setOpeningBalance(me, parsed.taka!, _date!);
      messenger.showSnackBar(SnackBar(content: Text(l.saved)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorText(l, fmt, e)),
          backgroundColor: AppColors.cancelledText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(l.openingBalanceTitle, chip: l.adminOnlyChip),
          const SizedBox(height: 6),
          Text(
            l.openingBalanceDesc,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.amountLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(errorText: _amountError),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DateFormField(
                  key: _dateKey,
                  label: l.dateLabel,
                  value: _date,
                  onChanged: (d) => setState(() => _date = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(l.balanceFormula, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: Text(l.save)),
        ],
      ),
    );
  }
}

/// The opening balance may be 0.
AmountParseResult parseAmountAllowZero(String input) {
  final r = parseAmount(input);
  if (r.problem == AmountProblem.notPositive) {
    return const AmountParseResult.ok(0);
  }
  return r;
}

class _ApproversCard extends StatefulWidget {
  const _ApproversCard();

  @override
  State<_ApproversCard> createState() => _ApproversCardState();
}

class _ApproversCardState extends State<_ApproversCard> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final l = context.l10n;
    final fmt = context.fmt;
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, errorText(l, fmt, e));
    }
  }

  Future<void> _rename(Approver a) async {
    final l = context.l10n;
    final ctrl = TextEditingController(text: a.name);
    final svc = context.services.settings;
    final me = context.app.user!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.renameApprover),
        content: SizedBox(
          width: 380,
          child: LabeledField(
            label: l.approverName,
            controller: ctrl,
            autofocus: true,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (ok == true) await _run(() => svc.renameApprover(me, a.id, ctrl.text));
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final svc = context.services.settings;
    final me = context.app.user!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(l.approversTitle, chip: l.adminOnlyChip),
          const SizedBox(height: 6),
          Text(
            l.approversDesc,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Approver>>(
            stream: svc.watchApprovers(),
            builder: (context, snap) => Column(
              children: [
                for (final a in snap.data ?? const <Approver>[])
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.divider)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.name,
                            style: TextStyle(
                              fontSize: 15,
                              color: a.isActive
                                  ? AppColors.text
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                        if (!a.isActive) StatusPill.neutral(l.statusDisabled),
                        TextButton(
                          onPressed: () => _rename(a),
                          child: Text(l.renameApprover),
                        ),
                        TextButton(
                          onPressed: () => _run(
                            () => svc.setApproverActive(me, a.id, !a.isActive),
                          ),
                          child: Text(
                            a.isActive ? l.disableUser : l.enableUser,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  decoration: InputDecoration(hintText: l.approverName),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: _add, child: Text(l.addApprover)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _add() async {
    final svc = context.services.settings;
    final me = context.app.user!;
    final text = _name.text;
    await _run(() => svc.addApprover(me, text));
    if (mounted) _name.clear();
  }
}

class PasswordCard extends StatefulWidget {
  const PasswordCard({super.key});

  @override
  State<PasswordCard> createState() => PasswordCardState();
}

class PasswordCardState extends State<PasswordCard> {
  final _form = GlobalKey<FormState>();
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _new2 = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_cur, _new, _new2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    final fmt = context.fmt;
    final app = context.app;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await app.services.users.changeOwnPassword(
        app.user!,
        _cur.text,
        _new.text,
      );
      if (!mounted) return;
      for (final c in [_cur, _new, _new2]) {
        c.clear();
      }
      setState(() => _error = null);
      messenger.showSnackBar(SnackBar(content: Text(l.passwordChanged)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = errorText(l, fmt, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    return AppCard(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(l.myPassword),
            const SizedBox(height: 12),
            LabeledField(
              label: l.currentPassword,
              controller: _cur,
              obscure: true,
              validator: (v) => (v ?? '').isEmpty ? l.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: l.newPassword,
              controller: _new,
              obscure: true,
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
              controller: _new2,
              obscure: true,
              validator: (v) => v != _new.text ? l.passwordsDontMatch : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              MessageBanner(_error!, kind: BannerKind.error),
            ],
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: Text(l.changePassword)),
          ],
        ),
      ),
    );
  }
}
