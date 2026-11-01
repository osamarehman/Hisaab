import 'sure_tokens.dart';

/// Sure type scale.
///
/// Mirrors the Tailwind font-size defaults the web design system uses. Like
/// [SureSpacing], this is hand-authored rather than generated from
/// `design/tokens/sure.tokens.json` because the type scale comes from Tailwind's
/// built-in `text-*` ramp, not the canonical token file.
///
/// Values are font sizes in logical pixels; the comment on each records the
/// Tailwind step and its paired line-height for reference. Use these instead of
/// raw `fontSize` literals so text stays on the scale.
class SureTypography {
  const SureTypography._();

  /// 12 / 16 — Tailwind `text-xs`.
  static const double xs = 12;

  /// 14 / 20 — Tailwind `text-sm`.
  static const double sm = 14;

  /// 16 / 24 — Tailwind `text-base`.
  static const double base = 16;

  /// 18 / 28 — Tailwind `text-lg`.
  static const double lg = 18;

  /// 20 / 28 — Tailwind `text-xl`.
  static const double xl = 20;

  /// 24 / 32 — Tailwind `text-2xl`.
  static const double xxl = 24;
}

/// Font families for the household "ledger" language.
class SureFonts {
  const SureFonts._();

  /// Headline numerals and screen titles.
  static const String display = 'Bricolage Grotesque';

  /// Body text.
  static const String sans = 'IBM Plex Sans';

  /// Tabular amounts.
  static const String mono = 'IBM Plex Mono';

  /// Arabic-script face for Urdu. None of the families above carry Arabic
  /// glyphs, so this is used as a fallback rather than a primary family.
  static const String urdu = 'Noto Naskh Arabic';

  /// Fallback chain for every text style: Urdu glyphs first, then the
  /// platform fallbacks the tokens already declare.
  static const List<String> fallback = <String>[
    urdu,
    ...SureTokens.fontFallback,
  ];
}
