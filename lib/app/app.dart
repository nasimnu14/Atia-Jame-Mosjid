import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../features/sign_in/setup_screen.dart';
import '../features/sign_in/sign_in_screen.dart';
import '../l10n/app_localizations.dart';
import 'app_host.dart';
import 'app_services.dart';
import 'app_state.dart';
import '../features/sync/pair_screen.dart';
import 'desktop_shell.dart';
import 'mobile_shell.dart';
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
  final _rootNavKey = GlobalKey<NavigatorState>();
  String? _signedInUserId;

  /// When the user signs out (or is signed out by a sync), close every dialog
  /// and full-screen page opened above the app, so nothing is left showing
  /// data for a user who is no longer signed in.
  void _closeOverlaysOnSignOut() {
    final id = _state.user?.id;
    // Only when somebody was signed in a moment ago: with nobody signed in
    // (a new phone being paired) other changes must leave the pages alone.
    if (id == null && _signedInUserId != null) {
      _rootNavKey.currentState?.popUntil((r) => r.isFirst);
    }
    _signedInUserId = id;
  }

  @override
  void initState() {
    super.initState();
    _state.addListener(_closeOverlaysOnSignOut);
    if (widget.runDriveJobs) {
      _services.scheduler.start();
      // Once a day, quietly: a failed check is not shown.
      _services.updates.checkIfDue();
    }
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
    state.addListener(_closeOverlaysOnSignOut);
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
          navigatorKey: _rootNavKey,
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
    final phone = context.read<AppServices>().isPhone;
    if (!s.hasUsers) {
      // A phone has no set-up: it must be paired with the desktop first (MOB-5).
      return phone ? const PairScreen() : const SetupScreen();
    }
    if (s.user == null) return const SignInScreen();
    return phone ? const MobileShell() : const DesktopShell();
  }
}
