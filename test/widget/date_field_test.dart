import 'package:atia_masjid_accounts/app/theme.dart';
import 'package:atia_masjid_accounts/l10n/app_localizations.dart';
import 'package:atia_masjid_accounts/shared/widgets/date_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(
  Locale locale,
  DateTime? initial,
  ValueChanged<DateTime?> onChanged,
) {
  return MaterialApp(
    theme: buildTheme(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                DateFormField(
                  label: 'তারিখ',
                  value: initial,
                  onChanged: (d) {
                    initial = d;
                    onChanged(d);
                    setState(() {});
                  },
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the date with Bangla digits in Bangla mode (GEN-4)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const Locale('bn'), DateTime(2026, 11, 13), (_) {}),
    );
    expect(find.text('১৩/১১/২০২৬'), findsOneWidget);
  });

  testWidgets('shows English digits in English mode', (tester) async {
    await tester.pumpWidget(
      host(const Locale('en'), DateTime(2026, 11, 13), (_) {}),
    );
    expect(find.text('13/11/2026'), findsOneWidget);
  });

  testWidgets('typing a Bangla-digit date is accepted (GEN-8)', (tester) async {
    DateTime? got;
    await tester.pumpWidget(host(const Locale('bn'), null, (d) => got = d));
    await tester.enterText(find.byType(TextField), '০৫/০৩/২০২৬');
    await tester.pump();
    expect(got, DateTime(2026, 3, 5));
  });

  testWidgets('31/02/2026 is refused and the message says why (GEN-8)', (
    tester,
  ) async {
    DateTime? got = DateTime(2000);
    await tester.pumpWidget(host(const Locale('en'), null, (d) => got = d));
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '31/02/2026');
    await tester.pump();
    expect(got, isNull);
    // The message appears once the user leaves the field (here: unfocus).
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(
      find.textContaining('February 2026 has only 28 days'),
      findsOneWidget,
    );
  });

  testWidgets('the calendar button opens on the date in the field (GEN-7)', (
    tester,
  ) async {
    DateTime? got;
    await tester.pumpWidget(
      host(const Locale('en'), DateTime(2026, 11, 13), (d) => got = d),
    );
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('November 2026'),
      findsWidgets,
    ); // opened on that month
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(got, DateTime(2026, 11, 20));
    expect(find.text('20/11/2026'), findsOneWidget);
  });

  testWidgets('with an empty field the calendar opens on today (GEN-7)', (
    tester,
  ) async {
    await tester.pumpWidget(host(const Locale('en'), null, (_) {}));
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    expect(
      find.textContaining('${months[now.month - 1]} ${now.year}'),
      findsWidgets,
    );
  });
}
