import 'package:flutter/material.dart';

import 'ledger_style.dart';

/// Fixed bottom action bar (sheet fill, 1px ink top rule) for a Save button.
class LedgerBottomBar extends StatelessWidget {
  const LedgerBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.sheet,
        border: Border(top: BorderSide(color: c.ink)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: child,
        ),
      ),
    );
  }
}
