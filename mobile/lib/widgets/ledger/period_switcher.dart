import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/app_localizations.dart';
import '../../models/period.dart';
import 'ledger_style.dart';
import 'month_switcher.dart';

/// Short English label for [period]; dates and months stay English in Urdu.
String periodLabel(AppLocalizations l, Period period, {DateTime? now}) {
  switch (period.kind) {
    case PeriodKind.month:
      return DateFormat('MMM yyyy', 'en_US').format(period.anchorMonth());
    case PeriodKind.last3:
      return l.periodLast3Months;
    case PeriodKind.last6:
      return l.periodLast6Months;
    case PeriodKind.last12:
      return l.periodLast12Months;
    case PeriodKind.allTime:
      return l.periodAllTime;
    case PeriodKind.custom:
      final r = period.range(now: now);
      final sameYear = r.start!.year == r.end.year;
      final from = DateFormat(sameYear ? 'd MMM' : 'd MMM yyyy', 'en_US')
          .format(r.start!);
      final to = DateFormat('d MMM yyyy', 'en_US').format(r.end);
      return '$from – $to';
  }
}

/// Period control for Home and Activity. A month shows the "‹ Oct 2026 ›"
/// stepper; tapping its label (or the label of any other period) opens a
/// sheet with the other choices.
class PeriodSwitcher extends StatelessWidget {
  const PeriodSwitcher({
    super.key,
    required this.period,
    required this.onChanged,
    this.now,
  });

  final Period period;
  final ValueChanged<Period> onChanged;

  /// Test seam for "today".
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = LedgerColors.of(context);
    final label = periodLabel(l, period, now: now);

    if (period.isMonth) {
      return MonthSwitcher(
        month: period.anchorMonth(),
        now: now,
        label: label,
        onLabelTap: () => _choose(context),
        onChanged: (m) => onChanged(Period.month(m)),
      );
    }

    return Semantics(
      button: true,
      label: '${l.periodChoose}: $label',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('period-switcher'),
        onTap: () => _choose(context),
        child: Container(
          constraints:
              const BoxConstraints(minHeight: 44, minWidth: 84, maxWidth: 200),
          padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
          decoration: BoxDecoration(
            border: Border.all(color: c.ink),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: period.kind == PeriodKind.custom
                      ? TextDirection.ltr
                      : null,
                  style: LedgerText.figures(
                    size: 14,
                    weight: FontWeight.w500,
                    color: c.ink,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: c.ink),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _choose(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final c = LedgerColors.of(context);
    final today = now ?? DateTime.now();
    // null = custom range, picked after the sheet closes.
    final options = <(String, Period?)>[
      (l.periodThisMonth, Period.thisMonth(now: today)),
      (l.periodLast3Months, const Period.last3()),
      (l.periodLast6Months, const Period.last6()),
      (l.periodLast12Months, const Period.last12()),
      (l.periodAllTime, const Period.allTime()),
      (l.periodCustom, null),
    ];

    final picked = await showModalBottomSheet<(String, Period?)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child:
                  Text(l.periodChoose, style: LedgerText.title(color: c.ink)),
            ),
            for (final option in options)
              ListTile(
                key: ValueKey('period-option-${options.indexOf(option)}'),
                title: Text(option.$1),
                trailing: _selected(option.$2)
                    ? Icon(Icons.check, color: c.ink)
                    : null,
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;

    final choice = picked.$2;
    if (choice != null) {
      if (choice != period) onChanged(choice);
      return;
    }

    final current = period.range(now: today);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: current.start == null
          ? null
          : DateTimeRange(start: current.start!, end: current.end),
    );
    if (range != null) onChanged(Period.custom(range.start, range.end));
  }

  bool _selected(Period? option) {
    if (option == null) return period.kind == PeriodKind.custom;
    if (option.isMonth) return period.isMonth;
    return option == period;
  }
}
