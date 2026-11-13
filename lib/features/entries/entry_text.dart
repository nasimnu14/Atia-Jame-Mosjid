import '../../data/database.dart';
import '../../data/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/formatters.dart';
import 'entry_service.dart';

String receiptNoLabel(AppLocalizations l, EntryType t) =>
    t == EntryType.income ? l.receiptNoIncome : l.receiptNoExpense;

String entryTitle(AppLocalizations l, EntryType t) =>
    t == EntryType.income ? l.navIncome : l.navExpense;

/// The donor's name, or "অজ্ঞাত" / "Unknown" when left blank (INC-3).
String displayName(AppLocalizations l, Entry e) =>
    e.name.trim().isEmpty ? l.unknownDonor : e.name;

/// One line that identifies an entry in dialogs.
String entrySummaryLine(AppLocalizations l, Fmt fmt, Entry e) =>
    e.type == EntryType.income
        ? l.entrySummaryIncome(fmt.integer(e.receiptNo), displayName(l, e), fmt.money(e.amount))
        : l.entrySummaryExpense(fmt.integer(e.receiptNo), displayName(l, e),
            e.purpose ?? '', fmt.money(e.amount));

/// Message for a field the service refused.
String entryProblemText(AppLocalizations l, Fmt fmt, EntryField field, EntryProblem p) {
  switch (p) {
    case EntryProblem.required:
      return switch (field) {
        EntryField.approver => l.approverRequired,
        EntryField.date => l.dateEmpty,
        EntryField.amount => l.amountRequired,
        EntryField.receiptNo => l.receiptInvalid,
        _ => l.fieldRequired,
      };
    case EntryProblem.notPositive:
      return l.amountPositive;
    case EntryProblem.tooMany:
      return l.photoLimit(fmt.integer(maxPhotosPerEntry));
    case EntryProblem.blankLabel:
      return l.fieldRequired;
    case EntryProblem.notInApproverList:
      return l.approverNotInList;
  }
}
