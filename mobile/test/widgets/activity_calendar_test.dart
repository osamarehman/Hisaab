import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/models/transaction.dart';
import 'package:sure_mobile/theme/sure_theme.dart';
import 'package:sure_mobile/widgets/activity_calendar.dart';

Transaction _tx(
  String date,
  String amount, {
  String nature = 'expense',
  String? kind,
}) =>
    Transaction(
      accountId: 'a1',
      name: 'Entry',
      date: date,
      amount: amount,
      amountDecimal: amount,
      currency: 'PKR',
      nature: nature,
      kind: kind,
    );

void main() {
  group('paymentsByDay', () {
    test('counts and sums only outflows per day', () {
      final totals = paymentsByDay([
        _tx('2026-10-23', '1200'),
        _tx('2026-10-23', '30400'),
        _tx('2026-10-23', '250000', nature: 'income'),
        _tx('2026-10-23', '5000', kind: 'funds_movement'),
        _tx('2026-10-24', '800'),
        _tx('2026-10-24', '900', kind: 'cc_payment'),
      ]);

      expect(
          totals[DateTime(2026, 10, 23)], const DayTotal(count: 2, out: 31600));
      expect(
          totals[DateTime(2026, 10, 24)], const DayTotal(count: 1, out: 800));
      expect(totals.length, 2);
    });

    test('ignores unparseable dates and keys by day only', () {
      final totals = paymentsByDay([
        _tx('not a date', '100'),
        _tx('2026-10-05T18:30:00', '100'),
      ]);
      expect(totals.keys.single, DateTime(2026, 10, 5));
    });

    test('is empty for no payments', () {
      expect(paymentsByDay(const []), isEmpty);
    });
  });

  testWidgets('ActivityCalendar shows day summaries and selects a day',
      (tester) async {
    DateTime? picked;
    await tester.pumpWidget(MaterialApp(
      theme: SureTheme.light,
      home: Scaffold(
        body: ActivityCalendar(
          month: DateTime(2026, 10),
          today: DateTime(2026, 10, 27),
          totals: {
            DateTime(2026, 10, 23): const DayTotal(count: 3, out: 4800),
          },
          selected: null,
          onSelect: (d) => picked = d,
        ),
      ),
    ));

    expect(find.text('3 · 4.8k'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.text('32'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('calendar-day-23')));
    expect(picked, DateTime(2026, 10, 23));
  });
}
