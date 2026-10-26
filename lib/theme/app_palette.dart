import 'package:flutter/material.dart';

/// Semantic color palette for Reweu Business Companion.
/// Supports both Obsidian Dark (Default) and Crisp Light themes with WCAG AA/AAA compliance.
class AppPalette {
  final Brightness brightness;
  final Color primary;
  final Color primaryVariant;
  final Color onPrimary;
  final Color brandText;

  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceElevated;

  final Color border;
  final Color borderSubtle;

  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  // Severity Colors
  final Color severityCritical;
  final Color severityHigh;
  final Color severityMedium;
  final Color severityLow;

  // Severity Background Containers
  final Color severityCriticalContainer;
  final Color severityHighContainer;
  final Color severityMediumContainer;
  final Color severityLowContainer;

  // Sentiment Colors (1 - 5 stars)
  final Color sentimentTerrible;
  final Color sentimentPoor;
  final Color sentimentAverage;
  final Color sentimentGood;
  final Color sentimentExcellent;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryVariant,
    required this.onPrimary,
    required this.brandText,
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceElevated,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.severityCritical,
    required this.severityHigh,
    required this.severityMedium,
    required this.severityLow,
    required this.severityCriticalContainer,
    required this.severityHighContainer,
    required this.severityMediumContainer,
    required this.severityLowContainer,
    required this.sentimentTerrible,
    required this.sentimentPoor,
    required this.sentimentAverage,
    required this.sentimentGood,
    required this.sentimentExcellent,
  });

  bool get isDark => brightness == Brightness.dark;

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFFFFA502), // Mustard
    primaryVariant: Color(0xFFFFB520),
    onPrimary: Color(0xFF0A0A0A), // Black passes 11.8:1 on mustard
    brandText: Color(0xFFFFB520),

    background: Color(0xFF0A0A0A), // Pure obsidian
    surface: Color(0xFF141414), // Primary card surface
    surfaceContainer: Color(0xFF1C1C1C), // Inputs, chips
    surfaceElevated: Color(0xFF222222), // Modals & sheets

    border: Color(0xFF262626),
    borderSubtle: Color(0xFF1E1E1E),

    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFFA1A1AA),
    textHint: Color(0xFF71717A),

    severityCritical: Color(0xFFF87171), // Red 400
    severityHigh: Color(0xFFFB923C), // Amber 400
    severityMedium: Color(0xFFFBBF24), // Yellow 400
    severityLow: Color(0xFF38BDF8), // Sky 400

    severityCriticalContainer: Color(0xFF450A0A),
    severityHighContainer: Color(0xFF451A03),
    severityMediumContainer: Color(0xFF332002),
    severityLowContainer: Color(0xFF082F49),

    sentimentTerrible: Color(0xFFF87171),
    sentimentPoor: Color(0xFFFB923C),
    sentimentAverage: Color(0xFFFBBF24),
    sentimentGood: Color(0xFF38BDF8),
    sentimentExcellent: Color(0xFF4ADE80),
  );

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFFFFA502),
    primaryVariant: Color(0xFFFFB520),
    onPrimary: Color(0xFF0A0A0A),
    brandText: Color(0xFF9A5C00), // 5.1:1 on white

    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF3F4F6),
    surfaceElevated: Color(0xFFFFFFFF),

    border: Color(0xFFE5E7EB),
    borderSubtle: Color(0xFFF1F5F9),

    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textHint: Color(0xFF9CA3AF),

    severityCritical: Color(0xFFDC2626), // Red 600
    severityHigh: Color(0xFFEA580C), // Orange 600
    severityMedium: Color(0xFFD97706), // Amber 600
    severityLow: Color(0xFF0284C7), // Sky 600

    severityCriticalContainer: Color(0xFFFEE2E2),
    severityHighContainer: Color(0xFFFFEDD5),
    severityMediumContainer: Color(0xFFFEF3C7),
    severityLowContainer: Color(0xFFE0F2FE),

    sentimentTerrible: Color(0xFFDC2626),
    sentimentPoor: Color(0xFFEA580C),
    sentimentAverage: Color(0xFFD97706),
    sentimentGood: Color(0xFF0284C7),
    sentimentExcellent: Color(0xFF16A34A),
  );

  Color colorForSeverity(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return severityCritical;
      case 'HIGH':
        return severityHigh;
      case 'MEDIUM':
        return severityMedium;
      case 'LOW':
      default:
        return severityLow;
    }
  }

  Color containerForSeverity(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return severityCriticalContainer;
      case 'HIGH':
        return severityHighContainer;
      case 'MEDIUM':
        return severityMediumContainer;
      case 'LOW':
      default:
        return severityLowContainer;
    }
  }

  Color colorForRating(double rating) {
    if (rating >= 4.5) return sentimentExcellent;
    if (rating >= 3.5) return sentimentGood;
    if (rating >= 2.5) return sentimentAverage;
    if (rating >= 1.5) return sentimentPoor;
    return sentimentTerrible;
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
}
