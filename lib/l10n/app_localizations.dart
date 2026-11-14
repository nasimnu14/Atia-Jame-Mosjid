import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Atia Jame Masjid'**
  String get appName;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Atia Jame Masjid — Accounts'**
  String get appTitle;

  /// No description provided for @mosquePlace.
  ///
  /// In en, this message translates to:
  /// **'Ghorashal, Palash, Narsingdi'**
  String get mosquePlace;

  /// No description provided for @mosqueAddressLine.
  ///
  /// In en, this message translates to:
  /// **'Atia, Ghorashal, Palash, Narsingdi'**
  String get mosqueAddressLine;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get back;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get navIncome;

  /// No description provided for @navExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get navExpense;

  /// No description provided for @navSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get navSummary;

  /// No description provided for @navPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF reports'**
  String get navPdf;

  /// No description provided for @navExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel upload'**
  String get navExcel;

  /// No description provided for @navSync.
  ///
  /// In en, this message translates to:
  /// **'Phone sync'**
  String get navSync;

  /// No description provided for @navUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navUsers;

  /// No description provided for @navBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get navBackup;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get mainMenu;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get roleSuperAdmin;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get roleUser;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langBangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get langBangla;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @setupWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Atia Jame Masjid accounts app'**
  String get setupWelcome;

  /// No description provided for @setupChoose.
  ///
  /// In en, this message translates to:
  /// **'To begin, choose one of the two below'**
  String get setupChoose;

  /// No description provided for @setupStartFresh.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get setupStartFresh;

  /// No description provided for @setupStartFreshDesc.
  ///
  /// In en, this message translates to:
  /// **'Create the Super Admin account. There is only one Super Admin, and only they can add new users.'**
  String get setupStartFreshDesc;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the password again'**
  String get confirmPassword;

  /// No description provided for @createAccountStart.
  ///
  /// In en, this message translates to:
  /// **'Create the account and start'**
  String get createAccountStart;

  /// No description provided for @setupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup'**
  String get setupRestoreTitle;

  /// No description provided for @setupRestoreDesc.
  ///
  /// In en, this message translates to:
  /// **'On a new computer, bring back all entries, photos, users and settings from the Google Drive backup.'**
  String get setupRestoreDesc;

  /// No description provided for @setupRestoreStep1.
  ///
  /// In en, this message translates to:
  /// **'Connect to the mosque\'s Google account'**
  String get setupRestoreStep1;

  /// No description provided for @setupRestoreStep2.
  ///
  /// In en, this message translates to:
  /// **'Choose which backup to restore'**
  String get setupRestoreStep2;

  /// No description provided for @setupRestoreStep3.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the old Super Admin\'s username and password'**
  String get setupRestoreStep3;

  /// No description provided for @connectGoogle.
  ///
  /// In en, this message translates to:
  /// **'Connect to a Google account'**
  String get connectGoogle;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'If you forgot your password, ask the Super Admin to reset it.'**
  String get forgotPasswordHint;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get switchLanguage;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {n} characters'**
  String passwordTooShort(String n);

  /// No description provided for @passwordTooLong.
  ///
  /// In en, this message translates to:
  /// **'This password is too long'**
  String get passwordTooLong;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use only English letters, digits, dot, dash or underscore'**
  String get usernameInvalid;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get usernameTaken;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong username or password'**
  String get invalidCredentials;

  /// No description provided for @accountDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is disabled. Ask the Super Admin.'**
  String get accountDisabled;

  /// No description provided for @wrongCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'The current password is wrong'**
  String get wrongCurrentPassword;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {detail}'**
  String genericError(String detail);

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to do this'**
  String get permissionDenied;

  /// No description provided for @notAnApprover.
  ///
  /// In en, this message translates to:
  /// **'Only an Admin or the Super Admin can approve this'**
  String get notAnApprover;

  /// No description provided for @usersTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersTitle;

  /// No description provided for @usersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only the Super Admin can see this page'**
  String get usersSubtitle;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'+ New user'**
  String get addUser;

  /// No description provided for @colName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get colName;

  /// No description provided for @colRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get colRole;

  /// No description provided for @colStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get colStatus;

  /// No description provided for @colLastSignIn.
  ///
  /// In en, this message translates to:
  /// **'Last sign-in'**
  String get colLastSignIn;

  /// No description provided for @colActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get colActions;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get statusDisabled;

  /// No description provided for @youChangeOwnPassword.
  ///
  /// In en, this message translates to:
  /// **'You — change your own password in Settings'**
  String get youChangeOwnPassword;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get changeRole;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @disableUser.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disableUser;

  /// No description provided for @enableUser.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enableUser;

  /// No description provided for @usersNeverDeleted.
  ///
  /// In en, this message translates to:
  /// **'Users are never deleted. A disabled user can no longer sign in, but their name stays on the entries they added. Changes reach phones at the phone\'s next sync.'**
  String get usersNeverDeleted;

  /// No description provided for @roleSuperAdminCan.
  ///
  /// In en, this message translates to:
  /// **'Everything, and only they can add users, change roles, disable users, reset passwords and restore a backup.'**
  String get roleSuperAdminCan;

  /// No description provided for @roleAdminCan.
  ///
  /// In en, this message translates to:
  /// **'Edit and cancel entries, opening balance, Google account, backup and settings.'**
  String get roleAdminCan;

  /// No description provided for @roleUserCan.
  ///
  /// In en, this message translates to:
  /// **'Add entries, search, view details, make PDFs and Excel, sync a phone, change own password.'**
  String get roleUserCan;

  /// No description provided for @addUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new user'**
  String get addUserTitle;

  /// No description provided for @addUserNote.
  ///
  /// In en, this message translates to:
  /// **'Only the Super Admin can add users. There is only one Super Admin.'**
  String get addUserNote;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @resetPasswordFor.
  ///
  /// In en, this message translates to:
  /// **'Reset password for {name}'**
  String resetPasswordFor(String name);

  /// No description provided for @changeRoleFor.
  ///
  /// In en, this message translates to:
  /// **'Change role of {name}'**
  String changeRoleFor(String name);

  /// No description provided for @userAdded.
  ///
  /// In en, this message translates to:
  /// **'User added'**
  String get userAdded;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageDesc.
  ///
  /// In en, this message translates to:
  /// **'Language of the app, PDFs and Excel'**
  String get languageDesc;

  /// No description provided for @openingBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalanceTitle;

  /// No description provided for @openingBalanceDesc.
  ///
  /// In en, this message translates to:
  /// **'The cash the mosque had in hand on the day it started using the app'**
  String get openingBalanceDesc;

  /// No description provided for @adminOnlyChip.
  ///
  /// In en, this message translates to:
  /// **'Admin and Super Admin'**
  String get adminOnlyChip;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (Taka)'**
  String get amountLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @balanceFormula.
  ///
  /// In en, this message translates to:
  /// **'Current balance = opening balance + all income − all expense'**
  String get balanceFormula;

  /// No description provided for @myPassword.
  ///
  /// In en, this message translates to:
  /// **'My password'**
  String get myPassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the new password again'**
  String get confirmNewPassword;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @approversTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense approvers'**
  String get approversTitle;

  /// No description provided for @approversDesc.
  ///
  /// In en, this message translates to:
  /// **'The list used for \"Approved by\" on every expense. Changing a name here does not change old expenses.'**
  String get approversDesc;

  /// No description provided for @approverName.
  ///
  /// In en, this message translates to:
  /// **'Approver name'**
  String get approverName;

  /// No description provided for @addApprover.
  ///
  /// In en, this message translates to:
  /// **'Add approver'**
  String get addApprover;

  /// No description provided for @approverNameTaken.
  ///
  /// In en, this message translates to:
  /// **'This name is already in the list'**
  String get approverNameTaken;

  /// No description provided for @renameApprover.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameApprover;

  /// No description provided for @appAndUpdate.
  ///
  /// In en, this message translates to:
  /// **'App and updates'**
  String get appAndUpdate;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version: {v}'**
  String version(String v);

  /// No description provided for @lastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {when}'**
  String lastChecked(String when);

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @datePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get datePlaceholder;

  /// No description provided for @dateHelp.
  ///
  /// In en, this message translates to:
  /// **'Type the date (e.g. 13/11/2026) or pick it from the calendar'**
  String get dateHelp;

  /// No description provided for @pickDateFromCalendar.
  ///
  /// In en, this message translates to:
  /// **'Pick the date from a calendar'**
  String get pickDateFromCalendar;

  /// No description provided for @dateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a date'**
  String get dateEmpty;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Write the date as DD/MM/YYYY, e.g. 13/11/2026'**
  String get dateFormat;

  /// No description provided for @dateMonthInvalid.
  ///
  /// In en, this message translates to:
  /// **'The month must be between 1 and 12'**
  String get dateMonthInvalid;

  /// No description provided for @dateYearInvalid.
  ///
  /// In en, this message translates to:
  /// **'The year is not valid'**
  String get dateYearInvalid;

  /// No description provided for @dateDayInvalid.
  ///
  /// In en, this message translates to:
  /// **'This date does not exist: {month} {year} has only {max} days'**
  String dateDayInvalid(String max, String month, String year);

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount'**
  String get amountRequired;

  /// No description provided for @amountWhole.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of Taka, with no decimals'**
  String get amountWhole;

  /// No description provided for @amountPositive.
  ///
  /// In en, this message translates to:
  /// **'The amount must be more than 0'**
  String get amountPositive;

  /// No description provided for @amountTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This amount is too large'**
  String get amountTooLarge;

  /// No description provided for @unknownDonor.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownDonor;

  /// No description provided for @versionUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get versionUnknown;

  /// No description provided for @newIncome.
  ///
  /// In en, this message translates to:
  /// **'+ New income'**
  String get newIncome;

  /// No description provided for @newExpense.
  ///
  /// In en, this message translates to:
  /// **'+ New expense'**
  String get newExpense;

  /// No description provided for @addIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new income'**
  String get addIncomeTitle;

  /// No description provided for @addExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new expense'**
  String get addExpenseTitle;

  /// No description provided for @editIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit income'**
  String get editIncomeTitle;

  /// No description provided for @editExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpenseTitle;

  /// No description provided for @incomeDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Income details'**
  String get incomeDetailsTitle;

  /// No description provided for @expenseDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense details'**
  String get expenseDetailsTitle;

  /// No description provided for @receiptNoIncome.
  ///
  /// In en, this message translates to:
  /// **'Receipt no.'**
  String get receiptNoIncome;

  /// No description provided for @receiptNoExpense.
  ///
  /// In en, this message translates to:
  /// **'Voucher no.'**
  String get receiptNoExpense;

  /// No description provided for @donorName.
  ///
  /// In en, this message translates to:
  /// **'Donor\'s name'**
  String get donorName;

  /// No description provided for @donorNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Donor\'s name (optional)'**
  String get donorNameOptional;

  /// No description provided for @payeeNameForm.
  ///
  /// In en, this message translates to:
  /// **'Name (who was paid)'**
  String get payeeNameForm;

  /// No description provided for @payeeName.
  ///
  /// In en, this message translates to:
  /// **'Name (payee)'**
  String get payeeName;

  /// No description provided for @purposeLabel.
  ///
  /// In en, this message translates to:
  /// **'Purpose (খরচ বাবদ)'**
  String get purposeLabel;

  /// No description provided for @approvedBy.
  ///
  /// In en, this message translates to:
  /// **'Approved by'**
  String get approvedBy;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// No description provided for @amountTaka.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountTaka;

  /// No description provided for @photosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosTitle;

  /// No description provided for @donorNameHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to save as “Unknown”'**
  String get donorNameHint;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ghorashal, Palash'**
  String get addressHint;

  /// No description provided for @suggestedNextReceipt.
  ///
  /// In en, this message translates to:
  /// **'Suggested next number: {n} — change it to match the receipt book'**
  String suggestedNextReceipt(String n);

  /// No description provided for @suggestedNextVoucher.
  ///
  /// In en, this message translates to:
  /// **'Suggested next number: {n} — change it to match the voucher book'**
  String suggestedNextVoucher(String n);

  /// No description provided for @duplicateWarningReceipt.
  ///
  /// In en, this message translates to:
  /// **'This receipt no. is already used by another income ({date} · {name} · {amount}). Please check the number again.'**
  String duplicateWarningReceipt(String date, String name, String amount);

  /// No description provided for @duplicateWarningVoucher.
  ///
  /// In en, this message translates to:
  /// **'This voucher no. is already used by another expense ({date} · {name} · {amount}). Please check the number again.'**
  String duplicateWarningVoucher(String date, String name, String amount);

  /// No description provided for @receiptInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the number as digits, 1 or more'**
  String get receiptInvalid;

  /// No description provided for @approverSelect.
  ///
  /// In en, this message translates to:
  /// **'Choose who approved this'**
  String get approverSelect;

  /// No description provided for @approverRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the approver'**
  String get approverRequired;

  /// No description provided for @approverListEmpty.
  ///
  /// In en, this message translates to:
  /// **'The approver list is empty. An Admin must add names in Settings first.'**
  String get approverListEmpty;

  /// No description provided for @approverNotInList.
  ///
  /// In en, this message translates to:
  /// **'Choose an approver from the list'**
  String get approverNotInList;

  /// No description provided for @photosHintIncome.
  ///
  /// In en, this message translates to:
  /// **'A photo of the receipt, or of the goods that were sold'**
  String get photosHintIncome;

  /// No description provided for @photosHintExpense.
  ///
  /// In en, this message translates to:
  /// **'A photo of the voucher, or of the goods that were bought'**
  String get photosHintExpense;

  /// No description provided for @photosOptionalMany.
  ///
  /// In en, this message translates to:
  /// **'Photos (optional, you can add several)'**
  String get photosOptionalMany;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'+ Add photo'**
  String get addPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove {label}'**
  String removePhoto(String label);

  /// No description provided for @photoLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo label'**
  String get photoLabelTitle;

  /// No description provided for @photoLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Receipt. If left blank, the description and a number are used.'**
  String get photoLabelHint;

  /// No description provided for @photoLimit.
  ///
  /// In en, this message translates to:
  /// **'An entry can have at most {max} photos'**
  String photoLimit(String max);

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'Photos ({n})'**
  String photosCount(String n);

  /// No description provided for @photoReadError.
  ///
  /// In en, this message translates to:
  /// **'This file could not be read as a photo'**
  String get photoReadError;

  /// No description provided for @photoMissing.
  ///
  /// In en, this message translates to:
  /// **'The photo file was not found on this computer'**
  String get photoMissing;

  /// No description provided for @openPhoto.
  ///
  /// In en, this message translates to:
  /// **'View {label} full size'**
  String openPhoto(String label);

  /// No description provided for @photoOf.
  ///
  /// In en, this message translates to:
  /// **'Photo {i} of {n}'**
  String photoOf(String i, String n);

  /// No description provided for @prevPhoto.
  ///
  /// In en, this message translates to:
  /// **'Previous photo'**
  String get prevPhoto;

  /// No description provided for @nextPhoto.
  ///
  /// In en, this message translates to:
  /// **'Next photo'**
  String get nextPhoto;

  /// No description provided for @closePhoto.
  ///
  /// In en, this message translates to:
  /// **'Close photo'**
  String get closePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo with the camera'**
  String get takePhoto;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from the gallery'**
  String get pickFromGallery;

  /// No description provided for @entrySaved.
  ///
  /// In en, this message translates to:
  /// **'Entry saved'**
  String get entrySaved;

  /// No description provided for @entryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Entry updated'**
  String get entryUpdated;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get periodYear;

  /// No description provided for @periodSpecific.
  ///
  /// In en, this message translates to:
  /// **'A chosen day / week / month / year'**
  String get periodSpecific;

  /// No description provided for @periodRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get periodRange;

  /// No description provided for @periodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get periodLabel;

  /// No description provided for @unitDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get unitDay;

  /// No description provided for @unitWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get unitWeek;

  /// No description provided for @unitMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get unitMonth;

  /// No description provided for @unitYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get unitYear;

  /// No description provided for @pickAnyDate.
  ///
  /// In en, this message translates to:
  /// **'Pick any date in it'**
  String get pickAnyDate;

  /// No description provided for @dateFrom.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get dateFrom;

  /// No description provided for @dateTo.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get dateTo;

  /// No description provided for @rangeInvalid.
  ///
  /// In en, this message translates to:
  /// **'The start date must not be after the end date'**
  String get rangeInvalid;

  /// No description provided for @periodDayName.
  ///
  /// In en, this message translates to:
  /// **'Day: {date}'**
  String periodDayName(String date);

  /// No description provided for @periodWeekName.
  ///
  /// In en, this message translates to:
  /// **'Week: {from} – {to}'**
  String periodWeekName(String from, String to);

  /// No description provided for @periodMonthName.
  ///
  /// In en, this message translates to:
  /// **'Month: {month}'**
  String periodMonthName(String month);

  /// No description provided for @periodYearName.
  ///
  /// In en, this message translates to:
  /// **'Year: {year}'**
  String periodYearName(String year);

  /// No description provided for @periodRangeName.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String periodRangeName(String from, String to);

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @searchHintReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt no. or part of a name (Enter opens a number)'**
  String get searchHintReceipt;

  /// No description provided for @searchHintVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher no. or part of a name (Enter opens a number)'**
  String get searchHintVoucher;

  /// No description provided for @entriesCount.
  ///
  /// In en, this message translates to:
  /// **'{n} entries'**
  String entriesCount(String n);

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @cancelledNotCounted.
  ///
  /// In en, this message translates to:
  /// **'Cancelled entries are not counted in the total'**
  String get cancelledNotCounted;

  /// No description provided for @showingRange.
  ///
  /// In en, this message translates to:
  /// **'Showing {from}–{to} of {total}'**
  String showingRange(String from, String to, String total);

  /// No description provided for @prevPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get prevPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries for this selection'**
  String get noEntries;

  /// No description provided for @colReceiptNo.
  ///
  /// In en, this message translates to:
  /// **'Receipt no.'**
  String get colReceiptNo;

  /// No description provided for @colVoucherNo.
  ///
  /// In en, this message translates to:
  /// **'Voucher no.'**
  String get colVoucherNo;

  /// No description provided for @colDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @colDonor.
  ///
  /// In en, this message translates to:
  /// **'Donor'**
  String get colDonor;

  /// No description provided for @colAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get colAddress;

  /// No description provided for @colPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get colPhotos;

  /// No description provided for @colAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get colAmount;

  /// No description provided for @colPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get colPurpose;

  /// No description provided for @colApprover.
  ///
  /// In en, this message translates to:
  /// **'Approved by'**
  String get colApprover;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get statusDuplicate;

  /// No description provided for @duplicatesBanner.
  ///
  /// In en, this message translates to:
  /// **'{n} entries from a phone have a number that already exists. An Admin should check them.'**
  String duplicatesBanner(String n);

  /// No description provided for @showDuplicatesOnly.
  ///
  /// In en, this message translates to:
  /// **'Show only duplicates'**
  String get showDuplicatesOnly;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @entryNotFoundByNumber.
  ///
  /// In en, this message translates to:
  /// **'No entry with number {no}'**
  String entryNotFoundByNumber(String no);

  /// No description provided for @crumbReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt no. {n}'**
  String crumbReceipt(String n);

  /// No description provided for @crumbVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher no. {n}'**
  String crumbVoucher(String n);

  /// No description provided for @pdfExport.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get pdfExport;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editEntry;

  /// No description provided for @cancelEntry.
  ///
  /// In en, this message translates to:
  /// **'Cancel entry'**
  String get cancelEntry;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @typeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get typeIncome;

  /// No description provided for @typeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get typeExpense;

  /// No description provided for @addedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by: {who} ({role}) · {device} · {when}'**
  String addedBy(String who, String role, String device, String when);

  /// No description provided for @fromPhone.
  ///
  /// In en, this message translates to:
  /// **'from a phone'**
  String get fromPhone;

  /// No description provided for @fromComputer.
  ///
  /// In en, this message translates to:
  /// **'from the computer'**
  String get fromComputer;

  /// No description provided for @syncedAtDesktop.
  ///
  /// In en, this message translates to:
  /// **'Synced to the computer: {when}'**
  String syncedAtDesktop(String when);

  /// No description provided for @editedByLine.
  ///
  /// In en, this message translates to:
  /// **'Edited by: {who} ({role}) · {when}'**
  String editedByLine(String who, String role, String when);

  /// No description provided for @notEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited: no'**
  String get notEdited;

  /// No description provided for @cancelledBanner.
  ///
  /// In en, this message translates to:
  /// **'This entry was cancelled. It is not counted in any total or balance.'**
  String get cancelledBanner;

  /// No description provided for @cancelledByLine.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by: {who} ({role}) · {when}'**
  String cancelledByLine(String who, String role, String when);

  /// No description provided for @cancelReasonLine.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String cancelReasonLine(String reason);

  /// No description provided for @amountNotCounted.
  ///
  /// In en, this message translates to:
  /// **'{amount} (not counted)'**
  String amountNotCounted(String amount);

  /// No description provided for @duplicateDetailBanner.
  ///
  /// In en, this message translates to:
  /// **'This entry came from a phone with a number that already exists. Please check it.'**
  String get duplicateDetailBanner;

  /// No description provided for @markReviewed.
  ///
  /// In en, this message translates to:
  /// **'Mark as checked'**
  String get markReviewed;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @approvalTitle.
  ///
  /// In en, this message translates to:
  /// **'An Admin\'s approval is needed'**
  String get approvalTitle;

  /// No description provided for @approvalBody.
  ///
  /// In en, this message translates to:
  /// **'You are signed in as a User. To edit or cancel this entry, an Admin or the Super Admin must enter their own username and password here.'**
  String get approvalBody;

  /// No description provided for @adminUsername.
  ///
  /// In en, this message translates to:
  /// **'Admin\'s username'**
  String get adminUsername;

  /// No description provided for @adminPassword.
  ///
  /// In en, this message translates to:
  /// **'Admin\'s password'**
  String get adminPassword;

  /// No description provided for @approvalNote.
  ///
  /// In en, this message translates to:
  /// **'Who approved will be written in the entry\'s history.'**
  String get approvalNote;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @cancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this entry'**
  String get cancelTitle;

  /// No description provided for @cancelBody.
  ///
  /// In en, this message translates to:
  /// **'A cancelled entry is not deleted. It stays in the list marked “Cancelled”, but is not counted in any total, summary or balance.'**
  String get cancelBody;

  /// No description provided for @cancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancelling'**
  String get cancelReasonLabel;

  /// No description provided for @cancelReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Write the reason for cancelling'**
  String get cancelReasonRequired;

  /// No description provided for @cancellingAs.
  ///
  /// In en, this message translates to:
  /// **'Cancelling as: {who}'**
  String cancellingAs(String who);

  /// No description provided for @entryCancelled.
  ///
  /// In en, this message translates to:
  /// **'Entry cancelled'**
  String get entryCancelled;

  /// No description provided for @entryAlreadyCancelled.
  ///
  /// In en, this message translates to:
  /// **'This entry is already cancelled'**
  String get entryAlreadyCancelled;

  /// No description provided for @entryNotFound.
  ///
  /// In en, this message translates to:
  /// **'This entry no longer exists'**
  String get entryNotFound;

  /// No description provided for @nothingToShow.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get nothingToShow;

  /// No description provided for @entrySummaryIncome.
  ///
  /// In en, this message translates to:
  /// **'Income · Receipt no. {no} · {name} · {amount}'**
  String entrySummaryIncome(String no, String name, String amount);

  /// No description provided for @entrySummaryExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense · Voucher no. {no} · {name} · {purpose} · {amount}'**
  String entrySummaryExpense(
    String no,
    String name,
    String purpose,
    String amount,
  );

  /// No description provided for @entriesCountPhotos.
  ///
  /// In en, this message translates to:
  /// **'{n}'**
  String entriesCountPhotos(String n);

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @balanceFormulaLine.
  ///
  /// In en, this message translates to:
  /// **'Opening balance {opening} ({date}) + all income − all expense · cancelled entries not counted'**
  String balanceFormulaLine(String opening, String date);

  /// No description provided for @balanceNoOpening.
  ///
  /// In en, this message translates to:
  /// **'No opening balance set · all income − all expense · cancelled entries not counted'**
  String get balanceNoOpening;

  /// No description provided for @viewSummary.
  ///
  /// In en, this message translates to:
  /// **'View summary'**
  String get viewSummary;

  /// No description provided for @incomeToday.
  ///
  /// In en, this message translates to:
  /// **'Income today'**
  String get incomeToday;

  /// No description provided for @expenseToday.
  ///
  /// In en, this message translates to:
  /// **'Expense today'**
  String get expenseToday;

  /// No description provided for @incomeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Income this month'**
  String get incomeThisMonth;

  /// No description provided for @expenseThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Expense this month'**
  String get expenseThisMonth;

  /// No description provided for @statusBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup (every 4 hours)'**
  String get statusBackup;

  /// No description provided for @statusExcel.
  ///
  /// In en, this message translates to:
  /// **'Daily Excel upload'**
  String get statusExcel;

  /// No description provided for @statusSync.
  ///
  /// In en, this message translates to:
  /// **'Last phone sync'**
  String get statusSync;

  /// No description provided for @statusNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get statusNotYet;

  /// No description provided for @statusOkAt.
  ///
  /// In en, this message translates to:
  /// **'{when} · OK'**
  String statusOkAt(String when);

  /// No description provided for @statusFailedAt.
  ///
  /// In en, this message translates to:
  /// **'Failed · last OK: {when}'**
  String statusFailedAt(String when);

  /// No description provided for @recentEntries.
  ///
  /// In en, this message translates to:
  /// **'Recent entries'**
  String get recentEntries;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @colType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get colType;

  /// No description provided for @colNameOrPurpose.
  ///
  /// In en, this message translates to:
  /// **'Name / purpose'**
  String get colNameOrPurpose;

  /// No description provided for @makePdf.
  ///
  /// In en, this message translates to:
  /// **'Make a PDF'**
  String get makePdf;

  /// No description provided for @excelUploadBtn.
  ///
  /// In en, this message translates to:
  /// **'Excel upload'**
  String get excelUploadBtn;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get totalIncome;

  /// No description provided for @totalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total expense'**
  String get totalExpense;

  /// No description provided for @incomeMinusExpense.
  ///
  /// In en, this message translates to:
  /// **'Income − expense'**
  String get incomeMinusExpense;

  /// No description provided for @surplusNote.
  ///
  /// In en, this message translates to:
  /// **'Surplus for this period'**
  String get surplusNote;

  /// No description provided for @deficitNote.
  ///
  /// In en, this message translates to:
  /// **'Deficit for this period'**
  String get deficitNote;

  /// No description provided for @summaryNote.
  ///
  /// In en, this message translates to:
  /// **'Cancelled entries are not counted in any total. Current balance today: {balance}'**
  String summaryNote(String balance);

  /// No description provided for @breakdownDays.
  ///
  /// In en, this message translates to:
  /// **'By day · {period}'**
  String breakdownDays(String period);

  /// No description provided for @breakdownWeeks.
  ///
  /// In en, this message translates to:
  /// **'By week · {period}'**
  String breakdownWeeks(String period);

  /// No description provided for @breakdownMonths.
  ///
  /// In en, this message translates to:
  /// **'By month · {period}'**
  String breakdownMonths(String period);

  /// No description provided for @rowTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get rowTotal;

  /// No description provided for @completePeriod.
  ///
  /// In en, this message translates to:
  /// **'Complete the period above to see the figures'**
  String get completePeriod;

  /// No description provided for @pdfWhatToInclude.
  ///
  /// In en, this message translates to:
  /// **'What the report contains'**
  String get pdfWhatToInclude;

  /// No description provided for @pdfIncomeOnly.
  ///
  /// In en, this message translates to:
  /// **'Income only'**
  String get pdfIncomeOnly;

  /// No description provided for @pdfExpenseOnly.
  ///
  /// In en, this message translates to:
  /// **'Expense only'**
  String get pdfExpenseOnly;

  /// No description provided for @pdfBoth.
  ///
  /// In en, this message translates to:
  /// **'Income and expense (with a summary)'**
  String get pdfBoth;

  /// No description provided for @pdfLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'Language: {lang}. The report is made in the app\'s current language.'**
  String pdfLanguageNote(String lang);

  /// No description provided for @pdfWhereNext.
  ///
  /// In en, this message translates to:
  /// **'In the next step, choose where to save the file.'**
  String get pdfWhereNext;

  /// No description provided for @pdfPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview (first page)'**
  String get pdfPreview;

  /// No description provided for @pdfGenerating.
  ///
  /// In en, this message translates to:
  /// **'Making the PDF…'**
  String get pdfGenerating;

  /// No description provided for @pdfSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved: {path}'**
  String pdfSaved(String path);

  /// No description provided for @pdfNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The PDF was not saved'**
  String get pdfNotSaved;

  /// No description provided for @pdfFailed.
  ///
  /// In en, this message translates to:
  /// **'The PDF could not be made: {detail}'**
  String pdfFailed(String detail);

  /// No description provided for @pdfReportTitleBoth.
  ///
  /// In en, this message translates to:
  /// **'Income and expense report'**
  String get pdfReportTitleBoth;

  /// No description provided for @pdfReportTitleIncome.
  ///
  /// In en, this message translates to:
  /// **'Income report'**
  String get pdfReportTitleIncome;

  /// No description provided for @pdfReportTitleExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense report'**
  String get pdfReportTitleExpense;

  /// No description provided for @pdfCancelledFootnote.
  ///
  /// In en, this message translates to:
  /// **'Cancelled entries are listed and marked, but are not counted in any total.'**
  String get pdfCancelledFootnote;

  /// No description provided for @pdfPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {n} of {total}'**
  String pdfPageOf(String n, String total);

  /// No description provided for @pdfGeneratedOn.
  ///
  /// In en, this message translates to:
  /// **'Made on {when}'**
  String pdfGeneratedOn(String when);

  /// No description provided for @pdfNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries in this period'**
  String get pdfNoEntries;

  /// No description provided for @pdfEntryTitleIncome.
  ///
  /// In en, this message translates to:
  /// **'Income entry'**
  String get pdfEntryTitleIncome;

  /// No description provided for @pdfEntryTitleExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense entry'**
  String get pdfEntryTitleExpense;

  /// No description provided for @pdfPhotosHeading.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get pdfPhotosHeading;

  /// No description provided for @pdfHistoryHeading.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get pdfHistoryHeading;

  /// No description provided for @pdfAddedByShort.
  ///
  /// In en, this message translates to:
  /// **'Added by {who} on {when}'**
  String pdfAddedByShort(String who, String when);

  /// No description provided for @pdfEditedByShort.
  ///
  /// In en, this message translates to:
  /// **'Edited by {who} on {when}'**
  String pdfEditedByShort(String who, String when);

  /// No description provided for @pdfCancelledByShort.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by {who} on {when}'**
  String pdfCancelledByShort(String who, String when);

  /// No description provided for @pdfAmountLine.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String pdfAmountLine(String amount);

  /// No description provided for @xlsAddedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by'**
  String get xlsAddedBy;

  /// No description provided for @xlsAddedAt.
  ///
  /// In en, this message translates to:
  /// **'Added at'**
  String get xlsAddedAt;

  /// No description provided for @xlsEditedBy.
  ///
  /// In en, this message translates to:
  /// **'Edited by'**
  String get xlsEditedBy;

  /// No description provided for @xlsEditedAt.
  ///
  /// In en, this message translates to:
  /// **'Edited at'**
  String get xlsEditedAt;

  /// No description provided for @xlsCancelledBy.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by'**
  String get xlsCancelledBy;

  /// No description provided for @xlsCancelledAt.
  ///
  /// In en, this message translates to:
  /// **'Cancelled at'**
  String get xlsCancelledAt;

  /// No description provided for @excelFilePrefix.
  ///
  /// In en, this message translates to:
  /// **'income-expense'**
  String get excelFilePrefix;

  /// No description provided for @excelBoth.
  ///
  /// In en, this message translates to:
  /// **'Income and expense'**
  String get excelBoth;

  /// No description provided for @logExcelDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily · all income and expense'**
  String get logExcelDaily;

  /// No description provided for @logExcelManual.
  ///
  /// In en, this message translates to:
  /// **'Manual · {period} · {content}'**
  String logExcelManual(String period, String content);

  /// No description provided for @logBackupLine.
  ///
  /// In en, this message translates to:
  /// **'Backup · {photos} new photos'**
  String logBackupLine(String photos);

  /// No description provided for @logBackupNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Full backup to the new Google account · {photos} photos'**
  String logBackupNewAccount(String photos);

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup and Google Drive'**
  String get backupTitle;

  /// No description provided for @googleAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Google account'**
  String get googleAccountTitle;

  /// No description provided for @connectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected: {email}'**
  String connectedAs(String email);

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @googleAccountNote.
  ///
  /// In en, this message translates to:
  /// **'Backups and the daily Excel files go to this account'**
  String get googleAccountNote;

  /// No description provided for @changeAccount.
  ///
  /// In en, this message translates to:
  /// **'Change account'**
  String get changeAccount;

  /// No description provided for @googleNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not set up in this build. See docs/setup-notes.md.'**
  String get googleNotConfigured;

  /// No description provided for @connectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to Google: {detail}'**
  String connectFailed(String detail);

  /// No description provided for @accountChangedBackup.
  ///
  /// In en, this message translates to:
  /// **'A full backup is being made to the new account…'**
  String get accountChangedBackup;

  /// No description provided for @accountChangedDone.
  ///
  /// In en, this message translates to:
  /// **'Connected. The first full backup to this account is done.'**
  String get accountChangedDone;

  /// No description provided for @autoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup — every 4 hours'**
  String get autoBackupTitle;

  /// No description provided for @lastGoodBackup.
  ///
  /// In en, this message translates to:
  /// **'Last successful backup'**
  String get lastGoodBackup;

  /// No description provided for @nextBackup.
  ///
  /// In en, this message translates to:
  /// **'Next backup'**
  String get nextBackup;

  /// No description provided for @backupIncludes.
  ///
  /// In en, this message translates to:
  /// **'What a backup holds'**
  String get backupIncludes;

  /// No description provided for @backupIncludesValue.
  ///
  /// In en, this message translates to:
  /// **'All entries, photos, users and settings'**
  String get backupIncludesValue;

  /// No description provided for @backupFailedNote.
  ///
  /// In en, this message translates to:
  /// **'The last backup attempt failed: {detail}. It will be tried again every few minutes.'**
  String backupFailedNote(String detail);

  /// No description provided for @backupAppClosedNote.
  ///
  /// In en, this message translates to:
  /// **'Backups do not run while the app is closed. When the app opens and more than 4 hours have passed, a backup is made at once.'**
  String get backupAppClosedNote;

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get backupNever;

  /// No description provided for @recentBackups.
  ///
  /// In en, this message translates to:
  /// **'Recent backup attempts'**
  String get recentBackups;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup'**
  String get restoreTitle;

  /// No description provided for @superOnlyChip.
  ///
  /// In en, this message translates to:
  /// **'Super Admin only'**
  String get superOnlyChip;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'Careful: this replaces all the data on this computer with the chosen backup.'**
  String get restoreWarning;

  /// No description provided for @whichBackup.
  ///
  /// In en, this message translates to:
  /// **'Which backup'**
  String get whichBackup;

  /// No description provided for @loadBackups.
  ///
  /// In en, this message translates to:
  /// **'Load the list of backups'**
  String get loadBackups;

  /// No description provided for @noBackupsFound.
  ///
  /// In en, this message translates to:
  /// **'No backups were found in Google Drive'**
  String get noBackupsFound;

  /// No description provided for @restoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreButton;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Really restore?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All data on this computer will be replaced by the backup of {when}. A copy of the current data is kept aside first.'**
  String restoreConfirmBody(String when);

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get restoring;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Everything was restored. Photos brought back: {n}.'**
  String restoreDone(String n);

  /// No description provided for @restoreDoneMissing.
  ///
  /// In en, this message translates to:
  /// **'Everything was restored. Photos brought back: {n}. {missing} photos were not in Google Drive.'**
  String restoreDoneMissing(String n, String missing);

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not restore: {detail}'**
  String restoreFailed(String detail);

  /// No description provided for @restoreDamaged.
  ///
  /// In en, this message translates to:
  /// **'The backup file is damaged or not a backup'**
  String get restoreDamaged;

  /// No description provided for @restoreTooNew.
  ///
  /// In en, this message translates to:
  /// **'This backup is from a newer version of the app. Update the app first.'**
  String get restoreTooNew;

  /// No description provided for @restoreNeedConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect to the Google account first'**
  String get restoreNeedConnect;

  /// No description provided for @restoreSignInNext.
  ///
  /// In en, this message translates to:
  /// **'Now sign in with the old Super Admin\'s username and password.'**
  String get restoreSignInNext;

  /// No description provided for @excelTitle.
  ///
  /// In en, this message translates to:
  /// **'Excel upload (Google Drive)'**
  String get excelTitle;

  /// No description provided for @dailyAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily automatic upload'**
  String get dailyAutoTitle;

  /// No description provided for @dailyAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Every day all income and expense (without photos) go to Google Drive in one Excel file. If the computer is off or there is no internet, it uploads as soon as the app is open and online.'**
  String get dailyAutoDesc;

  /// No description provided for @googleAccountLine.
  ///
  /// In en, this message translates to:
  /// **'Google account: {email}'**
  String googleAccountLine(String email);

  /// No description provided for @lastGoodDaily.
  ///
  /// In en, this message translates to:
  /// **'Last successful daily upload'**
  String get lastGoodDaily;

  /// No description provided for @uploadNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload now'**
  String get uploadNowTitle;

  /// No description provided for @whichData.
  ///
  /// In en, this message translates to:
  /// **'Which data'**
  String get whichData;

  /// No description provided for @excelFileLine.
  ///
  /// In en, this message translates to:
  /// **'File: {name}'**
  String excelFileLine(String name);

  /// No description provided for @excelSheetsLine.
  ///
  /// In en, this message translates to:
  /// **'Sheets: {sheets}'**
  String excelSheetsLine(String sheets);

  /// No description provided for @excelCancelledNote.
  ///
  /// In en, this message translates to:
  /// **'Cancelled entries are marked in the Status column'**
  String get excelCancelledNote;

  /// No description provided for @uploadToDrive.
  ///
  /// In en, this message translates to:
  /// **'Upload to Google Drive'**
  String get uploadToDrive;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @excelUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded: {name}'**
  String excelUploaded(String name);

  /// No description provided for @excelUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The upload failed: {detail}'**
  String excelUploadFailed(String detail);

  /// No description provided for @recentUploads.
  ///
  /// In en, this message translates to:
  /// **'Recent uploads'**
  String get recentUploads;

  /// No description provided for @logOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get logOk;

  /// No description provided for @logFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get logFailed;

  /// No description provided for @connectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect a Google account first (Backup page)'**
  String get connectFirst;

  /// No description provided for @noUploadsYet.
  ///
  /// In en, this message translates to:
  /// **'No uploads yet'**
  String get noUploadsYet;

  /// No description provided for @upToDateMsg.
  ///
  /// In en, this message translates to:
  /// **'The app is up to date'**
  String get upToDateMsg;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get updateAvailableTitle;

  /// No description provided for @updateVersionLine.
  ///
  /// In en, this message translates to:
  /// **'Version {newVersion} · you are running {oldVersion}'**
  String updateVersionLine(String newVersion, String oldVersion);

  /// No description provided for @whatChanged.
  ///
  /// In en, this message translates to:
  /// **'What changed'**
  String get whatChanged;

  /// No description provided for @updateSafety1.
  ///
  /// In en, this message translates to:
  /// **'All data is backed up before the update'**
  String get updateSafety1;

  /// No description provided for @updateSafety2.
  ///
  /// In en, this message translates to:
  /// **'Every entry, photo, user, setting and sync mark stays exactly as it is'**
  String get updateSafety2;

  /// No description provided for @updateSafety3.
  ///
  /// In en, this message translates to:
  /// **'If the update fails, the previous version keeps working with all its data'**
  String get updateSafety3;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateBackingUp.
  ///
  /// In en, this message translates to:
  /// **'Backing up before the update…'**
  String get updateBackingUp;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}'**
  String updateDownloading(String percent);

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'The update could not be installed: {detail}'**
  String updateFailed(String detail);

  /// No description provided for @updateNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Update checks are not set up in this build. See docs/setup-notes.md.'**
  String get updateNotSetUp;

  /// No description provided for @updateStoreOnly.
  ///
  /// In en, this message translates to:
  /// **'This app is updated only through Google Play.'**
  String get updateStoreOnly;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates: {detail}'**
  String updateCheckFailed(String detail);

  /// No description provided for @openReleasePage.
  ///
  /// In en, this message translates to:
  /// **'Open the release page'**
  String get openReleasePage;

  /// No description provided for @updateNoInstaller.
  ///
  /// In en, this message translates to:
  /// **'This test version does not update itself. Download the new version from the release page.'**
  String get updateNoInstaller;

  /// No description provided for @updateBanner.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateBanner(String version);

  /// No description provided for @updateBannerAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get updateBannerAction;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @syncedReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'This entry was already synced to the computer, so it can no longer be changed on the phone. Correct it on the computer.'**
  String get syncedReadOnlyNote;

  /// No description provided for @syncScanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Open “Sync” in the Android app and scan this code'**
  String get syncScanInstruction;

  /// No description provided for @waitingForPhone.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a phone…'**
  String get waitingForPhone;

  /// No description provided for @phoneConnected.
  ///
  /// In en, this message translates to:
  /// **'{phone} connected — receiving…'**
  String phoneConnected(String phone);

  /// No description provided for @receivedProgress.
  ///
  /// In en, this message translates to:
  /// **'{n} entries received'**
  String receivedProgress(String n);

  /// No description provided for @codeOnce.
  ///
  /// In en, this message translates to:
  /// **'This code can be used only once'**
  String get codeOnce;

  /// No description provided for @sameWifi.
  ///
  /// In en, this message translates to:
  /// **'The phone and the computer must be on the same Wi-Fi network'**
  String get sameWifi;

  /// No description provided for @newCode.
  ///
  /// In en, this message translates to:
  /// **'Make a new code'**
  String get newCode;

  /// No description provided for @lastSyncDone.
  ///
  /// In en, this message translates to:
  /// **'Last sync finished: {n} entries received'**
  String lastSyncDone(String n);

  /// No description provided for @syncBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Income {income} · Expense {expense} · Photos {photos}'**
  String syncBreakdown(String income, String expense, String photos);

  /// No description provided for @syncDuplicateNote.
  ///
  /// In en, this message translates to:
  /// **'{n} entries had a receipt number that already existed — they were saved and marked for checking.'**
  String syncDuplicateNote(String n);

  /// No description provided for @whatIsExchanged.
  ///
  /// In en, this message translates to:
  /// **'What is exchanged'**
  String get whatIsExchanged;

  /// No description provided for @phoneToComputer.
  ///
  /// In en, this message translates to:
  /// **'Phone → computer'**
  String get phoneToComputer;

  /// No description provided for @phoneToComputerDesc.
  ///
  /// In en, this message translates to:
  /// **'Only the entries not synced yet, with all their photos'**
  String get phoneToComputerDesc;

  /// No description provided for @computerToPhone.
  ///
  /// In en, this message translates to:
  /// **'Computer → phone'**
  String get computerToPhone;

  /// No description provided for @computerToPhoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Only the user accounts and the approver list, so people can sign in on the phone. No entries are sent.'**
  String get computerToPhoneDesc;

  /// No description provided for @previousSyncs.
  ///
  /// In en, this message translates to:
  /// **'Earlier syncs'**
  String get previousSyncs;

  /// No description provided for @noSyncsYet.
  ///
  /// In en, this message translates to:
  /// **'No sync yet'**
  String get noSyncsYet;

  /// No description provided for @syncCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code (type it on the phone if scanning does not work)'**
  String get syncCodeLabel;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @syncNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'This computer is not on a network'**
  String get syncNoNetwork;

  /// No description provided for @syncServerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the sync: {detail}'**
  String syncServerFailed(String detail);

  /// No description provided for @mobilePairTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair this phone with the computer'**
  String get mobilePairTitle;

  /// No description provided for @mobilePairSub.
  ///
  /// In en, this message translates to:
  /// **'Nobody can sign in on this phone until it is paired.'**
  String get mobilePairSub;

  /// No description provided for @pairStep1.
  ///
  /// In en, this message translates to:
  /// **'On the computer, open the “Phone sync” page'**
  String get pairStep1;

  /// No description provided for @pairStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below and scan the QR code on the screen'**
  String get pairStep2;

  /// No description provided for @pairStep3.
  ///
  /// In en, this message translates to:
  /// **'Then sign in with the same username and password as on the computer'**
  String get pairStep3;

  /// No description provided for @sameWifiNote.
  ///
  /// In en, this message translates to:
  /// **'The phone and the computer must be on the same Wi-Fi network.'**
  String get sameWifiNote;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code'**
  String get scanQr;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync with the computer'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Keep the QR code from the computer\'s “Phone sync” page inside the frame'**
  String get scanHint;

  /// No description provided for @willSend.
  ///
  /// In en, this message translates to:
  /// **'What will be sent'**
  String get willSend;

  /// No description provided for @willSendLine.
  ///
  /// In en, this message translates to:
  /// **'{n} entries and {photos} photos waiting to sync'**
  String willSendLine(String n, String photos);

  /// No description provided for @enterCodeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type the code instead of scanning'**
  String get enterCodeInstead;

  /// No description provided for @codeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeFieldLabel;

  /// No description provided for @connectBtn.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectBtn;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'This is not a sync code'**
  String get invalidCode;

  /// No description provided for @cameraDenied.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be used. Type the code instead.'**
  String get cameraDenied;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing… {sent} of {total}'**
  String syncing(String sent, String total);

  /// No description provided for @syncDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync finished'**
  String get syncDoneTitle;

  /// No description provided for @syncDoneSub.
  ///
  /// In en, this message translates to:
  /// **'The computer confirmed it saved everything.'**
  String get syncDoneSub;

  /// No description provided for @syncDoneSent.
  ///
  /// In en, this message translates to:
  /// **'{n} entries and {photos} photos sent'**
  String syncDoneSent(String n, String photos);

  /// No description provided for @syncDoneKinds.
  ///
  /// In en, this message translates to:
  /// **'Income {income}, expense {expense}'**
  String syncDoneKinds(String income, String expense);

  /// No description provided for @syncDoneReadOnly.
  ///
  /// In en, this message translates to:
  /// **'These entries are now view-only'**
  String get syncDoneReadOnly;

  /// No description provided for @syncDoneReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'If something is wrong, correct it on the computer'**
  String get syncDoneReadOnlyNote;

  /// No description provided for @syncDoneAccounts.
  ///
  /// In en, this message translates to:
  /// **'User accounts were updated'**
  String get syncDoneAccounts;

  /// No description provided for @syncDoneAccountsNote.
  ///
  /// In en, this message translates to:
  /// **'New users and password changes now work on this phone too'**
  String get syncDoneAccountsNote;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backHome;

  /// No description provided for @syncFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'The sync did not finish'**
  String get syncFailedTitle;

  /// No description provided for @syncPartial.
  ///
  /// In en, this message translates to:
  /// **'{sent} entries were sent, {left} are still waiting. Scan a new code to send the rest.'**
  String syncPartial(String sent, String left);

  /// No description provided for @syncUnauthorised.
  ///
  /// In en, this message translates to:
  /// **'The code was not accepted. Show a new code on the computer and try again.'**
  String get syncUnauthorised;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the computer. Check that both are on the same Wi-Fi.'**
  String get syncOffline;

  /// No description provided for @syncRejected.
  ///
  /// In en, this message translates to:
  /// **'The computer did not accept an entry: {detail}'**
  String syncRejected(String detail);

  /// No description provided for @phoneOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'These figures are only for entries added on this phone. See the mosque\'s real balance on the computer.'**
  String get phoneOnlyNote;

  /// No description provided for @phoneBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance of this phone\'s entries'**
  String get phoneBalance;

  /// No description provided for @phoneIncomeExpense.
  ///
  /// In en, this message translates to:
  /// **'Income {income} · Expense {expense}'**
  String phoneIncomeExpense(String income, String expense);

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync: {n} entries'**
  String syncPending(String n);

  /// No description provided for @lastSyncLine.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {when}'**
  String lastSyncLine(String when);

  /// No description provided for @syncNowBtn.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncNowBtn;

  /// No description provided for @syncedPill.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncedPill;

  /// No description provided for @pendingPill.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get pendingPill;

  /// No description provided for @syncedReadOnlyBanner.
  ///
  /// In en, this message translates to:
  /// **'Synced on {when}. A synced entry cannot be changed on the phone, only viewed. If something is wrong, correct it on the computer.'**
  String syncedReadOnlyBanner(String when);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @accountsLastReceived.
  ///
  /// In en, this message translates to:
  /// **'Account data last arrived: with the sync of {when}. New accounts and password changes arrive at the next sync.'**
  String accountsLastReceived(String when);

  /// No description provided for @signInPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Use the same username and password as in the computer app.'**
  String get signInPhoneHint;

  /// No description provided for @pendingLeft.
  ///
  /// In en, this message translates to:
  /// **'{n} waiting'**
  String pendingLeft(String n);

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersionLabel;

  /// No description provided for @syncPhoneOf.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s phone'**
  String syncPhoneOf(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
