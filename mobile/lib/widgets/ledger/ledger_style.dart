import 'package:flutter/material.dart';

import '../../theme/sure_colors.dart';
import '../../theme/sure_theme.dart';
import '../../theme/sure_typography.dart';

/// Ledger palette resolved for the active brightness; use `LedgerColors.of(context)`.
@immutable
class LedgerColors {
  const LedgerColors({
    required this.paper,
    required this.sheet,
    required this.ink,
    required this.onInk,
    required this.muted,
    required this.hairline,
    required this.track,
    required this.moneyIn,
    required this.moneyOut,
    required this.danger,
  });

  /// Page background (#F3F4EF).
  final Color paper;

  /// Raised fill for inputs and bars (#FBFBF8).
  final Color sheet;

  /// Text and 1px rules (#121413).
  final Color ink;

  /// Text on an ink fill.
  final Color onInk;

  /// Secondary text (#4A4F4B).
  final Color muted;

  /// Row dividers (#D9DBD4).
  final Color hairline;

  /// Empty part of a bar (#E6E7E1).
  final Color track;

  /// Cobalt: money in, links.
  final Color moneyIn;

  /// Amber: money out emphasis.
  final Color moneyOut;

  /// Destructive actions.
  final Color danger;

  static LedgerColors of(BuildContext context) {
    final theme = Theme.of(context);
    final p = SureColors.of(context).palette;
    final light = theme.brightness == Brightness.light;
    return LedgerColors(
      paper: p.surface,
      sheet: p.container,
      ink: p.textPrimary,
      onInk: p.textInverse,
      muted: light ? const Color(0xFF4A4F4B) : p.textSecondary,
      hairline: SureTheme.hairlineFor(p, theme.brightness),
      track: light ? const Color(0xFFE6E7E1) : p.surfaceInset,
      moneyIn: p.success,
      moneyOut: p.warning,
      danger: light ? const Color(0xFFA3260F) : p.destructive,
    );
  }
}

/// Shared ledger text styles.
class LedgerText {
  const LedgerText._();

  /// Tabular mono figures for amounts.
  static TextStyle figures({
    double size = 16,
    Color? color,
    FontWeight? weight,
  }) =>
      TextStyle(
        fontFamily: SureFonts.mono,
        fontSize: size,
        color: color,
        fontWeight: weight,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Bricolage display type for titles and headline numbers.
  static TextStyle display({
    double size = 20,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double letterSpacing = -0.2,
    double? height,
  }) =>
      TextStyle(
        fontFamily: SureFonts.display,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

/// Parses a "#RRGGBB" category color, returning [fallback] when absent/invalid.
Color parseHexColor(String? hex, Color fallback) {
  if (hex == null) return fallback;
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
  if (h.length != 6) return fallback;
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(0xFF000000 | v);
}
