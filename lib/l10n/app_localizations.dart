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
