import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/app_localizations.dart';

/// The installed app version, e.g. "1.0.0".
Future<String> appVersionText(AppLocalizations l) async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    return l.versionUnknown;
  }
}
