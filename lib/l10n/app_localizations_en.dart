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
}
