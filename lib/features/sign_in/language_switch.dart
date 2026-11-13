import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/context_ext.dart';

/// "বাংলা | English" toggle (GEN-3).
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final bangla = context.appWatch.bangla;
    Widget seg(String label, bool on, VoidCallback tap) => Semantics(
          button: true,
          selected: on,
          child: InkWell(
            onTap: tap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              color: on ? AppColors.primary : Colors.white,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15, color: on ? Colors.white : AppColors.text)),
            ),
          ),
        );
    return Semantics(
      container: true,
      label: context.l10n.language,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            seg(context.l10n.langBangla, bangla, () => context.app.setLanguage(true)),
            seg(context.l10n.langEnglish, !bangla, () => context.app.setLanguage(false)),
          ]),
        ),
      ),
    );
  }
}

/// The app logo mark (crescent) from the designs.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 52, this.light = false});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: light ? AppColors.incomeSoft : AppColors.primary,
            borderRadius: BorderRadius.circular(size / 4)),
        child: Icon(Icons.nightlight_round,
            size: size * 0.6, color: light ? AppColors.primary : Colors.white),
      );
}
