import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/screens/transaction_form_screen.dart';
import 'package:sure_mobile/theme/sure_theme.dart';
import 'package:sure_mobile/widgets/ledger/ledger.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: SureTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('MonthSwitcher', () {
    testWidgets('shows the month and steps back', (tester) async {
      DateTime? changed;
      await tester.pumpWidget(_wrap(MonthSwitcher(
        month: DateTime(2026, 10, 15),
        now: DateTime(2026, 10, 27),
        onChanged: (m) => changed = m,
      )));

      expect(find.text('Oct 2026'), findsOneWidget);
      await tester.tap(find.text('‹'));
      expect(changed, DateTime(2026, 9));
    });

    testWidgets('disables next on the current month', (tester) async {
      DateTime? changed;
      await tester.pumpWidget(_wrap(MonthSwitcher(
        month: DateTime(2026, 10),
        now: DateTime(2026, 10, 27),
        onChanged: (m) => changed = m,
      )));

      await tester.tap(find.text('›'));
      expect(changed, isNull);
    });

    testWidgets('steps forward across a year boundary', (tester) async {
      DateTime? changed;
      await tester.pumpWidget(_wrap(MonthSwitcher(
        month: DateTime(2025, 12),
        now: DateTime(2026, 10, 27),
        onChanged: (m) => changed = m,
      )));

      await tester.tap(find.text('›'));
      expect(changed, DateTime(2026, 1));
    });
  });

  testWidgets('RupeeAmount renders Rs with grouping', (tester) async {
    await tester.pumpWidget(_wrap(const RupeeAmount(182400, currency: 'PKR')));
    expect(find.text('Rs 182,400'), findsOneWidget);
  });

  testWidgets('LabelChip reports taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(LabelChip(
      name: 'Groceries',
      color: const Color(0xFF121413),
      onTap: () => tapped = true,
    )));
    await tester.tap(find.text('Groceries'));
    expect(tapped, isTrue);
    expect(tester.getSize(find.byType(LabelChip)).height,
        greaterThanOrEqualTo(44));
  });

  test('parseHexColor reads #RRGGBB and falls back', () {
    const fallback = Color(0xFF000000);
    expect(parseHexColor('#2445C8', fallback), const Color(0xFF2445C8));
    expect(parseHexColor(null, fallback), fallback);
    expect(parseHexColor('nope', fallback), fallback);
  });

  test('GroupedAmountFormatter groups digits and keeps two decimals', () {
    final f = GroupedAmountFormatter();
    String run(String text) => f
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text))
        .text;
    expect(run('2450'), '2,450');
    expect(run('1234567.891'), '1,234,567.89');
    expect(run('12.3.4'), '12.34');
    expect(run(''), '');
  });
}
