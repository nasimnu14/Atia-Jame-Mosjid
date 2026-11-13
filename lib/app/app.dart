import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../features/sign_in/setup_screen.dart';
import '../features/sign_in/sign_in_screen.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'app_state.dart';
import 'desktop_shell.dart';
import 'theme.dart';

class AtiaApp extends StatefulWidget {
  const AtiaApp({super.key, required this.services});
  final AppServices services;

  @override
  State<AtiaApp> createState() => _AtiaAppState();
}

class _AtiaAppState extends State<AtiaApp> {
  late final AppState _state = AppState(widget.services)..load();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: widget.services),
        ChangeNotifierProvider<AppState>.value(value: _state),
      ],
      child: Consumer<AppState>(
        builder: (context, state, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
          theme: buildTheme(),
          locale: state.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const RootGate(),
        ),
      ),
    );
  }
}

/// First launch → set-up; no user signed in → sign in; else the app.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (!s.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!s.hasUsers) return const SetupScreen();
    if (s.user == null) return const SignInScreen();
    return const DesktopShell();
  }
}
