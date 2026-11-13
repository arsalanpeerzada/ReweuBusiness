import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    const palette = AppPalette.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      scaffoldBackgroundColor: palette.background,
      primaryColor: palette.primary,
      colorScheme: ColorScheme.dark(
        primary: palette.primary,
        onPrimary: palette.onPrimary,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        error: palette.severityCritical,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          side: BorderSide(color: palette.border, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: palette.textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.primary,
        unselectedLabelColor: palette.textSecondary,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceElevated,
        modalBackgroundColor: palette.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLG)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: palette.textHint, fontSize: 14),
      ),
    );
  }

  static ThemeData get lightTheme {
    const palette = AppPalette.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: Brightness.light).textTheme,
      ),
      scaffoldBackgroundColor: palette.background,
      primaryColor: palette.primary,
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        onPrimary: palette.onPrimary,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        error: palette.severityCritical,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          side: BorderSide(color: palette.border, width: 0.5),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.04),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: palette.textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.brandText,
        unselectedLabelColor: palette.textSecondary,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceElevated,
        modalBackgroundColor: palette.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLG)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: palette.textHint, fontSize: 14),
      ),
    );
  }
}
