import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../context_ext.dart';
import '../date_parse.dart';
import '../error_text.dart';
import '../formatters.dart';

/// A date the user can type (DD/MM/YYYY, Bangla or English digits) or pick
/// from a calendar that opens from the button beside the field (GEN-7).
/// A date that does not exist is refused with the reason (GEN-8).
class DateFormField extends StatefulWidget {
  const DateFormField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = true,
    this.helper,
    this.firstDate,
    this.lastDate,
    this.compact = false,
  });

  final String label;

  /// The current date, or null when empty / not a valid date.
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool required;
  final String? helper;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool compact;

  @override
  State<DateFormField> createState() => DateFormFieldState();
}

class DateFormFieldState extends State<DateFormField> {
  late final TextEditingController _controller = TextEditingController();
  final _focus = FocusNode();
  bool _bangla = true;
  bool _showError = false;
  DateTime? _lastExternal;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) setState(() => _showError = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bangla = context.fmt.bangla;
    if (bangla != _bangla || _controller.text.isEmpty && widget.value != null) {
      _bangla = bangla;
      _syncText();
    }
  }

  @override
  void didUpdateWidget(DateFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent changed the date (e.g. a calendar pick or a quick period):
    // show it, unless the text already means the same day.
    if (widget.value != _lastExternal && widget.value != _parsedNow()) {
      _syncText();
    }
  }

  DateTime? _parsedNow() => parseTypedDate(_controller.text).date;

  void _syncText() {
    _lastExternal = widget.value;
    final v = widget.value;
    _controller.text = v == null ? '' : Fmt(bangla: _bangla).date(v);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Validates (used by the form's Save): returns a message or null.
  String? validate() {
    setState(() => _showError = true);
    return _errorText();
  }

  String? _errorText() {
    final l = context.l10n;
    final text = _controller.text;
    if (text.trim().isEmpty) {
      return widget.required ? l.dateEmpty : null;
    }
    final r = parseTypedDate(text);
    if (!r.isOk) return dateProblemText(l, Fmt(bangla: _bangla), r);
    return null;
  }

  Future<void> _pick() async {
    final initial = widget.value ?? _parsedNow() ?? dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2200),
      helpText: widget.label,
    );
    if (picked != null) {
      _lastExternal = picked;
      _controller.text = Fmt(bangla: _bangla).date(picked);
      setState(() => _showError = true);
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error = _showError ? _errorText() : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: widget.compact ? 13 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          focusNode: _focus,
          keyboardType: TextInputType.datetime,
          onChanged: (t) {
            final r = parseTypedDate(t);
            _lastExternal = r.date;
            widget.onChanged(r.date);
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: l.datePlaceholder,
            errorText: error,
            helperText: widget.helper,
            suffixIcon: Padding(
              padding: const EdgeInsets.all(4),
              child: IconButton(
                tooltip: l.pickDateFromCalendar,
                onPressed: _pick,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.incomeSoft,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(Icons.calendar_month_outlined, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
