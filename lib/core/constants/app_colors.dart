import 'package:flutter/material.dart';

/// Brand palette — light theme only: white + #692B7E purple.
class AppColors {
  AppColors._();

  /// Brand purple — FooDeeZ customer theme.
  static const Color primary = Color(0xFF692B7E);
  static const Color primaryLight = Color(0xFF8E4FA3);
  static const Color primaryDark = Color(0xFF4E2060);
  static const Color primarySurface = Color(0xFFF4ECF7);

  // Accent (same family)
  static const Color accent = Color(0xFF7D3A96);
  static const Color accentLight = Color(0xFFE8D4EF);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE8DCEC);

  static const Color authBackground = background;

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFF9E9E9E);

  // Text on purple surfaces
  static const Color onPrimary = white;

  // Status (muted greys + purple where needed)
  static const Color success = Color(0xFF2E7D32);
  static const Color successSurface = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFF6B6B6B);
  static const Color warningSurface = Color(0xFFF5F5F5);
  static const Color error = Color(0xFF692B7E);
  static const Color errorSurface = Color(0xFFF4ECF7);
  static const Color info = Color(0xFF692B7E);
  static const Color infoSurface = Color(0xFFF4ECF7);

  // Veg / non-veg — standard green / red indicators
  static const Color veg = Color(0xFF2E7D32);
  static const Color nonVeg = Color(0xFFC62828);

  // Order status
  static const Color statusPlaced = Color(0xFF692B7E);
  static const Color statusAccepted = Color(0xFF8E4FA3);
  static const Color statusPreparing = Color(0xFF6B6B6B);
  static const Color statusReady = Color(0xFF4A4A4A);
  static const Color statusOnTheWay = Color(0xFF692B7E);
  static const Color statusDelivering = Color(0xFF692B7E);
  static const Color statusDelivered = Color(0xFF4A4A4A);
  static const Color statusCancelled = Color(0xFF1A1A1A);

  // Divider & border
  static const Color divider = Color(0xFFE8DCEC);
  static const Color border = Color(0xFFE8DCEC);

  // Gradients — purple only
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF692B7E), Color(0xFF8E4FA3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF692B7E), Color(0xFF7D3A96)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy aliases — light theme only; map old dark/gold tokens to brand purple.
  static const Color gold = primary;
  static const Color darkBackground = black;
  static const Color darkSurfaceElevated = surface;
  static const Color darkSurfaceHighlight = background;
  static const Color darkCardBorder = cardBorder;
  static const Color darkDivider = divider;
  static const Color darkPrimarySurface = primarySurface;
  static const Color darkTextPrimary = white;
  static const Color darkTextSecondary = textSecondary;
  static const Color darkTextHint = textHint;
  static const Color customerAccent = primary;
  static const LinearGradient darkGoldGradient = primaryGradient;

  static LinearGradient headerGradientFor(bool isDark) => primaryGradient;

  /// Legacy call sites use `AppColors.headerGradient(isDark)`.
  static LinearGradient headerGradient(bool isDark) => primaryGradient;
}

/// Theme-aware color accessors — light theme only.
class AdaptiveAppColors {
  const AdaptiveAppColors._();

  factory AdaptiveAppColors.of(BuildContext context) =>
      const AdaptiveAppColors._();

  bool get isDark => false;

  Color get background => AppColors.background;
  Color get surface => AppColors.white;
  Color get surfaceContainer => AppColors.surface;
  Color get surfaceHighlight => AppColors.background;
  Color get cardBorder => AppColors.cardBorder;
  Color get textPrimary => AppColors.textPrimary;
  Color get textSecondary => AppColors.textSecondary;
  Color get textHint => AppColors.textHint;
  Color get errorText => AppColors.error;
  Color get linkText => AppColors.primary;
  Color get primaryColor => AppColors.primary;
  Color get onPrimaryColor => AppColors.white;
  Color get primarySurface => AppColors.primarySurface;
  Color get successSurface => AppColors.successSurface;
  Color get errorSurface => AppColors.errorSurface;
  Color get warningSurface => AppColors.warningSurface;
  Color get infoSurface => AppColors.infoSurface;
  Color get cardShadow => Colors.black.withValues(alpha: 0.035);
  LinearGradient get primaryGradient => AppColors.primaryGradient;
  LinearGradient get headerGradient => AppColors.primaryGradient;
  LinearGradient get cardGradient => AppColors.cardGradient;
}

extension AdaptiveAppColorsContext on BuildContext {
  AdaptiveAppColors get adaptive => AdaptiveAppColors.of(this);
}
