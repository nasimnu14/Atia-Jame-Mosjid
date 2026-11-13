import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/context_ext.dart';
import '../../shared/error_text.dart';
import '../../shared/widgets/basics.dart';
import 'language_switch.dart';

/// Sign in with username and password (USR-1).
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final l = context.l10n;
    final fmt = context.fmt;
    final app = context.app;
    try {
      await app.signIn(_user.text, _pass.text);
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AppCard(
                padding: const EdgeInsets.all(32),
                radius: 16,
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: LogoMark()),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(l.appName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                      Center(
                        child: Text(l.mosquePlace,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.muted)),
                      ),
                      const SizedBox(height: 14),
                      Text(l.signInTitle,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      LabeledField(
                        label: l.username,
                        controller: _user,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? l.fieldRequired : null,
                      ),
                      const SizedBox(height: 16),
                      LabeledField(
                        label: l.password,
                        controller: _pass,
                        obscure: true,
                        onSubmitted: (_) => _submit(),
                        validator: (v) =>
                            (v ?? '').isEmpty ? l.fieldRequired : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        MessageBanner(_error!, kind: BannerKind.error),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(l.signIn),
                      ),
                      const SizedBox(height: 16),
                      Text(l.forgotPasswordHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.muted)),
                      const SizedBox(height: 12),
                      const Center(child: LanguageSwitch()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
