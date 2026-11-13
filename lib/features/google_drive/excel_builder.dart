import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../data/database.dart';
import '../../data/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/formatters.dart';
import '../entries/entry_text.dart';

enum ExcelContent { income, expense, both }

/// Builds the .xlsx file of entries (XLS-1, XLS-3 to XLS-7).
///
/// - Income and expense are on separate sheets, one row per entry, one column
///   per field (XLS-5).
/// - Cancelled entries are included, marked in a status column with the
///   reason (XLS-5).
/// - Receipt numbers and amounts are real numbers, dates are real dates, so
///   they sort and add up in Excel (XLS-6). Nothing is formatted as text.
/// - Column headings and sheet names are in the app's language (XLS-7).
/// - Photos are not included (XLS-1).
Uint8List buildEntriesWorkbook({
  required AppLocalizations l,
  required List<Entry> entries,
  required Map<String, String> userNames,
  required ExcelContent content,
}) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();

  final dateStyle = CellStyle(
    numberFormat: CustomDateTimeNumFormat(formatCode: 'dd/mm/yyyy'),
    horizontalAlign: HorizontalAlign.Left,
  );
  final dateTimeStyle = CellStyle(
    numberFormat: CustomDateTimeNumFormat(formatCode: 'dd/mm/yyyy hh:mm'),
    horizontalAlign: HorizontalAlign.Left,
  );
  final amountStyle = CellStyle(numberFormat: NumFormat.standard_3);
  final headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#E3F0EA'),
    verticalAlign: VerticalAlign.Center,
  );

  void fill(EntryType type) {
    final isIncome = type == EntryType.income;
    final sheet = excel[isIncome ? l.typeIncome : l.typeExpense];
    final headers = <String>[
      isIncome ? l.colReceiptNo : l.colVoucherNo,
      l.colDate,
      isIncome ? l.colDonor : l.payeeName,
      if (!isIncome) l.colPurpose,
      if (!isIncome) l.colApprover,
      l.colAddress,
      l.colAmount,
      l.colStatus,
      l.cancelReasonLabel,
      l.xlsAddedBy,
      l.xlsAddedAt,
      l.xlsEditedBy,
      l.xlsEditedAt,
      l.xlsCancelledBy,
      l.xlsCancelledAt,
    ];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }
    // Where the amount column is (the status etc. follow it).
    final amountCol = isIncome ? 4 : 6;
    var row = 1;
    for (final e in entries.where((e) => e.type == type)) {
      var c = 0;
      void put(CellValue? v, [CellStyle? style]) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
        );
        if (v != null) cell.value = v;
        if (style != null) cell.cellStyle = style;
        c++;
      }

      String name(String? id) =>
          id == null ? '' : (userNames[id] ?? l.unknownUser);
      DateTimeCellValue? at(DateTime? d) =>
          d == null ? null : DateTimeCellValue.fromDateTime(d);

      put(IntCellValue(e.receiptNo));
      put(DateCellValue.fromDateTime(parseDayKey(e.entryDate)), dateStyle);
      put(TextCellValue(displayName(l, e)));
      if (!isIncome) {
        put(TextCellValue(e.purpose ?? ''));
        put(TextCellValue(e.approverName ?? ''));
      }
      put(TextCellValue(e.address ?? ''));
      put(IntCellValue(e.amount), amountStyle);
      put(
        TextCellValue(
          e.status == EntryStatus.cancelled
              ? l.statusCancelled
              : l.statusActive,
        ),
      );
      put(TextCellValue(e.cancelReason ?? ''));
      put(TextCellValue(name(e.createdBy)));
      put(at(e.createdAt), dateTimeStyle);
      put(TextCellValue(name(e.editedBy)));
      put(at(e.editedAt), dateTimeStyle);
      put(TextCellValue(name(e.cancelledBy)));
      put(at(e.cancelledAt), dateTimeStyle);
      row++;
    }
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(
        i,
        i == amountCol ? 14 : (i == 2 || i == 3 ? 28 : 16),
      );
    }
  }

  if (content != ExcelContent.expense) fill(EntryType.income);
  if (content != ExcelContent.income) fill(EntryType.expense);
  excel.delete(defaultSheet!);
  final bytes = excel.save();
  if (bytes == null) throw StateError('Could not build the Excel file');
  return Uint8List.fromList(bytes);
}
