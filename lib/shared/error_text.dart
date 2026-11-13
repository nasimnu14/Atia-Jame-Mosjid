import '../features/settings/settings_service.dart';
import '../features/users/user_service.dart';
import '../l10n/app_localizations.dart';
import 'date_parse.dart';
import 'formatters.dart';
import 'money_parse.dart';
import 'password_hasher.dart';
import 'permissions.dart';

/// A user-facing message for an error thrown by the services.
String errorText(AppLocalizations l, Fmt fmt, Object e) {
  if (e is UserException) {
    return switch (e.problem) {
      UserProblem.nameRequired ||
      UserProblem.usernameRequired => l.fieldRequired,
      UserProblem.usernameInvalid => l.usernameInvalid,
      UserProblem.usernameTaken => l.usernameTaken,
      UserProblem.passwordTooShort => l.passwordTooShort(
        fmt.integer(PasswordHasher.minLength),
      ),
      UserProblem.passwordTooLong => l.passwordTooLong,
      UserProblem.wrongCurrentPassword => l.wrongCurrentPassword,
      UserProblem.invalidCredentials => l.invalidCredentials,
      UserProblem.accountDisabled => l.accountDisabled,
      UserProblem.notAnApprover => l.notAnApprover,
      UserProblem.superAdminExists ||
      UserProblem.cannotChangeSuperAdmin ||
      UserProblem.invalidRole ||
      UserProblem.notFound => l.permissionDenied,
    };
  }
  if (e is PermissionDeniedException) return l.permissionDenied;
  if (e is SettingsException) {
    return switch (e.problem) {
      SettingsProblem.nameRequired => l.fieldRequired,
      SettingsProblem.nameTaken => l.approverNameTaken,
      SettingsProblem.negativeAmount => l.amountPositive,
      SettingsProblem.notFound => l.permissionDenied,
    };
  }
  return l.genericError(e.toString());
}

String dateProblemText(AppLocalizations l, Fmt fmt, DateParseResult r) {
  switch (r.problem!) {
    case DateParseProblem.empty:
      return l.dateEmpty;
    case DateParseProblem.format:
      return l.dateFormat;
    case DateParseProblem.month:
      return l.dateMonthInvalid;
    case DateParseProblem.year:
      return l.dateYearInvalid;
    case DateParseProblem.dayNotInMonth:
      return l.dateDayInvalid(
        fmt.integer(r.maxDay!),
        fmt.monthName(r.month!),
        fmt.integer(r.year!),
      );
  }
}

String amountProblemText(AppLocalizations l, AmountProblem p) => switch (p) {
  AmountProblem.empty => l.amountRequired,
  AmountProblem.notWholeNumber => l.amountWhole,
  AmountProblem.notPositive => l.amountPositive,
  AmountProblem.tooLarge => l.amountTooLarge,
};
