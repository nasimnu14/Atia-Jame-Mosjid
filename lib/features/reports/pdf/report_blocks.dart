import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../data/database.dart';
import '../../../data/tables.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/formatters.dart';
import '../../entries/entry_text.dart';
import 'pdf_pages.dart';

enum ReportContent { income, expense, both }

const _muted = Color(0xFF5B6B65);

/// Mosque name, address and the report title (PDF-3).
List<PdfBlock> _header(AppLocalizations l, String title, String? periodLine) =>
    [
      TextBlock(
        l.appName,
        style: pdfStyle(size: 19, weight: FontWeight.w700),
        align: TextAlign.center,
      ),
      TextBlock(
        l.mosqueAddressLine,
        style: pdfStyle(size: 10, color: _muted),
        align: TextAlign.center,
      ),
      SpacerBlock(6),
      TextBlock(
        title,
        style: pdfStyle(size: 13, weight: FontWeight.w700),
        align: TextAlign.center,
      ),
      if (periodLine != null)
        TextBlock(
          periodLine,
          style: pdfStyle(size: 10.5, color: const Color(0xFF3D4C46)),
          align: TextAlign.center,
        ),
      SpacerBlock(10),
    ];

TextStyle _entryStyle(bool cancelled, {bool bold = false}) => pdfStyle(
  weight: bold ? FontWeight.w600 : FontWeight.w400,
  color: cancelled ? _muted : const Color(0xFF1C2B26),
  decoration: cancelled ? TextDecoration.lineThrough : null,
);

/// The income / expense report (PDF-1 to PDF-6). Cancelled entries are listed
/// and marked and left out of every total (PDF-6, EDT-4).
List<PdfBlock> buildPeriodReport({
  required AppLocalizations l,
  required Fmt fmt,
  required ReportContent content,
  required String periodName,
  required List<Entry> entries,
}) {
  final title = switch (content) {
    ReportContent.income => l.pdfReportTitleIncome,
    ReportContent.expense => l.pdfReportTitleExpense,
    ReportContent.both => l.pdfReportTitleBoth,
  };
  final blocks = <PdfBlock>[..._header(l, title, periodName)];
  final income = entries.where((e) => e.type == EntryType.income).toList();
  final expense = entries.where((e) => e.type == EntryType.expense).toList();
  int total(List<Entry> xs) => xs
      .where((e) => e.status == EntryStatus.active)
      .fold(0, (a, e) => a + e.amount);
  final incomeTotal = total(income);
  final expenseTotal = total(expense);
  var anyCancelled = false;

  void section(EntryType type, List<Entry> rows, int sum) {
    final isIncome = type == EntryType.income;
    blocks.add(
      TextBlock(
        isIncome ? l.typeIncome : l.typeExpense,
        style: pdfStyle(size: 12, weight: FontWeight.w700),
        bottomRule: true,
        keepWithNext: true,
      ),
    );
    final cols = isIncome
        ? const [
            PdfCol.fixed(60),
            PdfCol.fixed(40),
            PdfCol.flex(1),
            PdfCol.fixed(72),
            PdfCol.fixed(40),
          ]
        : const [
            PdfCol.fixed(60),
            PdfCol.fixed(40),
            PdfCol.flex(1),
            PdfCol.flex(1.2),
            PdfCol.fixed(72),
            PdfCol.fixed(40),
          ];
    RowBlock row(
      List<String> cells, {
      bool header = false,
      bool cancelled = false,
    }) {
      final aligned = <PdfCell>[];
      for (var i = 0; i < cells.length; i++) {
        final isAmount = i == cols.length - 2;
        aligned.add(
          PdfCell(
            cells[i],
            align: isAmount ? TextAlign.right : TextAlign.left,
            style: header ? null : _entryStyle(cancelled, bold: i == 1),
          ),
        );
      }
      return RowBlock(cols, aligned, header: header);
    }

    blocks.add(
      row([
        l.colDate,
        isIncome ? l.colReceiptNo : l.colVoucherNo,
        isIncome ? l.colDonor : l.payeeName,
        if (!isIncome) l.colPurpose,
        l.colAmount,
        '',
      ], header: true),
    );
    if (rows.isEmpty) {
      blocks.add(
        TextBlock(
          l.pdfNoEntries,
          style: pdfStyle(color: _muted),
          padding: const EdgeInsets.symmetric(vertical: 6),
        ),
      );
    }
    for (final e in rows) {
      final cancelled = e.status == EntryStatus.cancelled;
      if (cancelled) anyCancelled = true;
      blocks.add(
        row([
          fmt.date(parseDayKey(e.entryDate)),
          fmt.integer(e.receiptNo),
          displayName(l, e),
          if (!isIncome) e.purpose ?? '',
          fmt.money(e.amount),
          cancelled ? l.statusCancelled : '',
        ], cancelled: cancelled),
      );
    }
    blocks.add(
      RowBlock(
        const [PdfCol.flex(1), PdfCol.fixed(130)],
        [
          PdfCell(
            isIncome ? l.totalIncome : l.totalExpense,
            style: pdfStyle(size: 11, weight: FontWeight.w700),
          ),
          PdfCell(
            fmt.money(sum),
            align: TextAlign.right,
            style: pdfStyle(size: 11, weight: FontWeight.w700),
          ),
        ],
        topRule: true,
        rowLine: false,
      ),
    );
    blocks.add(SpacerBlock(12));
  }

  if (content != ReportContent.expense)
    section(EntryType.income, income, incomeTotal);
  if (content != ReportContent.income)
    section(EntryType.expense, expense, expenseTotal);

  if (content == ReportContent.both) {
    final net = incomeTotal - expenseTotal;
    TextStyle s(bool bold) =>
        pdfStyle(size: 11, weight: bold ? FontWeight.w700 : FontWeight.w400);
    blocks.addAll([
      RowBlock(
        const [PdfCol.flex(1), PdfCol.fixed(130)],
        [
          PdfCell(l.totalIncome, style: s(false)),
          PdfCell(
            fmt.money(incomeTotal),
            align: TextAlign.right,
            style: s(false),
          ),
        ],
        background: const Color(0xFFF4F6F3),
        rowLine: false,
      ),
      RowBlock(
        const [PdfCol.flex(1), PdfCol.fixed(130)],
        [
          PdfCell(l.totalExpense, style: s(false)),
          PdfCell(
            fmt.money(expenseTotal),
            align: TextAlign.right,
            style: s(false),
          ),
        ],
        background: const Color(0xFFF4F6F3),
        rowLine: false,
      ),
      RowBlock(
        const [PdfCol.flex(1), PdfCol.fixed(130)],
        [
          PdfCell(l.incomeMinusExpense, style: s(true)),
          PdfCell(fmt.signedMoney(net), align: TextAlign.right, style: s(true)),
        ],
        background: AppColors.incomeSoft,
        rowLine: false,
      ),
      SpacerBlock(8),
    ]);
  }
  if (anyCancelled) {
    blocks.add(
      TextBlock(
        l.pdfCancelledFootnote,
        style: pdfStyle(size: 9, color: _muted),
      ),
    );
  }
  return blocks;
}

/// Who did what, already turned into text.
class EntryHistoryText {
  const EntryHistoryText({
    required this.addedBy,
    this.editedBy,
    this.cancelledBy,
  });
  final String addedBy;
  final String? editedBy;
  final String? cancelledBy;
}

/// One photo ready to draw. [image] is null when the file is missing.
class PdfPhoto {
  const PdfPhoto(this.label, this.image);
  final String label;
  final ui.Image? image;
}

/// A single entry with all its information and all its photos (DET-2).
List<PdfBlock> buildEntryReport({
  required AppLocalizations l,
  required Fmt fmt,
  required Entry entry,
  required EntryHistoryText history,
  required List<PdfPhoto> photos,
}) {
  final isIncome = entry.type == EntryType.income;
  final cancelled = entry.status == EntryStatus.cancelled;
  final blocks = <PdfBlock>[
    ..._header(
      l,
      isIncome ? l.pdfEntryTitleIncome : l.pdfEntryTitleExpense,
      null,
    ),
  ];
  if (cancelled) {
    blocks.addAll([
      TextBlock(
        l.cancelledBanner,
        style: pdfStyle(
          size: 11,
          weight: FontWeight.w700,
          color: const Color(0xFF6E1519),
        ),
        background: AppColors.cancelledBg,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      ),
      TextBlock(
        history.cancelledBy ?? '',
        style: pdfStyle(size: 10, color: const Color(0xFF6E1519)),
        background: AppColors.cancelledBg,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
      ),
      TextBlock(
        l.cancelReasonLine(entry.cancelReason ?? ''),
        style: pdfStyle(size: 10, color: const Color(0xFF6E1519)),
        background: AppColors.cancelledBg,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      ),
      SpacerBlock(10),
    ]);
  }
  const cols = [PdfCol.fixed(130), PdfCol.flex(1)];
  void field(String k, String v, {bool bold = false}) => blocks.add(
    RowBlock(cols, [
      PdfCell(k, style: pdfStyle(size: 10, color: _muted)),
      PdfCell(
        v,
        style: pdfStyle(
          size: 11.5,
          weight: bold ? FontWeight.w700 : FontWeight.w600,
          decoration: bold && cancelled ? TextDecoration.lineThrough : null,
        ),
      ),
    ]),
  );
  field(receiptNoLabel(l, entry.type), fmt.integer(entry.receiptNo));
  field(l.dateLabel, fmt.date(parseDayKey(entry.entryDate)));
  field(isIncome ? l.donorName : l.payeeName, displayName(l, entry));
  if (!isIncome) {
    field(l.purposeLabel, entry.purpose ?? '—');
    field(l.approvedBy, entry.approverName ?? '—');
  }
  field(
    l.amountTaka,
    cancelled
        ? l.amountNotCounted(fmt.money(entry.amount))
        : fmt.money(entry.amount),
    bold: true,
  );
  field(l.addressLabel, (entry.address ?? '').isEmpty ? '—' : entry.address!);

  blocks.addAll([
    SpacerBlock(10),
    TextBlock(
      l.pdfHistoryHeading,
      style: pdfStyle(size: 11, weight: FontWeight.w700),
      bottomRule: true,
      keepWithNext: true,
    ),
    TextBlock(
      history.addedBy,
      style: pdfStyle(size: 10, color: const Color(0xFF3D4C46)),
    ),
    TextBlock(
      history.editedBy ?? l.notEdited,
      style: pdfStyle(size: 10, color: const Color(0xFF3D4C46)),
    ),
    if (history.cancelledBy != null)
      TextBlock(
        history.cancelledBy!,
        style: pdfStyle(size: 10, color: const Color(0xFF3D4C46)),
      ),
    SpacerBlock(12),
  ]);

  if (photos.isNotEmpty) {
    blocks.add(
      TextBlock(
        '${l.pdfPhotosHeading} (${fmt.integer(photos.length)})',
        style: pdfStyle(size: 11, weight: FontWeight.w700),
        bottomRule: true,
        keepWithNext: true,
      ),
    );
    for (final p in photos) {
      blocks.add(
        p.image == null
            ? TextBlock(
                '${p.label} — ${l.photoMissing}',
                style: pdfStyle(size: 10, color: _muted),
                padding: const EdgeInsets.symmetric(vertical: 6),
              )
            : ImageBlock(p.image!, p.label),
      );
      blocks.add(SpacerBlock(6));
    }
  }
  return blocks;
}
