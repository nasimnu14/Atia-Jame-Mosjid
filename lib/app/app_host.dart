import 'app_services.dart';

/// Lets a screen replace the app's whole data (after restoring a backup) and
/// start the app again on the new data.
class AppHost {
  const AppHost(this._replace);
  final Future<void> Function(
    Future<String?> Function(AppServices current) work,
  )
  _replace;

  /// Tears down the screens, runs [work] (which may close and overwrite the
  /// database), reopens the data and shows the sign-in screen. The text [work]
  /// returns is shown there once.
  Future<void> replaceData(
    Future<String?> Function(AppServices current) work,
  ) => _replace(work);
}
