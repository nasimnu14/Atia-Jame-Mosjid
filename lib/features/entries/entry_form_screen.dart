import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../data/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/bangla.dart';
import '../../shared/context_ext.dart';
import '../../shared/error_text.dart';
import '../../shared/formatters.dart';
import '../../shared/money_parse.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/date_form_field.dart';
import 'entry_details_screen.dart';
import 'entry_service.dart';
import 'entry_text.dart';
import 'photo_shrinker.dart';
import 'photo_viewer.dart';

/// Add or edit an income or an expense (INC-1, EXP-1, EDT-1).
///
/// For an edit, [existing] is the saved entry and [approver] is the Admin who
/// approved a User's edit on the spot (EDT-2).
class EntryFormScreen extends StatefulWidget {
  const EntryFormScreen({
    super.key,
    required this.type,
    this.existing,
    this.approver,
  });
  final EntryType type;
  final EntryWithPhotos? existing;
  final User? approver;

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _receipt = TextEditingController();
  final _name = TextEditingController();
  final _purpose = TextEditingController();
  final _amount = TextEditingController();
  final _address = TextEditingController();
  final _dateKey = GlobalKey<DateFormFieldState>();
  DateTime? _date;
  String? _approver;
  List<PhotoDraft> _photos = [];
  List<Approver> _approvers = [];
  int? _suggested;
  Entry? _duplicate;
  Map<EntryField, String> _errors = {};
  String? _formError;
  bool _busy = false;
  bool _initialised = false;

  bool get _isExpense => widget.type == EntryType.expense;
  bool get _isEdit => widget.existing != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    _init();
  }

  Future<void> _init() async {
    final services = context.services;
    final fmt = context.fmt;
    final e = widget.existing;
    final approvers = await services.settings.approvers();
    int? suggested;
    if (e == null) {
      suggested = await services.entries.suggestReceiptNo(widget.type);
    }
    if (!mounted) return;
    setState(() {
      _approvers = approvers;
      if (e != null) {
        final x = e.entry;
        _receipt.text = fmt.integer(x.receiptNo);
        _date = parseDayKey(x.entryDate);
        _name.text = x.name;
        _purpose.text = x.purpose ?? '';
        _approver = x.approverName;
        _amount.text = fmt.number(x.amount);
        _address.text = x.address ?? '';
        _photos = [
          for (final p in e.photos)
            PhotoDraft(
              existingId: p.id,
              existingFileName: p.fileName,
              label: p.label,
            ),
        ];
      } else {
        _suggested = suggested;
        _receipt.text = fmt.integer(suggested!);
        _date = dateOnly(services.now());
      }
    });
    _checkDuplicate();
  }

  @override
  void dispose() {
    for (final c in [_receipt, _name, _purpose, _amount, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _receiptNo {
    final n = int.tryParse(toEnglishDigits(_receipt.text.trim()));
    return n != null && n >= 1 ? n : null;
  }

  /// INC-5 / EXP-4: warn, but do not forbid, when the number is already used.
  Future<void> _checkDuplicate() async {
    final no = _receiptNo;
    final svc = context.services.entries;
    final dup = no == null
        ? null
        : await svc.findDuplicate(
            widget.type,
            no,
            exceptId: widget.existing?.entry.id,
          );
    if (mounted && no == _receiptNo) setState(() => _duplicate = dup);
  }

  String _description() => (_isExpense ? _purpose.text : _name.text).trim();

  Future<void> _addPhotos() async {
    final l = context.l10n;
    final fmt = context.fmt;
    final services = context.services;
    final room = maxPhotosPerEntry - _photos.length;
    if (room <= 0) {
      showError(context, l.photoLimit(fmt.integer(maxPhotosPerEntry)));
      return;
    }
    final picked = await services.photoPicker.pick(context, maxCount: room);
    for (final raw in picked) {
      if (!mounted) return;
      Uint8List? bytes;
      try {
        bytes = await services.photoShrinker.shrink(raw);
      } on PhotoUnreadableException {
        if (mounted) showError(context, l.photoReadError);
        continue;
      }
      if (!mounted) return;
      final label = await _askLabel();
      if (label == null) continue; // cancelled this photo
      setState(
        () => _photos = [..._photos, PhotoDraft(bytes: bytes, label: label)],
      );
    }
  }

  /// INC-10: ask for a label; blank is allowed and gets a default at save.
  Future<String?> _askLabel() => showDialog<String>(
    context: context,
    builder: (_) => const _PhotoLabelDialog(),
  );

  bool _saving = false;

  /// One save at a time: a second click while the first is still checking must
  /// not create a second entry.
  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    try {
      await _saveNow();
    } finally {
      _saving = false;
    }
  }

  Future<void> _saveNow() async {
    final l = context.l10n;
    final fmt = context.fmt;
    final services = context.services;
    final me = context.app.user!;
    final nav = Navigator.of(context);

    final errors = <EntryField, String>{};
    if (_receiptNo == null) errors[EntryField.receiptNo] = l.receiptInvalid;
    final dateError = _dateKey.currentState?.validate();
    if (dateError != null || _date == null) {
      errors[EntryField.date] = dateError ?? l.dateEmpty;
    }
    final amount = parseAmount(_amount.text);
    if (!amount.isOk) {
      errors[EntryField.amount] = amountProblemText(l, amount.problem!);
    }

    final draft = EntryDraft(
      type: widget.type,
      receiptNo: _receiptNo,
      date: _date,
      name: _name.text,
      purpose: _purpose.text,
      approverName: _approver ?? '',
      amount: amount.taka,
      address: _address.text,
      photos: _photos,
    );
    draft.photos = withDefaultLabels(draft, fmt, unknownName: l.unknownDonor);

    final problems = await services.entries.validate(
      draft,
      existingApprover: widget.existing?.entry.approverName,
    );
    problems.forEach((f, p) {
      errors.putIfAbsent(f, () => entryProblemText(l, fmt, f, p));
    });
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _formError = null;
      });
      return;
    }

    setState(() {
      _busy = true;
      _errors = {};
      _formError = null;
    });
    try {
      final saved = widget.existing == null
          ? await services.entries.create(me, draft)
          : await services.entries.update(
              me,
              widget.existing!.entry.id,
              draft,
              approver: widget.approver,
            );
      if (!mounted) return;
      showInfo(
        context,
        widget.existing == null ? l.entrySaved : l.entryUpdated,
      );
      if (widget.existing == null) {
        nav.pushReplacement(
          MaterialPageRoute(
            builder: (_) => EntryDetailsScreen(entryId: saved.entry.id),
          ),
        );
      } else {
        nav.pop(true);
      }
    } on EntryValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errors = {
          for (final x in e.errors.entries)
            x.key: entryProblemText(l, fmt, x.key, x.value),
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _formError = errorText(l, fmt, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final isExpense = _isExpense;
    final title = _isEdit
        ? (isExpense ? l.editExpenseTitle : l.editIncomeTitle)
        : (isExpense ? l.addExpenseTitle : l.addIncomeTitle);

    final approverNames = [
      for (final a in _approvers) a.name,
      if (_approver != null && !_approvers.any((a) => a.name == _approver))
        _approver!,
    ];

    Widget receiptField() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledField(
          label: '${receiptNoLabel(l, widget.type)} *',
          controller: _receipt,
          keyboardType: TextInputType.number,
          errorText: _errors[EntryField.receiptNo],
          borderColor: _duplicate != null ? AppColors.warnBorder : null,
          onChanged: (_) => _checkDuplicate(),
          helper: _suggested == null
              ? null
              : (isExpense
                    ? l.suggestedNextVoucher(fmt.integer(_suggested!))
                    : l.suggestedNextReceipt(fmt.integer(_suggested!))),
        ),
        if (_duplicate != null) ...[
          const SizedBox(height: 6),
          MessageBanner(
            (isExpense ? l.duplicateWarningVoucher : l.duplicateWarningReceipt)(
              fmt.date(parseDayKey(_duplicate!.entryDate)),
              displayName(l, _duplicate!),
              fmt.money(_duplicate!.amount),
            ),
          ),
        ],
      ],
    );

    final dateField = DateFormField(
      key: _dateKey,
      label: '${l.dateLabel} *',
      value: _date,
      helper: l.dateHelp,
      onChanged: (d) => setState(() => _date = d),
    );

    final fields = <Widget>[
      receiptField(),
      dateField,
      LabeledField(
        label: isExpense ? '${l.payeeNameForm} *' : l.donorNameOptional,
        controller: _name,
        hint: isExpense ? null : l.donorNameHint,
        errorText: _errors[EntryField.name],
        onChanged: (_) => setState(() {}),
      ),
      if (isExpense)
        LabeledField(
          label: '${l.purposeLabel} *',
          controller: _purpose,
          errorText: _errors[EntryField.purpose],
          onChanged: (_) => setState(() {}),
        ),
      if (isExpense) _approverField(l, approverNames),
      LabeledField(
        label: '${l.amountTaka} *',
        controller: _amount,
        keyboardType: TextInputType.number,
        errorText: _errors[EntryField.amount],
      ),
    ];

    return PageScaffold(
      maxWidth: 920,
      breadcrumb: Breadcrumb(
        root: entryTitle(l, widget.type),
        current: _isEdit
            ? l.editEntry
            : (isExpense ? l.addExpenseTitle : l.addIncomeTitle),
      ),
      title: title,
      child: AppCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 560 ? 2 : 1;
                final w = (c.maxWidth - (cols - 1) * 18) / cols;
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    for (final f in fields) SizedBox(width: w, child: f),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: l.addressOptional,
              controller: _address,
              hint: l.addressHint,
            ),
            const SizedBox(height: 18),
            _photoSection(l, fmt),
            if (_formError != null) ...[
              const SizedBox(height: 14),
              MessageBanner(_formError!, kind: BannerKind.error),
            ],
            const Divider(height: 36),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: Text(l.save),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text(l.back),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _approverField(AppLocalizations l, List<String> names) {
    final err = _errors[EntryField.approver];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l.approvedBy} *',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey('approver-${names.length}-$_approver'),
          initialValue: names.contains(_approver) ? _approver : null,
          isExpanded: true,
          hint: Text(l.approverSelect),
          items: [
            for (final n in names) DropdownMenuItem(value: n, child: Text(n)),
          ],
          onChanged: (v) => setState(() => _approver = v),
          decoration: InputDecoration(errorText: err),
        ),
        if (names.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: MessageBanner(l.approverListEmpty),
          ),
      ],
    );
  }

  Widget _photoSection(AppLocalizations l, Fmt fmt) {
    final e = widget.existing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.photosOptionalMany,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          _isExpense ? l.photosHintExpense : l.photosHintIncome,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (i, p) in _photos.indexed)
              _PhotoTile(
                label: p.label.trim().isEmpty
                    ? defaultPhotoLabel(
                        _description(),
                        i + 1,
                        fmt,
                        unknownName: l.unknownDonor,
                      )
                    : p.label,
                removeLabel: l.removePhoto(
                  p.label.trim().isEmpty ? '${i + 1}' : p.label,
                ),
                onRemove: () =>
                    setState(() => _photos = [..._photos]..removeAt(i)),
                child: p.bytes != null
                    ? DraftPhotoImage(bytes: p.bytes!)
                    : SavedPhotoImage(
                        entryId: e!.entry.id,
                        photo: e.photos.firstWhere((x) => x.id == p.existingId),
                        cacheWidth: 300,
                      ),
              ),
            if (_photos.length < maxPhotosPerEntry)
              SizedBox(
                width: 140,
                height: 110,
                child: OutlinedButton(
                  onPressed: _addPhotos,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFF9FB3AA), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l.addPhoto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_errors[EntryField.photos] != null) ...[
          const SizedBox(height: 8),
          MessageBanner(_errors[EntryField.photos]!, kind: BannerKind.error),
        ],
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.child,
    required this.label,
    required this.removeLabel,
    required this.onRemove,
  });
  final Widget child;
  final String label;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 140,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 140,
              height: 110,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.neutralPill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: child,
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filled(
                tooltip: removeLabel,
                onPressed: onRemove,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.text,
                  minimumSize: const Size(28, 28),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.close, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.mutedStrong),
        ),
      ],
    ),
  );
}

class _PhotoLabelDialog extends StatefulWidget {
  const _PhotoLabelDialog();

  @override
  State<_PhotoLabelDialog> createState() => _PhotoLabelDialogState();
}

class _PhotoLabelDialogState extends State<_PhotoLabelDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.photoLabelTitle),
      content: SizedBox(
        width: 420,
        child: LabeledField(
          label: l.photoLabelTitle,
          controller: _ctrl,
          hint: l.photoLabelHint,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.back),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text(l.add),
        ),
      ],
    );
  }
}
