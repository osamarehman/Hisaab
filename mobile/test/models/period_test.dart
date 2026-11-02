import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/models/period.dart';

void main() {
  final now = DateTime(2026, 11, 15, 9, 30);

  group('Period.range', () {
    test('a past month covers the whole month', () {
      final r = Period.month(DateTime(2026, 10, 20)).range(now: now);
      expect(r.start, DateTime(2026, 10, 1));
      expect(r.end, DateTime(2026, 10, 31));
    });

    test('the current month ends today', () {
      final r = Period.thisMonth(now: now).range(now: now);
      expect(r.start, DateTime(2026, 11, 1));
      expect(r.end, DateTime(2026, 11, 15));
    });

    test('rolling periods end today and start the day after N months ago', () {
      expect(const Period.last3().range(now: now).start, DateTime(2026, 8, 16));
      expect(const Period.last6().range(now: now).start, DateTime(2026, 5, 16));
      expect(
          const Period.last12().range(now: now).start, DateTime(2025, 11, 16));
      expect(const Period.last3().range(now: now).end, DateTime(2026, 11, 15));
    });

    test('rolling start normalises short months', () {
      // 31 May minus 3 months is "31 Feb", which rolls into March.
      final r = const Period.last3().range(now: DateTime(2026, 5, 31));
      expect(r.start, DateTime(2026, 3, 4));
    });

    test('all time has no start', () {
      final r = const Period.allTime().range(now: now);
      expect(r.start, isNull);
      expect(r.end, DateTime(2026, 11, 15));
    });

    test('a custom range is capped at today', () {
      final r = Period.custom(DateTime(2026, 9, 1), DateTime(2026, 12, 31))
          .range(now: now);
      expect(r.start, DateTime(2026, 9, 1));
      expect(r.end, DateTime(2026, 11, 15));
    });
  });

  group('queries', () {
    test('a month asks cash_flow for that month', () {
      expect(Period.month(DateTime(2026, 10, 5)).cashFlowQuery(now: now),
          {'month': '2026-10-01'});
    });

    test('rolling and custom periods send explicit dates', () {
      final expected = {'start_date': '2026-08-16', 'end_date': '2026-11-15'};
      expect(const Period.last3().cashFlowQuery(now: now), expected);
      expect(const Period.last3().transactionDates(now: now), expected);
    });

    test('all time sends period=all_time and no transaction dates', () {
      expect(const Period.allTime().cashFlowQuery(now: now),
          {'period': 'all_time'});
      expect(const Period.allTime().transactionDates(now: now), isEmpty);
    });
  });

  test('contains respects both ends', () {
    final p = Period.month(DateTime(2026, 10));
    expect(p.contains(DateTime(2026, 10, 1), now: now), isTrue);
    expect(p.contains(DateTime(2026, 10, 31, 23), now: now), isTrue);
    expect(p.contains(DateTime(2026, 11, 1), now: now), isFalse);
    expect(p.contains(DateTime(2026, 9, 30), now: now), isFalse);
    expect(const Period.allTime().contains(DateTime(1999), now: now), isTrue);
  });

  test('step moves a month at a time and keeps equality by value', () {
    final oct = Period.month(DateTime(2026, 10));
    expect(oct.step(1), Period.month(DateTime(2026, 11, 20)));
    expect(oct.step(-10), Period.month(DateTime(2025, 12)));
    expect(oct.anchorMonth(now: now), DateTime(2026, 10));
    expect(const Period.last6().anchorMonth(now: now), DateTime(2026, 11));
  });
}
