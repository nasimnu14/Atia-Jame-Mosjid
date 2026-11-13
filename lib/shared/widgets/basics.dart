import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// White rounded panel with a thin border (design: cards).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderColor = AppColors.border,
    this.borderWidth = 1,
    this.color = AppColors.card,
    this.radius = 12,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final double borderWidth;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: child,
      );
}

/// Small rounded label such as "বাতিল" or "সক্রিয়".
class StatusPill extends StatelessWidget {
  const StatusPill(this.text,
      {super.key, this.background = AppColors.incomeSoft, this.foreground = AppColors.income});
  final String text;
  final Color background;
  final Color foreground;

  const StatusPill.cancelled(this.text, {super.key})
      : background = AppColors.cancelledBg,
        foreground = AppColors.cancelledText;
  const StatusPill.neutral(this.text, {super.key})
      : background = AppColors.neutralPill,
        foreground = AppColors.mutedStrong;
  const StatusPill.warn(this.text, {super.key})
      : background = AppColors.warnBg,
        foreground = AppColors.warnText;
  const StatusPill.expense(this.text, {super.key})
      : background = AppColors.expenseSoft,
        foreground = AppColors.expense;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: foreground)),
      );
}

enum BannerKind { warn, error, info }

/// A coloured message box (duplicate warning, errors, "this phone only").
class MessageBanner extends StatelessWidget {
  const MessageBanner(this.text, {super.key, this.kind = BannerKind.warn, this.icon});
  final String text;
  final BannerKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, ic) = switch (kind) {
      BannerKind.warn => (AppColors.warnBg, AppColors.warnText, Icons.warning_amber_rounded),
      BannerKind.error => (AppColors.cancelledBg, AppColors.cancelledText, Icons.error_outline),
      BannerKind.info => (AppColors.incomeSoft, AppColors.income, Icons.info_outline),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon ?? ic, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: TextStyle(fontSize: 13, color: fg))),
        ]),
      ),
    );
  }
}

/// A label above a text field, as in the designs.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.helper,
    this.obscure = false,
    this.validator,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
    this.suffix,
    this.textInputAction,
    this.borderColor,
  });
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final String? helper;
  final bool obscure;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int maxLines;
  final bool enabled;
  final FocusNode? focusNode;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          focusNode: focusNode,
          obscureText: obscure,
          validator: validator,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          autofocus: autofocus,
          maxLines: obscure ? 1 : maxLines,
          enabled: enabled,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            suffixIcon: suffix,
            enabledBorder: borderColor == null
                ? null
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor!, width: 2)),
          ),
        ),
      ],
    );
  }
}

/// Page title area used by every desktop screen.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.breadcrumb,
    required this.child,
    this.maxWidth,
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? breadcrumb;
  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (breadcrumb != null) ...[breadcrumb!, const SizedBox(height: 4)],
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.muted)),
                      ),
                  ]),
                  if (actions.isNotEmpty)
                    Wrap(spacing: 10, runSpacing: 8, children: actions),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows an error as a snack bar.
void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text(message), backgroundColor: AppColors.cancelledText));
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
