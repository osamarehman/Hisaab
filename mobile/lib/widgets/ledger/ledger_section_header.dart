import 'package:flutter/material.dart';

import 'ledger_style.dart';

/// Section title over a 1px ink rule, with an optional link-style action on the right.
class LedgerSectionHeader extends StatelessWidget {
  const LedgerSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.ink)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: LedgerText.display(color: c.ink)),
            ),
          ),
          if (actionLabel != null)
            InkWell(
              onTap: onAction,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 1,
                  child: Text(
                    actionLabel!,
                    style: TextStyle(fontSize: 14, color: c.moneyIn),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
