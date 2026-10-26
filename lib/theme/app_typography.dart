import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';

/// Typography configuration adhering to Option A:
/// - Headlines, quantitative KPIs, and Incident IDs: Outfit
/// - Body text, customer reviews, operational notes: Plus Jakarta Sans
/// - Fallback for Urdu text: Noto Nastaliq Urdu
class AppTypography {
  AppTypography._();

  static const String headlineFont = 'Outfit';
  static const String bodyFont = 'Plus Jakarta Sans';
  static const String urduFont = 'Noto Nastaliq Urdu';

  static TextStyle h1(BuildContext context) => GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: context.palette.textPrimary,
        height: 1.25,
      );

  static TextStyle h2(BuildContext context) => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: context.palette.textPrimary,
        height: 1.3,
      );

  static TextStyle h3(BuildContext context) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.palette.textPrimary,
        height: 1.35,
      );

  static TextStyle incidentCode(BuildContext context) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: context.palette.textPrimary,
      );

  static TextStyle metricValue(BuildContext context) => GoogleFonts.outfit(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: context.palette.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: context.palette.textPrimary,
        height: 1.5,
      );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: context.palette.textPrimary,
        height: 1.45,
      );

  static TextStyle body(BuildContext context) => bodyMedium(context);

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: context.palette.textSecondary,
        height: 1.4,
      );

  static TextStyle caption(BuildContext context) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: context.palette.textHint,
        letterSpacing: 0.4,
      );

  static TextStyle button(BuildContext context) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  /// Formats review content with proper font family and text direction.
  static TextStyle reviewContent(BuildContext context, {bool isUrdu = false}) {
    if (isUrdu) {
      return GoogleFonts.notoNastaliqUrdu(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: context.palette.textPrimary,
        height: 1.8,
      );
    }
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: context.palette.textPrimary,
      height: 1.55,
    );
  }
}

extension TypographyContext on BuildContext {
  AppTypography get typography => AppTypography._();
}
