import 'package:flutter/material.dart';

import '../../theme/sure_tokens.dart';
import 'ledger_style.dart';

/// The seven label colors offered when making a label.
const List<(String, String)> labelSwatches = [
  ('Ink', '#121413'),
  ('Cobalt', '#2445C8'),
  ('Amber', '#9A4F06'),
  ('Olive', '#5A6B2E'),
  ('Plum', '#7A2E5A'),
  ('Steel', '#3D5A80'),
  ('Stone', '#6B716C'),
];

/// Row of 44px [labelSwatches] acting as a radio group over "#RRGGBB" values.
class SwatchPicker extends StatelessWidget {
  const SwatchPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (name, hex) in labelSwatches)
          Builder(builder: (context) {
            final on = hex.toUpperCase() == selected.toUpperCase();
            return Semantics(
              label: name,
              selected: on,
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(hex),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: parseHexColor(hex, c.ink),
                    borderRadius: BorderRadius.circular(SureTokens.radiusMd),
                    border: on ? Border.all(color: c.ink, width: 2) : null,
                  ),
                  child: on
                      ? Padding(
                          padding: const EdgeInsets.all(2),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(color: c.paper, width: 3),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
      ],
    );
  }
}
