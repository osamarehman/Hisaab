import 'package:intl/intl.dart';

enum PeriodKind { month, last3, last6, last12, allTime, custom }

/// The date range Home and Activity show.
///
/// Rolling periods end today and start the day after the same date N months
/// ago, so "Last 3 months" on 15 Nov covers 16 Aug – 15 Nov. Every period
/// except [PeriodKind.allTime] is sent to the server as explicit dates so the
/// totals and the transaction list always cover the same days.
class Period {
  const Period._(this.kind, {DateTime? month, DateTime? start, DateTime? end})
      : _month = month,
        _start = start,
        _end = end;

  factory Period.month(DateTime month) =>
      Period._(PeriodKind.month, month: DateTime(month.year, month.month));

  factory Period.thisMonth({DateTime? now}) =>
      Period.month(now ?? DateTime.now());

  const Period.last3() : this._(PeriodKind.last3);
  const Period.last6() : this._(PeriodKind.last6);
  const Period.last12() : this._(PeriodKind.last12);
  const Period.allTime() : this._(PeriodKind.allTime);

  factory Period.custom(DateTime start, DateTime end) => Period._(
        PeriodKind.custom,
        start: _day(start),
        end: _day(end),
      );

  final PeriodKind kind;
  final DateTime? _month;
  final DateTime? _start;
  final DateTime? _end;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static final _iso = DateFormat('yyyy-MM-dd');

  bool get isMonth => kind == PeriodKind.month;

  /// First day of the shown month, or of the month the range ends in.
  DateTime anchorMonth({DateTime? now}) {
    final end = range(now: now).end;
    return _month ?? DateTime(end.year, end.month);
  }

  /// Inclusive day range. [start] is null for all time.
  ({DateTime? start, DateTime end}) range({DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    DateTime cap(DateTime d) => d.isAfter(today) ? today : d;
    DateTime rolling(int months) =>
        DateTime(today.year, today.month - months, today.day + 1);
    switch (kind) {
      case PeriodKind.month:
        final m = _month!;
        return (start: m, end: cap(DateTime(m.year, m.month + 1, 0)));
      case PeriodKind.last3:
        return (start: rolling(3), end: today);
      case PeriodKind.last6:
        return (start: rolling(6), end: today);
      case PeriodKind.last12:
        return (start: rolling(12), end: today);
      case PeriodKind.allTime:
        return (start: null, end: today);
      case PeriodKind.custom:
        return (start: _start!, end: cap(_end!));
    }
  }

  /// `start_date`/`end_date` for the transactions API; empty for all time.
  Map<String, String> transactionDates({DateTime? now}) {
    if (kind == PeriodKind.allTime) return const {};
    final r = range(now: now);
    return {
      'start_date': _iso.format(r.start!),
      'end_date': _iso.format(r.end)
    };
  }

  /// Query for `GET /api/v1/cash_flow`.
  Map<String, String> cashFlowQuery({DateTime? now}) {
    switch (kind) {
      case PeriodKind.month:
        return {'month': _iso.format(_month!)};
      case PeriodKind.allTime:
        return const {'period': 'all_time'};
      default:
        return transactionDates(now: now);
    }
  }

  bool contains(DateTime date, {DateTime? now}) {
    final d = _day(date);
    final r = range(now: now);
    return !d.isAfter(r.end) && (r.start == null || !d.isBefore(r.start!));
  }

  /// The month before (-1) or after (+1); only meaningful for [isMonth].
  Period step(int months) =>
      Period.month(DateTime(_month!.year, _month.month + months));

  @override
  bool operator ==(Object other) =>
      other is Period &&
      other.kind == kind &&
      other._month == _month &&
      other._start == _start &&
      other._end == _end;

  @override
  int get hashCode => Object.hash(kind, _month, _start, _end);
}
