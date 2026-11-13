import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../features/sign_in/setup_screen.dart';
import '../features/sign_in/sign_in_screen.dart';
import '../l10n/app_localizations.dart';
import 'app_host.dart';
import 'app_services.dart';
import 'app_state.dart';
import 'desktop_shell.dart';
import 'theme.dart';

class AtiaApp extends StatefulWidget {
  const AtiaApp({
    super.key,
    required this.services,
    this.reopen,
    this.runDriveJobs = false,
  });
  final AppServices services;

  /// Opens the data again after a restore replaced it.
  final Future<AppServices> Function()? reopen;

  /// Run the automatic Google Drive jobs (desktop only).
  final bool runDriveJobs;

  @override
  State<AtiaApp> createState() => _AtiaAppState();
}

class _AtiaAppState extends State<AtiaApp> {
  late AppServices _services = widget.services;
  late AppState _state = AppState(_services)..load();
  bool _replacing = false;

  @override
  void initState() {
    super.initState();
    if (widget.runDriveJobs) _services.scheduler.start();
  }

  @override
  void dispose() {
    _services.scheduler.stop();
    super.dispose();
  }

  /// See [AppHost.replaceData].
  Future<void> _replaceData(
    Future<String?> Function(AppServices current) work,
  ) async {
    final reopen = widget.reopen;
    if (reopen == null) throw StateError('This app cannot reopen its data');
    final old = _services;
    // Remove every screen first, so nothing is still using the database.
    setState(() => _replacing = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    String? message;
    try {
      message = await work(old);
    } catch (e) {
      message = '$e';
    }
    old.scheduler.stop();
    await old.db.close();
    final fresh = await reopen();
    final state = AppState(fresh)..notice = message;
    await state.load();
    if (!mounted) return;
    setState(() {
      _services = fresh;
      _state = state;
      _replacing = false;
    });
    if (widget.runDriveJobs) fresh.scheduler.start();
  }

  @override
  Widget build(BuildContext context) {
    if (_replacing) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: _services),
        Provider<AppHost>.value(value: AppHost(_replaceData)),
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
