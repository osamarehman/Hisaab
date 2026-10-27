// GENERATED CODE - DO NOT EDIT BY HAND.
// Source: design/tokens/sure.tokens.json
// Build: node mobile/tool/generate_sure_tokens.mjs

import 'package:flutter/painting.dart';

class SureTokens {
  const SureTokens._();

  static const String version = '3.0.0';
  static const String fontSans = 'IBM Plex Sans';
  static const String fontMono = 'IBM Plex Mono';

  // Keep the existing Flutter fallback behavior until native mobile font assets
  // are registered. The canonical web stack remains in sure.tokens.json.
  static const List<String> fontFallback = <String>[
    'Inter',
    'Arial',
    'sans-serif',
  ];

  static const double radiusMd = 2.0;
  static const double radiusLg = 2.0;

  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;

  static const light = SureTokenPalette(
    surface: Color(0xFFF3F4EF),
    surfaceHover: Color(0xFFE9EAE4),
    surfaceInset: Color(0xFFE9EAE4),
    surfaceInsetHover: Color(0xFFD9DBD4),
    container: Color(0xFFFBFBF8),
    containerHover: Color(0xFFF3F4EF),
    containerInset: Color(0xFFF3F4EF),
    containerInsetHover: Color(0xFFE9EAE4),
    success: Color(0xFF2445C8),
    warning: Color(0xFF9A4F06),
    destructive: Color(0xFFF13636),
    destructiveSubtle: Color(0xFFFEB9B3),
    info: Color(0xFF2445C8),
    link: Color(0xFF2445C8),
    shadow: Color(0x0F0B0D0C),
    focusRing: Color(0x800B0D0C),
    bgInverse: Color(0xFF222522),
    textPrimary: Color(0xFF121413),
    textInverse: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF6B716C),
    textSubdued: Color(0xFF8A8F8A),
    borderPrimary: Color(0x260B0D0C),
    borderSecondary: Color(0x1A0B0D0C),
    borderSubdued: Color(0x0D0B0D0C),
    buttonPrimary: Color(0xFF121413),
    buttonPrimaryHover: Color(0xFF222522),
    buttonDestructive: Color(0xFFEC2222),
    buttonDestructiveHover: Color(0xFFC91313),
    shadowXs: [BoxShadow(color: Color(0x000B0D0C), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 0.0)],
    shadowSm: [BoxShadow(color: Color(0x000B0D0C), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 0.0)],
    shadowMd: [BoxShadow(color: Color(0x000B0D0C), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 0.0)],
    shadowLg: [BoxShadow(color: Color(0x000B0D0C), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 0.0)],
    shadowXl: [BoxShadow(color: Color(0x000B0D0C), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 0.0)],
  );

  static const dark = SureTokenPalette(
    surface: Color(0xFF0B0D0C),
    surfaceHover: Color(0xFF222522),
    surfaceInset: Color(0xFF222522),
    surfaceInsetHover: Color(0xFF222522),
    container: Color(0xFF121413),
    containerHover: Color(0xFF222522),
    containerInset: Color(0xFF222522),
    containerInsetHover: Color(0xFF333733),
    success: Color(0xFF6F88E2),
    warning: Color(0xFFFDB022),
    destructive: Color(0xFFED4E4E),
    destructiveSubtle: Color(0xFFA40E0E),
    info: Color(0xFF4A6BE0),
    link: Color(0xFF4A6BE0),
    shadow: Color(0x14FFFFFF),
    focusRing: Color(0x80FFFFFF),
    bgInverse: Color(0xFFFFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textInverse: Color(0xFF121413),
    textSecondary: Color(0xFFC2C5BD),
    textSubdued: Color(0xFF8A8F8A),
    borderPrimary: Color(0x4DFFFFFF),
    borderSecondary: Color(0x33FFFFFF),
    borderSubdued: Color(0x1AFFFFFF),
    buttonPrimary: Color(0xFFFFFFFF),
    buttonPrimaryHover: Color(0xFFF3F4EF),
    buttonDestructive: Color(0xFFED4E4E),
    buttonDestructiveHover: Color(0xFFF13636),
    shadowXs: [BoxShadow(color: Color(0x00FFFFFF), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 0.0)],
    shadowSm: [BoxShadow(color: Color(0x00FFFFFF), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 0.0)],
    shadowMd: [BoxShadow(color: Color(0x00FFFFFF), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 0.0)],
    shadowLg: [BoxShadow(color: Color(0x00FFFFFF), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 0.0)],
    shadowXl: [BoxShadow(color: Color(0x00FFFFFF), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 0.0)],
  );
}

class SureTokenPalette {
  const SureTokenPalette({
    required this.surface,
    required this.surfaceHover,
    required this.surfaceInset,
    required this.surfaceInsetHover,
    required this.container,
    required this.containerHover,
    required this.containerInset,
    required this.containerInsetHover,
    required this.success,
    required this.warning,
    required this.destructive,
    required this.destructiveSubtle,
    required this.info,
    required this.link,
    required this.shadow,
    required this.focusRing,
    required this.bgInverse,
    required this.textPrimary,
    required this.textInverse,
    required this.textSecondary,
    required this.textSubdued,
    required this.borderPrimary,
    required this.borderSecondary,
    required this.borderSubdued,
    required this.buttonPrimary,
    required this.buttonPrimaryHover,
    required this.buttonDestructive,
    required this.buttonDestructiveHover,
    required this.shadowXs,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.shadowXl,
  });

  final Color surface;
  final Color surfaceHover;
  final Color surfaceInset;
  final Color surfaceInsetHover;
  final Color container;
  final Color containerHover;
  final Color containerInset;
  final Color containerInsetHover;
  final Color success;
  final Color warning;
  final Color destructive;
  final Color destructiveSubtle;
  final Color info;
  final Color link;
  final Color shadow;
  final Color focusRing;
  final Color bgInverse;
  final Color textPrimary;
  final Color textInverse;
  final Color textSecondary;
  final Color textSubdued;
  final Color borderPrimary;
  final Color borderSecondary;
  final Color borderSubdued;
  final Color buttonPrimary;
  final Color buttonPrimaryHover;
  final Color buttonDestructive;
  final Color buttonDestructiveHover;
  final List<BoxShadow> shadowXs;
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;
  final List<BoxShadow> shadowXl;
}
