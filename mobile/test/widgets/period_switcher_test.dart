import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/models/period.dart';
import 'package:sure_mobile/theme/sure_theme.dart';
import 'package:sure_mobile/widgets/ledger/ledger.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: SureTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  final now = DateTime(2026, 11, 15);

  testWidgets('a month keeps the stepper', (tester) async {
    Period? changed;
    await tester.pumpWidget(_wrap(PeriodSwitcher(
      period: Period.month(DateTime(2026, 10)),
      now: now,
      onChanged: (p) => changed = p,
    )));

    expect(find.text('Oct 2026'), findsOneWidget);
    await tester.tap(find.text('›'));
    expect(changed, Period.month(DateTime(2026, 11)));
  });

  testWidgets('tapping the month opens the sheet and picks a period',
      (tester) async {
    Period? changed;
    await tester.pumpWidget(_wrap(PeriodSwitcher(
      period: Period.month(DateTime(2026, 11)),
      now: now,
      onChanged: (p) => changed = p,
    )));

    await tester.tap(find.byKey(const ValueKey('month-switcher-label')));
    await tester.pumpAndSettle();
    expect(find.text('Choose period'), findsOneWidget);
    expect(find.text('Custom range…'), findsOneWidget);

    await tester.tap(find.text('Last 6 months'));
    await tester.pumpAndSettle();
    expect(changed, const Period.last6());
  });

  testWidgets('a longer period shows its name and can go back to a month',
      (tester) async {
    Period? changed;
    await tester.pumpWidget(_wrap(PeriodSwitcher(
      period: const Period.allTime(),
      now: now,
      onChanged: (p) => changed = p,
    )));

    expect(find.text('All time'), findsOneWidget);
    expect(find.text('‹'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('period-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This month'));
    await tester.pumpAndSettle();
    expect(changed, Period.month(DateTime(2026, 11)));
  });

  testWidgets('fits a narrow header without overflowing', (tester) async {
    for (final period in [
      Period.month(DateTime(2026, 11)),
      Period.custom(DateTime(2025, 8, 1), DateTime(2026, 10, 15))
    ]) {
      await tester.pumpWidget(_wrap(SizedBox(
        width: 320,
        child: Row(children: [
          const Expanded(
            child: Text('Hisaab', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          PeriodSwitcher(period: period, now: now, onChanged: (_) {}),
          const SizedBox(width: 88),
        ]),
      )));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('custom range label uses English dates in Urdu', (tester) async {
    await tester.pumpWidget(_wrap(
      PeriodSwitcher(
        period: Period.custom(DateTime(2026, 8, 1), DateTime(2026, 10, 15)),
        now: now,
        onChanged: (_) {},
      ),
      locale: const Locale('ur'),
    ));

    expect(find.text('1 Aug – 15 Oct 2026'), findsOneWidget);
  });
}
