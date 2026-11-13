import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/context_ext.dart';
import '../../shared/error_text.dart';
import '../../shared/password_hasher.dart';
import '../../shared/widgets/basics.dart';
import '../google_drive/restore_launcher.dart';
import 'language_switch.dart';

/// First launch (USR-3): create the Super Admin, or restore from a backup.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _user, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final l = context.l10n;
    final fmt = context.fmt;
    final app = context.app;
    try {
      await app.createSuperAdmin(
          name: _name.text, username: _user.text, password: _pass.text);
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
    String? required(String? v) => (v ?? '').trim().isEmpty ? l.fieldRequired : null;

    final create = AppCard(
      padding: const EdgeInsets.all(24),
      borderColor: AppColors.primary,
      borderWidth: 2,
      radius: 14,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.setupStartFresh,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(l.setupStartFreshDesc,
                style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 14),
            LabeledField(label: l.fullName, controller: _name, validator: required),
            const SizedBox(height: 12),
            LabeledField(label: l.username, controller: _user, validator: required),
            const SizedBox(height: 12),
            LabeledField(
              label: l.password,
              controller: _pass,
              obscure: true,
              validator: (v) {
                if ((v ?? '').isEmpty) return l.fieldRequired;
                if (PasswordHasher.isTooShort(v!)) {
                  return l.passwordTooShort(fmt.integer(PasswordHasher.minLength));
                }
                if (PasswordHasher.isTooLong(v)) return l.passwordTooLong;
                return null;
              },
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: l.confirmPassword,
              controller: _pass2,
              obscure: true,
              onSubmitted: (_) => _create(),
              validator: (v) => v != _pass.text ? l.passwordsDontMatch : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              MessageBanner(_error!, kind: BannerKind.error),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _create,
              child: Text(l.createAccountStart),
            ),
          ],
        ),
      ),
    );

    final restore = AppCard(
      padding: const EdgeInsets.all(24),
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.setupRestoreTitle,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(l.setupRestoreDesc,
              style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          const SizedBox(height: 14),
          for (final (i, s) in [l.setupRestoreStep1, l.setupRestoreStep2, l.setupRestoreStep3].indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${fmt.integer(i + 1)}. $s',
                  style: const TextStyle(fontSize: 14)),
            ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => openRestoreFlow(context),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary)),
            child: Text(l.connectGoogle,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                children: [
                  const Align(
                      alignment: Alignment.centerRight, child: LanguageSwitch()),
                  const SizedBox(height: 16),
                  const LogoMark(size: 56),
                  const SizedBox(height: 10),
                  Text(l.setupWelcome,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(l.setupChoose,
                      style: const TextStyle(fontSize: 15, color: AppColors.muted)),
                  const SizedBox(height: 24),
                  LayoutBuilder(builder: (context, c) {
                    if (c.maxWidth < 700) {
                      return Column(children: [create, const SizedBox(height: 20), restore]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: create),
                        const SizedBox(width: 20),
                        Expanded(child: restore),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
