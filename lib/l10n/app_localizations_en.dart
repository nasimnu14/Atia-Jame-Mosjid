// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Atia Jame Masjid';

  @override
  String get appTitle => 'Atia Jame Masjid — Accounts';

  @override
  String get mosquePlace => 'Ghorashal, Palash, Narsingdi';

  @override
  String get mosqueAddressLine => 'Atia, Ghorashal, Palash, Narsingdi';

  @override
  String get save => 'Save';

  @override
  String get back => 'Go back';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get tryAgain => 'Try again';

  @override
  String get signOut => 'Sign out';

  @override
  String get loading => 'Loading…';

  @override
  String get saved => 'Saved';

  @override
  String get never => 'Never';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navIncome => 'Income';

  @override
  String get navExpense => 'Expense';

  @override
  String get navSummary => 'Summary';

  @override
  String get navPdf => 'PDF reports';

  @override
  String get navExcel => 'Excel upload';

  @override
  String get navSync => 'Phone sync';

  @override
  String get navUsers => 'Users';

  @override
  String get navBackup => 'Backup';

  @override
  String get navSettings => 'Settings';

  @override
  String get mainMenu => 'Main menu';

  @override
  String get roleSuperAdmin => 'Super Admin';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleUser => 'User';

  @override
  String get language => 'Language';

  @override
  String get langBangla => 'বাংলা';

  @override
  String get langEnglish => 'English';

  @override
  String get setupWelcome => 'Welcome to the Atia Jame Masjid accounts app';

  @override
  String get setupChoose => 'To begin, choose one of the two below';

  @override
  String get setupStartFresh => 'Start fresh';

  @override
  String get setupStartFreshDesc =>
      'Create the Super Admin account. There is only one Super Admin, and only they can add new users.';

  @override
  String get fullName => 'Full name';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Enter the password again';

  @override
  String get createAccountStart => 'Create the account and start';

  @override
  String get setupRestoreTitle => 'Restore from a backup';

  @override
  String get setupRestoreDesc =>
      'On a new computer, bring back all entries, photos, users and settings from the Google Drive backup.';

  @override
  String get setupRestoreStep1 => 'Connect to the mosque\'s Google account';

  @override
  String get setupRestoreStep2 => 'Choose which backup to restore';

  @override
  String get setupRestoreStep3 =>
      'Sign in with the old Super Admin\'s username and password';

  @override
  String get connectGoogle => 'Connect to a Google account';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signIn => 'Sign in';

  @override
  String get forgotPasswordHint =>
      'If you forgot your password, ask the Super Admin to reset it.';

  @override
  String get switchLanguage => 'বাংলা';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get passwordsDontMatch => 'The two passwords do not match';

  @override
  String passwordTooShort(String n) {
    return 'Use at least $n characters';
  }

  @override
  String get passwordTooLong => 'This password is too long';

  @override
  String get usernameInvalid =>
      'Use only English letters, digits, dot, dash or underscore';

  @override
  String get usernameTaken => 'This username is already taken';

  @override
  String get invalidCredentials => 'Wrong username or password';

  @override
  String get accountDisabled =>
      'This account is disabled. Ask the Super Admin.';

  @override
  String get wrongCurrentPassword => 'The current password is wrong';

  @override
  String genericError(String detail) {
    return 'Something went wrong: $detail';
  }

  @override
  String get permissionDenied => 'You are not allowed to do this';

  @override
  String get notAnApprover =>
      'Only an Admin or the Super Admin can approve this';

  @override
  String get usersTitle => 'Users';

  @override
  String get usersSubtitle => 'Only the Super Admin can see this page';

  @override
  String get addUser => '+ New user';

  @override
  String get colName => 'Name';

  @override
  String get colRole => 'Role';

  @override
  String get colStatus => 'Status';

  @override
  String get colLastSignIn => 'Last sign-in';

  @override
  String get colActions => 'Actions';

  @override
  String get statusActive => 'Active';

  @override
  String get statusDisabled => 'Disabled';

  @override
  String get youChangeOwnPassword =>
      'You — change your own password in Settings';

  @override
  String get changeRole => 'Change role';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get disableUser => 'Disable';

  @override
  String get enableUser => 'Enable';

  @override
  String get usersNeverDeleted =>
      'Users are never deleted. A disabled user can no longer sign in, but their name stays on the entries they added. Changes reach phones at the phone\'s next sync.';

  @override
  String get roleSuperAdminCan =>
      'Everything, and only they can add users, change roles, disable users, reset passwords and restore a backup.';

  @override
  String get roleAdminCan =>
      'Edit and cancel entries, opening balance, Google account, backup and settings.';

  @override
  String get roleUserCan =>
      'Add entries, search, view details, make PDFs and Excel, sync a phone, change own password.';

  @override
  String get addUserTitle => 'Add a new user';

  @override
  String get addUserNote =>
      'Only the Super Admin can add users. There is only one Super Admin.';

  @override
  String get newPassword => 'New password';

  @override
  String resetPasswordFor(String name) {
    return 'Reset password for $name';
  }

  @override
  String changeRoleFor(String name) {
    return 'Change role of $name';
  }

  @override
  String get userAdded => 'User added';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageDesc => 'Language of the app, PDFs and Excel';

  @override
  String get openingBalanceTitle => 'Opening balance';

  @override
  String get openingBalanceDesc =>
      'The cash the mosque had in hand on the day it started using the app';

  @override
  String get adminOnlyChip => 'Admin and Super Admin';

  @override
  String get amountLabel => 'Amount (Taka)';

  @override
  String get dateLabel => 'Date';

  @override
  String get balanceFormula =>
      'Current balance = opening balance + all income − all expense';

  @override
  String get myPassword => 'My password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get confirmNewPassword => 'Enter the new password again';

  @override
  String get changePassword => 'Change password';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get approversTitle => 'Expense approvers';

  @override
  String get approversDesc =>
      'The list used for \"Approved by\" on every expense. Changing a name here does not change old expenses.';

  @override
  String get approverName => 'Approver name';

  @override
  String get addApprover => 'Add approver';

  @override
  String get approverNameTaken => 'This name is already in the list';

  @override
  String get renameApprover => 'Rename';

  @override
  String get appAndUpdate => 'App and updates';

  @override
  String version(String v) {
    return 'Version: $v';
  }

  @override
  String lastChecked(String when) {
    return 'Last checked: $when';
  }

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get datePlaceholder => 'DD/MM/YYYY';

  @override
  String get dateHelp =>
      'Type the date (e.g. 13/11/2026) or pick it from the calendar';

  @override
  String get pickDateFromCalendar => 'Pick the date from a calendar';

  @override
  String get dateEmpty => 'Enter a date';

  @override
  String get dateFormat => 'Write the date as DD/MM/YYYY, e.g. 13/11/2026';

  @override
  String get dateMonthInvalid => 'The month must be between 1 and 12';

  @override
  String get dateYearInvalid => 'The year is not valid';

  @override
  String dateDayInvalid(String max, String month, String year) {
    return 'This date does not exist: $month $year has only $max days';
  }

  @override
  String get amountRequired => 'Enter the amount';

  @override
  String get amountWhole => 'Enter a whole number of Taka, with no decimals';

  @override
  String get amountPositive => 'The amount must be more than 0';

  @override
  String get amountTooLarge => 'This amount is too large';

  @override
  String get unknownDonor => 'Unknown';

  @override
  String get versionUnknown => 'unknown';

  @override
  String get newIncome => '+ New income';

  @override
  String get newExpense => '+ New expense';

  @override
  String get addIncomeTitle => 'Add a new income';

  @override
  String get addExpenseTitle => 'Add a new expense';

  @override
  String get editIncomeTitle => 'Edit income';

  @override
  String get editExpenseTitle => 'Edit expense';

  @override
  String get incomeDetailsTitle => 'Income details';

  @override
  String get expenseDetailsTitle => 'Expense details';

  @override
  String get receiptNoIncome => 'Receipt no.';

  @override
  String get receiptNoExpense => 'Voucher no.';

  @override
  String get donorName => 'Donor\'s name';

  @override
  String get donorNameOptional => 'Donor\'s name (optional)';

  @override
  String get payeeNameForm => 'Name (who was paid)';

  @override
  String get payeeName => 'Name (payee)';

  @override
  String get purposeLabel => 'Purpose (খরচ বাবদ)';

  @override
  String get approvedBy => 'Approved by';

  @override
  String get addressLabel => 'Address';

  @override
  String get addressOptional => 'Address (optional)';

  @override
  String get amountTaka => 'Amount';

  @override
  String get photosTitle => 'Photos';

  @override
  String get donorNameHint => 'Leave blank to save as “Unknown”';

  @override
  String get addressHint => 'e.g. Ghorashal, Palash';

  @override
  String suggestedNextReceipt(String n) {
    return 'Suggested next number: $n — change it to match the receipt book';
  }

  @override
  String suggestedNextVoucher(String n) {
    return 'Suggested next number: $n — change it to match the voucher book';
  }

  @override
  String duplicateWarningReceipt(String date, String name, String amount) {
    return 'This receipt no. is already used by another income ($date · $name · $amount). Please check the number again.';
  }

  @override
  String duplicateWarningVoucher(String date, String name, String amount) {
    return 'This voucher no. is already used by another expense ($date · $name · $amount). Please check the number again.';
  }

  @override
  String get receiptInvalid => 'Enter the number as digits, 1 or more';

  @override
  String get approverSelect => 'Choose who approved this';

  @override
  String get approverRequired => 'Choose the approver';

  @override
  String get approverListEmpty =>
      'The approver list is empty. An Admin must add names in Settings first.';

  @override
  String get approverNotInList => 'Choose an approver from the list';

  @override
  String get photosHintIncome =>
      'A photo of the receipt, or of the goods that were sold';

  @override
  String get photosHintExpense =>
      'A photo of the voucher, or of the goods that were bought';

  @override
  String get photosOptionalMany => 'Photos (optional, you can add several)';

  @override
  String get addPhoto => '+ Add photo';

  @override
  String removePhoto(String label) {
    return 'Remove $label';
  }

  @override
  String get photoLabelTitle => 'Photo label';

  @override
  String get photoLabelHint =>
      'e.g. Receipt. If left blank, the description and a number are used.';

  @override
  String photoLimit(String max) {
    return 'An entry can have at most $max photos';
  }

  @override
  String photosCount(String n) {
    return 'Photos ($n)';
  }

  @override
  String get photoReadError => 'This file could not be read as a photo';

  @override
  String get photoMissing => 'The photo file was not found on this computer';

  @override
  String openPhoto(String label) {
    return 'View $label full size';
  }

  @override
  String photoOf(String i, String n) {
    return 'Photo $i of $n';
  }

  @override
  String get prevPhoto => 'Previous photo';

  @override
  String get nextPhoto => 'Next photo';

  @override
  String get closePhoto => 'Close photo';

  @override
  String get takePhoto => 'Take a photo with the camera';

  @override
  String get pickFromGallery => 'Choose from the gallery';

  @override
  String get entrySaved => 'Entry saved';

  @override
  String get entryUpdated => 'Entry updated';

  @override
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'This week';

  @override
  String get periodMonth => 'This month';

  @override
  String get periodYear => 'This year';

  @override
  String get periodSpecific => 'A chosen day / week / month / year';

  @override
  String get periodRange => 'Date range';

  @override
  String get periodLabel => 'Period';

  @override
  String get unitDay => 'Day';

  @override
  String get unitWeek => 'Week';

  @override
  String get unitMonth => 'Month';

  @override
  String get unitYear => 'Year';

  @override
  String get pickAnyDate => 'Pick any date in it';

  @override
  String get dateFrom => 'From date';

  @override
  String get dateTo => 'To date';

  @override
  String get rangeInvalid => 'The start date must not be after the end date';

  @override
  String periodDayName(String date) {
    return 'Day: $date';
  }

  @override
  String periodWeekName(String from, String to) {
    return 'Week: $from – $to';
  }

  @override
  String periodMonthName(String month) {
    return 'Month: $month';
  }

  @override
  String periodYearName(String year) {
    return 'Year: $year';
  }

  @override
  String periodRangeName(String from, String to) {
    return '$from – $to';
  }

  @override
  String get searchLabel => 'Search';

  @override
  String get searchHintReceipt =>
      'Receipt no. or part of a name (Enter opens a number)';

  @override
  String get searchHintVoucher =>
      'Voucher no. or part of a name (Enter opens a number)';

  @override
  String entriesCount(String n) {
    return '$n entries';
  }

  @override
  String get totalLabel => 'Total';

  @override
  String get cancelledNotCounted =>
      'Cancelled entries are not counted in the total';

  @override
  String showingRange(String from, String to, String total) {
    return 'Showing $from–$to of $total';
  }

  @override
  String get prevPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String get noEntries => 'No entries for this selection';

  @override
  String get colReceiptNo => 'Receipt no.';

  @override
  String get colVoucherNo => 'Voucher no.';

  @override
  String get colDate => 'Date';

  @override
  String get colDonor => 'Donor';

  @override
  String get colAddress => 'Address';

  @override
  String get colPhotos => 'Photos';

  @override
  String get colAmount => 'Amount';

  @override
  String get colPurpose => 'Purpose';

  @override
  String get colApprover => 'Approved by';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusDuplicate => 'Duplicate';

  @override
  String duplicatesBanner(String n) {
    return '$n entries from a phone have a number that already exists. An Admin should check them.';
  }

  @override
  String get showDuplicatesOnly => 'Show only duplicates';

  @override
  String get showAll => 'Show all';

  @override
  String entryNotFoundByNumber(String no) {
    return 'No entry with number $no';
  }

  @override
  String crumbReceipt(String n) {
    return 'Receipt no. $n';
  }

  @override
  String crumbVoucher(String n) {
    return 'Voucher no. $n';
  }

  @override
  String get pdfExport => 'Export PDF';

  @override
  String get editEntry => 'Edit';

  @override
  String get cancelEntry => 'Cancel entry';

  @override
  String get typeLabel => 'Type';

  @override
  String get typeIncome => 'Income';

  @override
  String get typeExpense => 'Expense';

  @override
  String addedBy(String who, String role, String device, String when) {
    return 'Added by: $who ($role) · $device · $when';
  }

  @override
  String get fromPhone => 'from a phone';

  @override
  String get fromComputer => 'from the computer';

  @override
  String syncedAtDesktop(String when) {
    return 'Synced to the computer: $when';
  }

  @override
  String editedByLine(String who, String role, String when) {
    return 'Edited by: $who ($role) · $when';
  }

  @override
  String get notEdited => 'Edited: no';

  @override
  String get cancelledBanner =>
      'This entry was cancelled. It is not counted in any total or balance.';

  @override
  String cancelledByLine(String who, String role, String when) {
    return 'Cancelled by: $who ($role) · $when';
  }

  @override
  String cancelReasonLine(String reason) {
    return 'Reason: $reason';
  }

  @override
  String amountNotCounted(String amount) {
    return '$amount (not counted)';
  }

  @override
  String get duplicateDetailBanner =>
      'This entry came from a phone with a number that already exists. Please check it.';

  @override
  String get markReviewed => 'Mark as checked';

  @override
  String get unknownUser => 'Unknown user';

  @override
  String get approvalTitle => 'An Admin\'s approval is needed';

  @override
  String get approvalBody =>
      'You are signed in as a User. To edit or cancel this entry, an Admin or the Super Admin must enter their own username and password here.';

  @override
  String get adminUsername => 'Admin\'s username';

  @override
  String get adminPassword => 'Admin\'s password';

  @override
  String get approvalNote =>
      'Who approved will be written in the entry\'s history.';

  @override
  String get approve => 'Approve';

  @override
  String get cancelTitle => 'Cancel this entry';

  @override
  String get cancelBody =>
      'A cancelled entry is not deleted. It stays in the list marked “Cancelled”, but is not counted in any total, summary or balance.';

  @override
  String get cancelReasonLabel => 'Reason for cancelling';

  @override
  String get cancelReasonRequired => 'Write the reason for cancelling';

  @override
  String cancellingAs(String who) {
    return 'Cancelling as: $who';
  }

  @override
  String get entryCancelled => 'Entry cancelled';

  @override
  String get entryAlreadyCancelled => 'This entry is already cancelled';

  @override
  String get entryNotFound => 'This entry no longer exists';

  @override
  String get nothingToShow => 'Nothing to show yet';

  @override
  String entrySummaryIncome(String no, String name, String amount) {
    return 'Income · Receipt no. $no · $name · $amount';
  }

  @override
  String entrySummaryExpense(
    String no,
    String name,
    String purpose,
    String amount,
  ) {
    return 'Expense · Voucher no. $no · $name · $purpose · $amount';
  }

  @override
  String entriesCountPhotos(String n) {
    return '$n';
  }
}
