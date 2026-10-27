import 'package:flutter/material.dart';

import 'ledger_style.dart';

/// Square colour swatch for a label; a `null` color draws the outlined "No label" box.
class LabelDot extends StatelessWidget {
  const LabelDot({super.key, required this.color, this.size = 10});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          border: color == null ? Border.all(color: c.muted) : null,
        ),
      ),
    );
  }
}

/// Outlined label chip (44px tall) with a [LabelDot]; ink-filled when [selected]; [subdued] for "+ New label"-style actions.
class LabelChip extends StatelessWidget {
  const LabelChip({
    super.key,
    required this.name,
    this.color,
    this.selected = false,
    this.onTap,
    this.showDot = true,
    this.subdued = false,
  });

  final String name;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;
  final bool showDot;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final fg = selected ? c.onInk : (subdued ? c.muted : c.ink);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.ink : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: BorderSide(color: subdued ? c.muted : c.ink),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDot && !subdued) ...[
                  LabelDot(color: selected ? c.onInk : color),
                  const SizedBox(width: 8),
                ],
                Text(name, style: TextStyle(fontSize: 15, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
