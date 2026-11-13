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

  @override
  String get newIncome => '+ নতুন আয়';

  @override
  String get newExpense => '+ নতুন ব্যয়';

  @override
  String get addIncomeTitle => 'নতুন আয় যোগ করুন';

  @override
  String get addExpenseTitle => 'নতুন ব্যয় যোগ করুন';

  @override
  String get editIncomeTitle => 'আয় সম্পাদনা করুন';

  @override
  String get editExpenseTitle => 'ব্যয় সম্পাদনা করুন';

  @override
  String get incomeDetailsTitle => 'আয়ের বিস্তারিত';

  @override
  String get expenseDetailsTitle => 'ব্যয়ের বিস্তারিত';

  @override
  String get receiptNoIncome => 'রশিদ নং';

  @override
  String get receiptNoExpense => 'ভাউচার নং';

  @override
  String get donorName => 'দাতার নাম';

  @override
  String get donorNameOptional => 'দাতার নাম (ঐচ্ছিক)';

  @override
  String get payeeNameForm => 'নাম (যাকে টাকা দেওয়া হয়েছে)';

  @override
  String get payeeName => 'নাম (প্রাপক)';

  @override
  String get purposeLabel => 'খরচ বাবদ';

  @override
  String get approvedBy => 'অনুমোদনকারী';

  @override
  String get addressLabel => 'ঠিকানা';

  @override
  String get addressOptional => 'ঠিকানা (ঐচ্ছিক)';

  @override
  String get amountTaka => 'টাকা';

  @override
  String get photosTitle => 'ছবি';

  @override
  String get donorNameHint => 'খালি রাখলে ‘অজ্ঞাত’ হিসেবে সংরক্ষণ হবে';

  @override
  String get addressHint => 'যেমন: ঘোড়াশাল, পলাশ';

  @override
  String suggestedNextReceipt(String n) {
    return 'প্রস্তাবিত পরবর্তী নম্বর: $n — রশিদ বই দেখে বদলাতে পারেন';
  }

  @override
  String suggestedNextVoucher(String n) {
    return 'প্রস্তাবিত পরবর্তী নম্বর: $n — ভাউচার বই দেখে বদলাতে পারেন';
  }

  @override
  String duplicateWarningReceipt(String date, String name, String amount) {
    return 'এই রশিদ নং আগেই একটি আয়ে ব্যবহার হয়েছে ($date · $name · $amount)। নম্বরটি আবার দেখে নিন।';
  }

  @override
  String duplicateWarningVoucher(String date, String name, String amount) {
    return 'এই ভাউচার নং আগেই একটি ব্যয়ে ব্যবহার হয়েছে ($date · $name · $amount)। নম্বরটি আবার দেখে নিন।';
  }

  @override
  String get receiptInvalid => 'নম্বরটি অঙ্কে লিখুন (১ বা তার বেশি)';

  @override
  String get approverSelect => 'যিনি অনুমোদন করেছেন তাঁকে বাছুন';

  @override
  String get approverRequired => 'অনুমোদনকারী বাছতে হবে';

  @override
  String get approverListEmpty =>
      'অনুমোদনকারীর তালিকা খালি। আগে অ্যাডমিনকে সেটিংসে নাম যোগ করতে হবে।';

  @override
  String get approverNotInList => 'তালিকা থেকে অনুমোদনকারী বাছুন';

  @override
  String get photosHintIncome =>
      'রশিদের ছবি, অথবা যে মালামাল বিক্রি হয়েছে তার ছবি';

  @override
  String get photosHintExpense =>
      'ভাউচারের ছবি, অথবা যে মালামাল কেনা হয়েছে তার ছবি';

  @override
  String get photosOptionalMany => 'ছবি (ঐচ্ছিক, একাধিক দেওয়া যাবে)';

  @override
  String get addPhoto => '+ ছবি যোগ করুন';

  @override
  String removePhoto(String label) {
    return '$label সরান';
  }

  @override
  String get photoLabelTitle => 'ছবির লেবেল';

  @override
  String get photoLabelHint =>
      'যেমন: রশিদ। খালি রাখলে বিবরণ ও নম্বর দেওয়া হবে।';

  @override
  String photoLimit(String max) {
    return 'একটি এন্ট্রিতে সর্বোচ্চ $maxটি ছবি দেওয়া যায়';
  }

  @override
  String photosCount(String n) {
    return 'ছবি ($nটি)';
  }

  @override
  String get photoReadError => 'এই ফাইলটি ছবি হিসেবে পড়া যায়নি';

  @override
  String get photoMissing => 'ছবির ফাইলটি এই কম্পিউটারে পাওয়া যায়নি';

  @override
  String openPhoto(String label) {
    return '$label বড় করে দেখুন';
  }

  @override
  String photoOf(String i, String n) {
    return 'ছবি $i / $n';
  }

  @override
  String get prevPhoto => 'আগের ছবি';

  @override
  String get nextPhoto => 'পরের ছবি';

  @override
  String get closePhoto => 'ছবি বন্ধ করুন';

  @override
  String get takePhoto => 'ক্যামেরা দিয়ে ছবি তুলুন';

  @override
  String get pickFromGallery => 'গ্যালারি থেকে বাছুন';

  @override
  String get entrySaved => 'এন্ট্রি সংরক্ষিত হয়েছে';

  @override
  String get entryUpdated => 'এন্ট্রি হালনাগাদ হয়েছে';

  @override
  String get periodToday => 'আজ';

  @override
  String get periodWeek => 'এই সপ্তাহ';

  @override
  String get periodMonth => 'এই মাস';

  @override
  String get periodYear => 'এই বছর';

  @override
  String get periodSpecific => 'নির্দিষ্ট দিন / সপ্তাহ / মাস / বছর';

  @override
  String get periodRange => 'তারিখের পরিসর';

  @override
  String get periodLabel => 'সময়কাল';

  @override
  String get unitDay => 'দিন';

  @override
  String get unitWeek => 'সপ্তাহ';

  @override
  String get unitMonth => 'মাস';

  @override
  String get unitYear => 'বছর';

  @override
  String get pickAnyDate => 'তার যেকোনো একটি তারিখ বাছুন';

  @override
  String get dateFrom => 'তারিখ থেকে';

  @override
  String get dateTo => 'তারিখ পর্যন্ত';

  @override
  String get rangeInvalid => 'শুরুর তারিখ শেষের তারিখের পরে হতে পারবে না';

  @override
  String periodDayName(String date) {
    return 'দিন: $date';
  }

  @override
  String periodWeekName(String from, String to) {
    return 'সপ্তাহ: $from – $to';
  }

  @override
  String periodMonthName(String month) {
    return 'মাস: $month';
  }

  @override
  String periodYearName(String year) {
    return 'বছর: $year';
  }

  @override
  String periodRangeName(String from, String to) {
    return '$from – $to';
  }

  @override
  String get searchLabel => 'খুঁজুন';

  @override
  String get searchHintReceipt =>
      'রশিদ নং বা নামের অংশ (নম্বর লিখে এন্টার দিলে সরাসরি খুলবে)';

  @override
  String get searchHintVoucher =>
      'ভাউচার নং বা নামের অংশ (নম্বর লিখে এন্টার দিলে সরাসরি খুলবে)';

  @override
  String entriesCount(String n) {
    return '$nটি এন্ট্রি';
  }

  @override
  String get totalLabel => 'মোট';

  @override
  String get cancelledNotCounted => 'বাতিল এন্ট্রি মোটে ধরা হয়নি';

  @override
  String showingRange(String from, String to, String total) {
    return '$from–$to দেখানো হচ্ছে, মোট $totalটি';
  }

  @override
  String get prevPage => 'আগের পাতা';

  @override
  String get nextPage => 'পরের পাতা';

  @override
  String get noEntries => 'এই নির্বাচনে কোনো এন্ট্রি নেই';

  @override
  String get colReceiptNo => 'রশিদ নং';

  @override
  String get colVoucherNo => 'ভাউচার নং';

  @override
  String get colDate => 'তারিখ';

  @override
  String get colDonor => 'দাতার নাম';

  @override
  String get colAddress => 'ঠিকানা';

  @override
  String get colPhotos => 'ছবি';

  @override
  String get colAmount => 'টাকা';

  @override
  String get colPurpose => 'খরচ বাবদ';

  @override
  String get colApprover => 'অনুমোদনকারী';

  @override
  String get statusCancelled => 'বাতিল';

  @override
  String get statusDuplicate => 'ডুপ্লিকেট';

  @override
  String duplicatesBanner(String n) {
    return 'ফোন থেকে আসা $nটি এন্ট্রির নম্বর আগে থেকেই আছে। অ্যাডমিন যাচাই করুন।';
  }

  @override
  String get showDuplicatesOnly => 'শুধু ডুপ্লিকেট দেখুন';

  @override
  String get showAll => 'সব দেখুন';

  @override
  String entryNotFoundByNumber(String no) {
    return '$no নম্বরের কোনো এন্ট্রি পাওয়া যায়নি';
  }

  @override
  String crumbReceipt(String n) {
    return 'রশিদ নং $n';
  }

  @override
  String crumbVoucher(String n) {
    return 'ভাউচার নং $n';
  }

  @override
  String get pdfExport => 'পিডিএফ এক্সপোর্ট';

  @override
  String get editEntry => 'সম্পাদনা';

  @override
  String get cancelEntry => 'এন্ট্রি বাতিল';

  @override
  String get typeLabel => 'ধরন';

  @override
  String get typeIncome => 'আয়';

  @override
  String get typeExpense => 'ব্যয়';

  @override
  String addedBy(String who, String role, String device, String when) {
    return 'যোগ করেছেন: $who ($role) · $device · $when';
  }

  @override
  String get fromPhone => 'ফোন থেকে';

  @override
  String get fromComputer => 'কম্পিউটার থেকে';

  @override
  String syncedAtDesktop(String when) {
    return 'কম্পিউটারে সিঙ্ক: $when';
  }

  @override
  String editedByLine(String who, String role, String when) {
    return 'সম্পাদনা: $who ($role) · $when';
  }

  @override
  String get notEdited => 'সম্পাদনা: হয়নি';

  @override
  String get cancelledBanner =>
      'এই এন্ট্রি বাতিল করা হয়েছে। কোনো মোট বা ব্যালেন্সে এটি ধরা হয় না।';

  @override
  String cancelledByLine(String who, String role, String when) {
    return 'বাতিল করেছেন: $who ($role) · $when';
  }

  @override
  String cancelReasonLine(String reason) {
    return 'কারণ: $reason';
  }

  @override
  String amountNotCounted(String amount) {
    return '$amount (মোটে ধরা হয়নি)';
  }

  @override
  String get duplicateDetailBanner =>
      'ফোন থেকে আসা এই এন্ট্রির নম্বর আগে থেকেই আছে। যাচাই করে নিন।';

  @override
  String get markReviewed => 'যাচাই হয়েছে';

  @override
  String get unknownUser => 'অজানা ব্যবহারকারী';

  @override
  String get approvalTitle => 'অ্যাডমিনের অনুমোদন প্রয়োজন';

  @override
  String get approvalBody =>
      'আপনি ইউজার হিসেবে সাইন ইন করেছেন। এই এন্ট্রি সম্পাদনা বা বাতিল করতে একজন অ্যাডমিন বা সুপার অ্যাডমিনকে এখানে তাঁর নিজের ইউজারনেম ও পাসওয়ার্ড দিতে হবে।';

  @override
  String get adminUsername => 'অ্যাডমিনের ইউজারনেম';

  @override
  String get adminPassword => 'অ্যাডমিনের পাসওয়ার্ড';

  @override
  String get approvalNote => 'কে অনুমোদন দিলেন তা এন্ট্রির ইতিহাসে লেখা থাকবে।';

  @override
  String get approve => 'অনুমোদন দিন';

  @override
  String get cancelTitle => 'এন্ট্রি বাতিল করুন';

  @override
  String get cancelBody =>
      'বাতিল করা এন্ট্রি মুছে যায় না। এটি তালিকায় ‘বাতিল’ চিহ্নসহ থেকে যাবে, কিন্তু কোনো মোট, সারাংশ বা ব্যালেন্সে ধরা হবে না।';

  @override
  String get cancelReasonLabel => 'বাতিলের কারণ';

  @override
  String get cancelReasonRequired => 'বাতিলের কারণ লিখতে হবে';

  @override
  String cancellingAs(String who) {
    return 'বাতিল করছেন: $who';
  }

  @override
  String get entryCancelled => 'এন্ট্রি বাতিল হয়েছে';

  @override
  String get entryAlreadyCancelled => 'এই এন্ট্রি আগেই বাতিল হয়েছে';

  @override
  String get entryNotFound => 'এই এন্ট্রিটি আর পাওয়া যাচ্ছে না';

  @override
  String get nothingToShow => 'এখনো দেখানোর কিছু নেই';

  @override
  String entrySummaryIncome(String no, String name, String amount) {
    return 'আয় · রশিদ নং $no · $name · $amount';
  }

  @override
  String entrySummaryExpense(
    String no,
    String name,
    String purpose,
    String amount,
  ) {
    return 'ব্যয় · ভাউচার নং $no · $name · $purpose · $amount';
  }

  @override
  String entriesCountPhotos(String n) {
    return '$nটি';
  }
}
