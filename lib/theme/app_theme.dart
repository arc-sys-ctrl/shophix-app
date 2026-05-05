import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sophix design tokens — dark luxury + cyan accent.
abstract final class SophixColors {
  static const Color background = Color(0xFF0A0E14);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceVariant = Color(0xFF1E2832);
  static const Color navBar = Color(0xFF0D1117);
  static const Color accent = Color(0xFF00D1FF);
  static const Color accentMuted = Color(0xFF003366);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
}

abstract final class SophixRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

ThemeData buildSophixTheme() {
  final baseDark = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.interTextTheme(baseDark.textTheme).copyWith(
    displayLarge: GoogleFonts.outfitTextTheme(baseDark.textTheme).displayLarge,
    headlineMedium: GoogleFonts.outfit(
      fontWeight: FontWeight.w800,
      color: Colors.white,
    ),
    titleLarge: GoogleFonts.outfit(
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  );

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SophixColors.background,
    primaryColor: SophixColors.accent,
    textTheme: textTheme,
    colorScheme: ColorScheme.dark(
      primary: SophixColors.accent,
      onPrimary: Colors.black,
      secondary: SophixColors.surfaceVariant,
      surface: SophixColors.background,
      onSurface: Colors.white,
      error: SophixColors.error,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: SophixColors.background,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.outfit(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: SophixColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SophixRadii.md),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: SophixColors.surface,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SophixRadii.sm)),
      elevation: 8,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: SophixColors.accent,
      linearTrackColor: SophixColors.surfaceVariant,
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.08)),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    splashFactory: InkSparkle.splashFactory,
    splashColor: SophixColors.accent.withValues(alpha: 0.12),
    highlightColor: SophixColors.accent.withValues(alpha: 0.08),
  );
}
