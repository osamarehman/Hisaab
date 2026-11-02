import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import 'ledger_style.dart';

/// Outlined "‹ Oct 2026 ›" control; calls [onChanged] with the first day of the new month and, unless [canGoNext] says otherwise, disables future months.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
    this.now,
    this.label,
    this.canGoNext,
    this.onLabelTap,
  });

  /// Any day in the shown month.
  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  /// Test seam for "today".
  final DateTime? now;

  /// Overrides the "Oct 2026" text (e.g. a locale-aware format).
  final String? label;

  /// Overrides the default "no months after today" limit.
  final bool? canGoNext;

  /// Makes the month label tappable (e.g. to pick another period).
  final VoidCallback? onLabelTap;

  static DateTime firstOf(DateTime d) => DateTime(d.year, d.month);

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final current = firstOf(month);
    final today = firstOf(now ?? DateTime.now());
    final canGoNext = this.canGoNext ?? current.isBefore(today);
    final label = this.label ?? DateFormat('MMM yyyy', 'en_US').format(current);

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
            l.budgetsPreviousMonth,
            () => onChanged(DateTime(current.year, current.month - 1)),
          ),
          InkWell(
            key: const ValueKey('month-switcher-label'),
            onTap: onLabelTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 84, minHeight: 44),
              child: Center(
                widthFactor: 1,
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
            ),
          ),
          arrow(
            '›',
            l.budgetsNextMonth,
            canGoNext
                ? () => onChanged(DateTime(current.year, current.month + 1))
                : null,
          ),
        ],
      ),
    );
  }
}
