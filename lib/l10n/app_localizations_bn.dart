// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'আটিয়া জামে মসজিদ';

  @override
  String get appTitle => 'আটিয়া জামে মসজিদ — হিসাব';

  @override
  String get mosquePlace => 'ঘোড়াশাল, পলাশ, নরসিংদী';

  @override
  String get mosqueAddressLine => 'আটিয়া, ঘোড়াশাল, পলাশ, নরসিংদী';

  @override
  String get save => 'সংরক্ষণ করুন';

  @override
  String get back => 'ফিরে যান';

  @override
  String get add => 'যোগ করুন';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get edit => 'সম্পাদনা';

  @override
  String get search => 'খুঁজুন';

  @override
  String get tryAgain => 'আবার চেষ্টা করুন';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get loading => 'লোড হচ্ছে…';

  @override
  String get saved => 'সংরক্ষিত হয়েছে';

  @override
  String get never => 'কখনো না';

  @override
  String get navDashboard => 'ড্যাশবোর্ড';

  @override
  String get navIncome => 'আয়';

  @override
  String get navExpense => 'ব্যয়';

  @override
  String get navSummary => 'সারাংশ';

  @override
  String get navPdf => 'পিডিএফ রিপোর্ট';

  @override
  String get navExcel => 'এক্সেল আপলোড';

  @override
  String get navSync => 'ফোন সিঙ্ক';

  @override
  String get navUsers => 'ব্যবহারকারী';

  @override
  String get navBackup => 'ব্যাকআপ';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get mainMenu => 'প্রধান মেনু';

  @override
  String get roleSuperAdmin => 'সুপার অ্যাডমিন';

  @override
  String get roleAdmin => 'অ্যাডমিন';

  @override
  String get roleUser => 'ইউজার';

  @override
  String get language => 'ভাষা';

  @override
  String get langBangla => 'বাংলা';

  @override
  String get langEnglish => 'English';

  @override
  String get setupWelcome => 'আটিয়া জামে মসজিদের হিসাব অ্যাপে স্বাগতম';

  @override
  String get setupChoose => 'শুরু করতে নিচের যেকোনো একটি বেছে নিন';

  @override
  String get setupStartFresh => 'নতুনভাবে শুরু করুন';

  @override
  String get setupStartFreshDesc =>
      'সুপার অ্যাডমিন অ্যাকাউন্ট তৈরি করুন। সুপার অ্যাডমিন একজনই থাকবেন, এবং শুধু তিনিই নতুন ব্যবহারকারী যোগ করতে পারবেন।';

  @override
  String get fullName => 'পূর্ণ নাম';

  @override
  String get username => 'ইউজারনেম';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get confirmPassword => 'পাসওয়ার্ড আবার লিখুন';

  @override
  String get createAccountStart => 'অ্যাকাউন্ট তৈরি করে শুরু করুন';

  @override
  String get setupRestoreTitle => 'ব্যাকআপ থেকে ফিরিয়ে আনুন';

  @override
  String get setupRestoreDesc =>
      'নতুন কম্পিউটারে অ্যাপ বসালে, গুগল ড্রাইভের ব্যাকআপ থেকে আগের সব এন্ট্রি, ছবি, ব্যবহারকারী ও সেটিংস ফিরিয়ে আনুন।';

  @override
  String get setupRestoreStep1 => 'মসজিদের গুগল অ্যাকাউন্টে সংযুক্ত হন';

  @override
  String get setupRestoreStep2 => 'কোন ব্যাকআপটি ফিরিয়ে আনবেন বেছে নিন';

  @override
  String get setupRestoreStep3 =>
      'পুরনো সুপার অ্যাডমিনের ইউজারনেম ও পাসওয়ার্ড দিয়ে সাইন ইন করুন';

  @override
  String get connectGoogle => 'গুগল অ্যাকাউন্টে সংযুক্ত হন';

  @override
  String get signInTitle => 'সাইন ইন করুন';

  @override
  String get signIn => 'সাইন ইন';

  @override
  String get forgotPasswordHint =>
      'পাসওয়ার্ড ভুলে গেলে সুপার অ্যাডমিনকে বলুন, তিনি রিসেট করে দেবেন।';

  @override
  String get switchLanguage => 'Switch to English';

  @override
  String get fieldRequired => 'এই ঘরটি পূরণ করা আবশ্যক';

  @override
  String get passwordsDontMatch => 'দুটি পাসওয়ার্ড মিলছে না';

  @override
  String passwordTooShort(String n) {
    return 'কমপক্ষে $nটি অক্ষর দিন';
  }

  @override
  String get passwordTooLong => 'পাসওয়ার্ডটি খুব বড়';

  @override
  String get usernameInvalid =>
      'শুধু ইংরেজি অক্ষর, সংখ্যা, ডট, ড্যাশ বা আন্ডারস্কোর ব্যবহার করুন';

  @override
  String get usernameTaken => 'এই ইউজারনেমটি আগেই নেওয়া হয়েছে';

  @override
  String get invalidCredentials => 'ইউজারনেম বা পাসওয়ার্ড ভুল';

  @override
  String get accountDisabled =>
      'এই অ্যাকাউন্টটি নিষ্ক্রিয়। সুপার অ্যাডমিনকে বলুন।';

  @override
  String get wrongCurrentPassword => 'বর্তমান পাসওয়ার্ড ভুল';

  @override
  String genericError(String detail) {
    return 'কিছু একটা সমস্যা হয়েছে: $detail';
  }

  @override
  String get permissionDenied => 'আপনার এই কাজের অনুমতি নেই';

  @override
  String get notAnApprover =>
      'শুধু অ্যাডমিন বা সুপার অ্যাডমিন এটি অনুমোদন করতে পারেন';

  @override
  String get usersTitle => 'ব্যবহারকারী';

  @override
  String get usersSubtitle => 'এই পাতা শুধু সুপার অ্যাডমিন দেখতে পান';

  @override
  String get addUser => '+ নতুন ব্যবহারকারী';

  @override
  String get colName => 'নাম';

  @override
  String get colRole => 'ভূমিকা';

  @override
  String get colStatus => 'অবস্থা';

  @override
  String get colLastSignIn => 'শেষ সাইন ইন';

  @override
  String get colActions => 'কাজ';

  @override
  String get statusActive => 'সক্রিয়';

  @override
  String get statusDisabled => 'নিষ্ক্রিয়';

  @override
  String get youChangeOwnPassword =>
      'আপনি — নিজের পাসওয়ার্ড সেটিংস থেকে বদলান';

  @override
  String get changeRole => 'ভূমিকা বদলান';

  @override
  String get resetPassword => 'পাসওয়ার্ড রিসেট';

  @override
  String get disableUser => 'নিষ্ক্রিয় করুন';

  @override
  String get enableUser => 'সক্রিয় করুন';

  @override
  String get usersNeverDeleted =>
      'ব্যবহারকারী কখনো মুছে ফেলা হয় না। নিষ্ক্রিয় করলে তিনি আর সাইন ইন করতে পারবেন না, কিন্তু তাঁর যোগ করা এন্ট্রিতে নাম থেকে যাবে। ফোনে এই পরিবর্তন পৌঁছাবে ফোনের পরের সিঙ্কে।';

  @override
  String get roleSuperAdminCan =>
      'সব কাজ, এবং শুধু তিনিই ব্যবহারকারী যোগ, ভূমিকা বদল, নিষ্ক্রিয় ও পাসওয়ার্ড রিসেট এবং ব্যাকআপ থেকে ফিরিয়ে আনতে পারেন।';

  @override
  String get roleAdminCan =>
      'এন্ট্রি সম্পাদনা ও বাতিল, প্রারম্ভিক ব্যালেন্স, গুগল অ্যাকাউন্ট, ব্যাকআপ ও সেটিংস।';

  @override
  String get roleUserCan =>
      'এন্ট্রি যোগ, খোঁজা, বিস্তারিত দেখা, পিডিএফ ও এক্সেল, ফোন সিঙ্ক এবং নিজের পাসওয়ার্ড বদল।';

  @override
  String get addUserTitle => 'নতুন ব্যবহারকারী যোগ করুন';

  @override
  String get addUserNote =>
      'শুধু সুপার অ্যাডমিন নতুন ব্যবহারকারী যোগ করতে পারেন। সুপার অ্যাডমিন একজনই থাকেন।';

  @override
  String get newPassword => 'নতুন পাসওয়ার্ড';

  @override
  String resetPasswordFor(String name) {
    return '$name-এর পাসওয়ার্ড রিসেট';
  }

  @override
  String changeRoleFor(String name) {
    return '$name-এর ভূমিকা বদলান';
  }

  @override
  String get userAdded => 'ব্যবহারকারী যোগ হয়েছে';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get languageDesc => 'অ্যাপ, পিডিএফ ও এক্সেলের ভাষা';

  @override
  String get openingBalanceTitle => 'প্রারম্ভিক ব্যালেন্স';

  @override
  String get openingBalanceDesc =>
      'অ্যাপ ব্যবহার শুরুর দিনে মসজিদের হাতে থাকা নগদ টাকা';

  @override
  String get adminOnlyChip => 'অ্যাডমিন ও সুপার অ্যাডমিন';

  @override
  String get amountLabel => 'টাকা';

  @override
  String get dateLabel => 'তারিখ';

  @override
  String get balanceFormula =>
      'বর্তমান ব্যালেন্স = প্রারম্ভিক ব্যালেন্স + সব আয় − সব ব্যয়';

  @override
  String get myPassword => 'আমার পাসওয়ার্ড';

  @override
  String get currentPassword => 'বর্তমান পাসওয়ার্ড';

  @override
  String get confirmNewPassword => 'নতুন পাসওয়ার্ড আবার লিখুন';

  @override
  String get changePassword => 'পাসওয়ার্ড বদলান';

  @override
  String get passwordChanged => 'পাসওয়ার্ড বদলানো হয়েছে';

  @override
  String get approversTitle => 'ব্যয় অনুমোদনকারী';

  @override
  String get approversDesc =>
      'প্রতিটি ব্যয়ের “অনুমোদনকারী” এই তালিকা থেকে বাছা হয়। এখানে নাম বদলালে পুরনো ব্যয় বদলায় না।';

  @override
  String get approverName => 'অনুমোদনকারীর নাম';

  @override
  String get addApprover => 'অনুমোদনকারী যোগ করুন';

  @override
  String get approverNameTaken => 'এই নামটি তালিকায় আগেই আছে';

  @override
  String get renameApprover => 'নাম বদলান';

  @override
  String get appAndUpdate => 'অ্যাপ ও আপডেট';

  @override
  String version(String v) {
    return 'সংস্করণ: $v';
  }

  @override
  String lastChecked(String when) {
    return 'শেষবার দেখা হয়েছে: $when';
  }

  @override
  String get checkForUpdates => 'আপডেট আছে কিনা দেখুন';

  @override
  String get datePlaceholder => 'দিন/মাস/বছর';

  @override
  String get dateHelp => 'লিখুন (যেমন ১৩/১১/২০২৬) অথবা ক্যালেন্ডার থেকে বাছুন';

  @override
  String get pickDateFromCalendar => 'ক্যালেন্ডার থেকে তারিখ বাছুন';

  @override
  String get dateEmpty => 'তারিখ লিখুন';

  @override
  String get dateFormat => 'তারিখ দিন/মাস/বছর আকারে লিখুন, যেমন ১৩/১১/২০২৬';

  @override
  String get dateMonthInvalid => 'মাস ১ থেকে ১২-এর মধ্যে হতে হবে';

  @override
  String get dateYearInvalid => 'বছরটি সঠিক নয়';

  @override
  String dateDayInvalid(String max, String month, String year) {
    return 'এই তারিখটি নেই: $month $year মাসে মাত্র $max দিন';
  }

  @override
  String get amountRequired => 'টাকার পরিমাণ লিখুন';

  @override
  String get amountWhole => 'পূর্ণ সংখ্যায় টাকা লিখুন, দশমিক ছাড়া';

  @override
  String get amountPositive => 'টাকার পরিমাণ ০-এর বেশি হতে হবে';

  @override
  String get amountTooLarge => 'টাকার পরিমাণ অতিরিক্ত বড়';

  @override
  String get unknownDonor => 'অজ্ঞাত';

  @override
  String get versionUnknown => 'অজানা';
}
