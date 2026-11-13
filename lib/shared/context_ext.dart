import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../app/app_services.dart';
import '../app/app_state.dart';
import '../l10n/app_localizations.dart';
import 'formatters.dart';

extension AppContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Follows the language the screen is showing, so it rebuilds when the
  /// language changes and is also safe to call from button handlers.
  Fmt get fmt => Fmt(bangla: Localizations.localeOf(this).languageCode == 'bn');

  AppState get app => read<AppState>();
  AppState get appWatch => watch<AppState>();
  AppServices get services => read<AppServices>();
}
