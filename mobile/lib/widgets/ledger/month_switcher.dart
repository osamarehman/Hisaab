import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'ledger_style.dart';

/// Outlined "‹ Oct 2026 ›" control; calls [onChanged] with the first day of the new month and disables future months.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
    this.now,
  });

  /// Any day in the shown month.
  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  /// Test seam for "today".
  final DateTime? now;

  static DateTime firstOf(DateTime d) => DateTime(d.year, d.month);

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final current = firstOf(month);
    final today = firstOf(now ?? DateTime.now());
    final canGoNext = current.isBefore(today);
    final label = DateFormat('MMM yyyy', 'en_US').format(current);

    Widget arrow(String glyph, String semantics, VoidCallback? onTap) {
      return Semantics(
        button: true,
        label: semantics,
        enabled: onTap != null,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Text(
                glyph,
                style: TextStyle(
                  fontSize: 20,
                  color: onTap == null ? c.hairline : c.ink,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.ink),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(
            '‹',
            'Previous month',
            () => onChanged(DateTime(current.year, current.month - 1)),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 84),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: LedgerText.figures(
                size: 14,
                weight: FontWeight.w500,
                color: c.ink,
              ),
            ),
          ),
          arrow(
            '›',
            'Next month',
            canGoNext
                ? () => onChanged(DateTime(current.year, current.month + 1))
                : null,
          ),
        ],
      ),
    );
  }
}
