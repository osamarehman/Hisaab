import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/sure_colors.dart';
import '../../theme/sure_tokens.dart';

/// Broadsheet-ledger colors resolved from the active Sure palette, so the
/// household screens follow light/dark mode.
class HouseholdColors {
  HouseholdColors._(this.p);

  final SureTokenPalette p;

  static HouseholdColors of(BuildContext context) =>
      HouseholdColors._(SureColors.of(context).palette);

  Color get ink => p.textPrimary;
  Color get paper => p.surface;
  Color get card => p.container;
  Color get hairline => p.surfaceInsetHover;
  Color get track => p.surfaceHover;
  Color get muted => p.textSecondary;
  Color get cobalt => p.link;
  Color get amber => p.warning;
  Color get danger => p.destructive;
  Color get onInk => p.textInverse;
}

/// Type helpers matching the mockups: Bricolage for headlines and big
/// numerals, Plex Mono with tabular figures for amounts.
class HouseholdText {
  const HouseholdText._();

  static const String display = 'Bricolage Grotesque';

  static TextStyle title(Color color) => TextStyle(
        fontFamily: display,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1,
        color: color,
      );

  static TextStyle section(Color color) => TextStyle(
        fontFamily: display,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle bigNumber(Color color, {double size = 42}) => TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: -size * 0.035,
        height: 1,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle mono(Color color,
          {double size = 14, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: SureTokens.fontMono,
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle body(Color color,
          {double size = 16, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: SureTokens.fontSans,
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
}

final NumberFormat _grouped = NumberFormat('#,##0', 'en_US');

/// "182,400" — whole units, absolute value, no currency.
String groupDigits(num amount) => _grouped.format(amount.abs().round());

/// "Rs 182,400" — whole rupees, absolute value; callers add any sign.
String formatRs(num amount) => 'Rs ${groupDigits(amount)}';

/// Whole-unit amount in [currency]; PKR gets the household "Rs 1,234" form.
String formatMoney(num amount, String? currency) {
  final code = (currency ?? 'PKR').toUpperCase();
  if (code == 'PKR') return formatRs(amount);
  final symbol = NumberFormat.simpleCurrency(name: code).currencySymbol;
  return '$symbol${groupDigits(amount)}';
}

/// Same as [formatMoney] for a minor-unit (cents/paisa) value.
String formatMoneyCents(int cents, String? currency) =>
    formatMoney(cents / 100, currency);

/// Parses a server category color like "#2445C8"; null when missing/invalid.
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  final value = hex.replaceFirst('#', '');
  if (value.length != 6) return null;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(0xFF000000 | parsed);
}

/// Section head: title with a 1px ink rule underneath.
class LedgerHead extends StatelessWidget {
  const LedgerHead({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = HouseholdColors.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.ink)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: HouseholdText.section(c.ink))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Small caps section head ("YOUR LABELS ........ uses this month").
class LedgerCapsHead extends StatelessWidget {
  const LedgerCapsHead({super.key, required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final c = HouseholdColors.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.ink)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style:
                  HouseholdText.body(c.muted, size: 12, weight: FontWeight.w600)
                      .copyWith(letterSpacing: 0.5),
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: HouseholdText.mono(c.ink, size: 12)),
        ],
      ),
    );
  }
}

/// Square color swatch used as a label marker.
class LabelSquare extends StatelessWidget {
  const LabelSquare({super.key, required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: ColoredBox(color: color));
}

/// Back link header used by pushed screens ("‹ Back").
class LedgerBackHeader extends StatelessWidget {
  const LedgerBackHeader({
    super.key,
    this.label = 'Back',
    this.trailing,
    this.onBack,
  });

  final String label;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = HouseholdColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          InkWell(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left, size: 22, color: c.cobalt),
                    Text(label, style: HouseholdText.body(c.cobalt)),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Full-width ink button (primary action).
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 50,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = HouseholdColors.of(context);
    final enabled = onPressed != null && !busy;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor: enabled ? c.ink : c.track,
          foregroundColor: enabled ? c.onInk : c.muted,
          disabledForegroundColor: c.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SureTokens.radiusMd),
          ),
        ),
        child: busy
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.ink),
              )
            : Text(
                label,
                style: HouseholdText.body(
                  enabled ? c.onInk : c.muted,
                  weight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Outlined (1px ink) secondary button.
class OutlineInkButton extends StatelessWidget {
  const OutlineInkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = HouseholdColors.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.ink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SureTokens.radiusMd),
          ),
        ),
        child: Text(label,
            style: HouseholdText.body(c.ink, weight: FontWeight.w500)),
      ),
    );
  }
}

/// Text field styled like the mockup inputs (48px, 1px ink border).
InputDecoration ledgerInputDecoration(BuildContext context,
    {String? hint, Color? fill}) {
  final c = HouseholdColors.of(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(SureTokens.radiusMd),
    borderSide: BorderSide(color: c.ink),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: HouseholdText.body(c.muted),
    isDense: true,
    filled: true,
    fillColor: fill ?? c.paper,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: c.cobalt, width: 2),
    ),
  );
}

/// Bordered panel ("card" without shadow).
class LedgerPanel extends StatelessWidget {
  const LedgerPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = HouseholdColors.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.ink),
        borderRadius: BorderRadius.circular(SureTokens.radiusMd),
      ),
      child: child,
    );
  }
}

/// The seven label colors offered when making a label (from the mockup).
const List<(String, String)> labelSwatches = [
  ('Ink', '#121413'),
  ('Cobalt', '#2445C8'),
  ('Amber', '#9A4F06'),
  ('Olive', '#5A6B2E'),
  ('Plum', '#7A2E5A'),
  ('Steel', '#3D5A80'),
  ('Stone', '#6B716C'),
];

/// Row of 40px color swatches acting as a radio group.
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
    final c = HouseholdColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (name, hex) in labelSwatches)
          Semantics(
            label: name,
            selected: hex.toUpperCase() == selected.toUpperCase(),
            button: true,
            child: GestureDetector(
              onTap: () => onChanged(hex),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: parseHexColor(hex),
                  borderRadius: BorderRadius.circular(SureTokens.radiusMd),
                  border: hex.toUpperCase() == selected.toUpperCase()
                      ? Border.all(color: c.ink, width: 2)
                      : null,
                ),
                child: hex.toUpperCase() == selected.toUpperCase()
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
          ),
      ],
    );
  }
}

/// Boxed "‹ Oct 2026 ›" month switcher.
class LedgerMonthSwitcher extends StatelessWidget {
  const LedgerMonthSwitcher({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.previousTooltip = 'Previous month',
    this.nextTooltip = 'Next month',
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String previousTooltip;
  final String nextTooltip;

  @override
  Widget build(BuildContext context) {
    final c = HouseholdColors.of(context);
    Widget arrow(IconData icon, String tip, VoidCallback? onTap) => Tooltip(
          message: tip,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon,
                  size: 20, color: onTap == null ? c.hairline : c.ink),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.ink),
        borderRadius: BorderRadius.circular(SureTokens.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(Icons.chevron_left, previousTooltip, onPrevious),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 80),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: HouseholdText.mono(c.ink, weight: FontWeight.w500),
            ),
          ),
          arrow(Icons.chevron_right, nextTooltip, onNext),
        ],
      ),
    );
  }
}
