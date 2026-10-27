import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/privacy_provider.dart';
import '../utils/money_format.dart';
import '../utils/money_masker.dart';
import 'ledger/ledger.dart';

/// Payments (outflows, transfers excluded) on one day.
@immutable
class DayTotal {
  const DayTotal({this.count = 0, this.out = 0});

  final int count;
  final double out;

  @override
  bool operator ==(Object other) =>
      other is DayTotal && other.count == count && other.out == out;

  @override
  int get hashCode => Object.hash(count, out);

  @override
  String toString() => 'DayTotal($count, $out)';
}

/// Strips the time so dates can key a map.
DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Groups [transactions] by calendar day, counting only money going out.
Map<DateTime, DayTotal> paymentsByDay(Iterable<Transaction> transactions) {
  final totals = <DateTime, DayTotal>{};
  for (final t in transactions) {
    if (t.isTransfer || !t.isExpense) continue;
    final date = DateTime.tryParse(t.date);
    if (date == null) continue;
    final key = dayOf(date);
    final prev = totals[key] ?? const DayTotal();
    totals[key] = DayTotal(count: prev.count + 1, out: prev.out + t.absAmount);
  }
  return totals;
}

/// Month grid (Monday first); each day shows its payment count and total out.
class ActivityCalendar extends StatelessWidget {
  const ActivityCalendar({
    super.key,
    required this.month,
    required this.totals,
    required this.selected,
    required this.onSelect,
    this.today,
  });

  final DateTime month;
  final Map<DateTime, DayTotal> totals;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  /// Test seam for "today".
  final DateTime? today;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final now = dayOf(today ?? DateTime.now());
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final weeks = ((lead + daysInMonth) / 7).ceil();

    Widget cell(int index) {
      final day = index - lead + 1;
      if (day < 1 || day > daysInMonth) {
        return const Expanded(child: SizedBox());
      }
      final date = DateTime(month.year, month.month, day);
      return Expanded(
        child: _DayCell(
          date: date,
          total: totals[date] ?? const DayTotal(),
          isToday: date == now,
          isSelected: selected != null && dayOf(selected!) == date,
          onTap: () => onSelect(date),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration:
              BoxDecoration(border: Border(bottom: BorderSide(color: c.ink))),
          child: Row(
            children: [
              for (final d in _weekdays)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: LedgerText.body(
                        size: 12, color: c.muted, weight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        for (var w = 0; w < weeks; w++)
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.hairline)),
            ),
            child: Row(
              children: [for (var i = 0; i < 7; i++) cell(w * 7 + i)],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.total,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final DayTotal total;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    var hidden = false;
    try {
      hidden = context.select<PrivacyProvider, bool>((p) => p.hidden);
    } on ProviderNotFoundException {
      // Privacy mode is optional (e.g. in widget tests).
    }
    final fg = isSelected ? c.onInk : c.ink;
    final amount =
        MoneyMasker.mask(MoneyFormat.compact(total.out), hidden: hidden);
    final summary = total.count == 0 ? '' : '${total.count} · $amount';

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        key: ValueKey('calendar-day-${date.day}'),
        onTap: onTap,
        child: Container(
          height: 56,
          margin: const EdgeInsets.all(1),
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          decoration: BoxDecoration(
            color: isSelected ? c.ink : null,
            border: isToday && !isSelected ? Border.all(color: c.ink) : null,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.day}',
                style: LedgerText.figures(
                  size: 13,
                  color: fg,
                  weight: isToday ? FontWeight.w600 : null,
                ),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  summary,
                  maxLines: 1,
                  style: LedgerText.figures(
                    size: 11,
                    color: isSelected ? c.onInk : c.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
