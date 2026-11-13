import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../shared/context_ext.dart';
import '../../shared/formatters.dart';
import '../../shared/period_choice.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/period_selector.dart';
import 'excel_builder.dart';

/// The daily automatic Excel upload and uploading by hand for a chosen period
/// (XLS-1 to XLS-9).
class ExcelUploadScreen extends StatefulWidget {
  const ExcelUploadScreen({super.key});

  @override
  State<ExcelUploadScreen> createState() => _ExcelUploadScreenState();
}

class _ExcelUploadScreenState extends State<ExcelUploadScreen> {
  PeriodChoice _choice = const PeriodChoice.currentMonth();
  ExcelContent _content = ExcelContent.both;
  String? _account;
  DateTime? _lastDaily;
  List<DriveLogData> _log = const [];
  StreamSubscription<void>? _sub;
  bool _busy = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sub == null) {
      _sub = context.services.drive.logChanges.listen((_) => _load());
      _load();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final s = context.services;
    final account = await s.drive.accountEmail();
    final last = await s.excel.lastDailyUpload();
    final log = await s.drive.recentLog([
      'excel_daily',
      'excel_manual',
    ], limit: 8);
    if (!mounted) return;
    setState(() {
      _account = account;
      _lastDaily = last;
      _log = log;
      _loaded = true;
    });
  }

  Future<void> _upload() async {
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.services;
    final today = dateOnly(s.now());
    final period = _choice.resolve(today);
    if (period == null) return;
    setState(() => _busy = true);
    final r = await s.excel.uploadManual(
      period: period,
      content: _content,
      periodName: periodChoiceName(l, fmt, _choice, today),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      showInfo(context, l.excelUploaded(r.fileName ?? ''));
    } else if (r.notConnected) {
      showError(context, l.connectFirst);
    } else {
      showError(context, l.excelUploadFailed(r.error ?? ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final today = dateOnly(context.services.now());
    if (!_loaded)
      return PageScaffold(title: l.excelTitle, child: const SizedBox.shrink());
    final period = _choice.resolve(today);
    final connected = _account != null;
    final fileName = period == null
        ? ''
        : '${l.excelFilePrefix}_${dayKey(period.from)}_${dayKey(period.to)}_${_content.name}.xlsx';

    return PageScaffold(
      title: l.excelTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.dailyAutoTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.dailyAutoDesc,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedStrong,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        connected
                            ? l.googleAccountLine(_account!)
                            : l.connectFirst,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.incomeSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.lastGoodDaily,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.income,
                        ),
                      ),
                      Text(
                        _lastDaily == null
                            ? l.statusNotYet
                            : fmt.dateTime(_lastDaily!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.uploadNowTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.whichData,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                RadioGroup<ExcelContent>(
                  groupValue: _content,
                  onChanged: (v) => setState(() => _content = v!),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (final (c, label) in [
                        (ExcelContent.income, l.pdfIncomeOnly),
                        (ExcelContent.expense, l.pdfExpenseOnly),
                        (ExcelContent.both, l.excelBoth),
                      ])
                        Container(
                          width: 240,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _content == c
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: RadioListTile<ExcelContent>(
                              value: c,
                              dense: true,
                              title: Text(
                                label,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.periodLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                PeriodSelector(
                  value: _choice,
                  today: today,
                  onChanged: (c) => setState(() => _choice = c),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 6,
                    children: [
                      Text(
                        l.excelFileLine(fileName),
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        l.excelSheetsLine(switch (_content) {
                          ExcelContent.income => l.typeIncome,
                          ExcelContent.expense => l.typeExpense,
                          ExcelContent.both =>
                            '${l.typeIncome}, ${l.typeExpense}',
                        }),
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        l.excelCancelledNote,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: (_busy || period == null || !connected)
                        ? null
                        : _upload,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    child: Text(
                      _busy ? l.uploading : l.uploadToDrive,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Text(
                      l.recentUploads,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_log.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Text(
                        l.noUploadsYet,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  for (final e in _log)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 190,
                            child: Text(
                              fmt.dateTime(e.at),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Text(
                              e.ok || e.error == null
                                  ? e.description
                                  : '${e.description} · ${e.error}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          e.ok
                              ? StatusPill(l.logOk)
                              : StatusPill.cancelled(l.logFailed),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
