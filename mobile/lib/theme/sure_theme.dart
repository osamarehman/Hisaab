import 'package:flutter/material.dart';

import 'sure_colors.dart';
import 'sure_tokens.dart';
import 'sure_typography.dart';

/// Material theme for the "broadsheet ledger" language: flat paper surfaces,
/// hairline rules instead of shadows, ink inputs and buttons, 2px corners.
class SureTheme {
  const SureTheme._();

  static ThemeData get light => _build(SureTokens.light, Brightness.light);

  static ThemeData get dark => _build(SureTokens.dark, Brightness.dark);

  /// Hairline rule color (#D9DBD4 on paper).
  static Color hairlineFor(SureTokenPalette tokens, Brightness brightness) =>
      brightness == Brightness.light
          ? tokens.surfaceInsetHover
          : tokens.containerInsetHover;

  static ThemeData _build(SureTokenPalette tokens, Brightness brightness) {
    final ink = tokens.textPrimary;
    final hairline = hairlineFor(tokens, brightness);
    const radius = BorderRadius.all(Radius.circular(SureTokens.radiusLg));
    const shape = RoundedRectangleBorder(borderRadius: radius);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.link,
      onPrimary: tokens.textInverse,
      // Container roles pinned to neutral surfaces so un-restyled Material
      // widgets don't fall back to an off-brand tinted blue.
      primaryContainer: tokens.surfaceInset,
      onPrimaryContainer: tokens.textPrimary,
      secondary: tokens.info,
      onSecondary: tokens.textInverse,
      secondaryContainer: tokens.surfaceInset,
      onSecondaryContainer: tokens.textPrimary,
      error: tokens.destructive,
      onError: tokens.textInverse,
      errorContainer: tokens.destructiveSubtle,
      onErrorContainer: tokens.textPrimary,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      onSurfaceVariant: tokens.textSecondary,
      surfaceContainerHighest: tokens.containerInset,
      outline: tokens.borderSecondary,
      outlineVariant: hairline,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: ink),
    );

    // A button's textStyle replaces the inherited text style rather than
    // merging with it, so without the family it renders in Roboto.
    TextStyle buttonText(double size, FontWeight weight) => TextStyle(
          fontFamily: SureTokens.fontSans,
          fontFamilyFallback: SureTokens.fontFallback,
          fontSize: size,
          fontWeight: weight,
        );

    final base = ThemeData(
      fontFamily: SureTokens.fontSans,
      fontFamilyFallback: SureTokens.fontFallback,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.surface,
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      extensions: <ThemeExtension<dynamic>>[SureColors(tokens)],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: tokens.surface,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: hairline)),
        titleTextStyle: TextStyle(
          fontFamily: SureFonts.display,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.container,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: hairline),
        ),
      ),
      dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: tokens.link, width: 2),
        ),
        filled: true,
        fillColor: tokens.container,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          backgroundColor: tokens.buttonPrimary,
          foregroundColor: tokens.textInverse,
          disabledBackgroundColor: tokens.containerInset,
          disabledForegroundColor: tokens.textSubdued,
          textStyle: buttonText(16, FontWeight.w600),
          shape: shape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          backgroundColor: tokens.buttonPrimary,
          foregroundColor: tokens.textInverse,
          textStyle: buttonText(16, FontWeight.w600),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: ink,
          side: BorderSide(color: ink),
          textStyle: buttonText(15, FontWeight.w500),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: tokens.link,
          textStyle: buttonText(15, FontWeight.w500),
          shape: shape,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: ink),
        ),
        backgroundColor: Colors.transparent,
        selectedColor: ink,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.container,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: ink),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.container,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: ink),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.bgInverse,
        contentTextStyle: TextStyle(color: tokens.textInverse, fontSize: 15),
        shape: shape,
        elevation: 0,
      ),
      // The FAB is the prominent action: ink fill rather than M3's subtle
      // primaryContainer.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.buttonPrimary,
        foregroundColor: tokens.textInverse,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: shape,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: ink),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: tokens.textPrimary,
        displayColor: tokens.textPrimary,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: tokens.textPrimary,
        displayColor: tokens.textPrimary,
      ),
    );
  }
}
