import 'package:flutter/material.dart';

/// Brand palette — matches flutter_foodeez restaurant app.
class AppColors {
  AppColors._();

  // Primary purple palette
  static const Color primary = Color(0xFF6D3FC8);
  static const Color primaryLight = Color(0xFF9B7AE8);
  static const Color primaryDark = Color(0xFF45227E);
  static const Color primarySurface = Color(0xFFF2ECFF);

  // Accent
  static const Color accent = Color(0xFFB083F0);
  static const Color accentLight = Color(0xFFE9D8FD);

  /// Customer web parity — cart / wallet CTAs (foodeez_frontend-dev).
  static const Color customerAccent = Color(0xFFB88A2E);
  static const Color customerAccentSurface = Color(0xFFFEF5E6);
  static const Color customerAccentBorder = Color(0xFFF7D19A);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAF8FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFEAE5F4);

  // Auth screens use the same soft background as the rest of the app.
  static const Color authBackground = background;

  // Dark palette
  static const Color darkBackground = Color(0xFF0F0E12);
  static const Color darkSurface = Color(0xFF17161C);
  static const Color darkSurfaceElevated = Color(0xFF1F1E25);
  static const Color darkSurfaceHighlight = Color(0xFF29282F);
  static const Color darkCardBorder = Color(0xFF323138);
  static const Color darkDivider = Color(0xFF2A2932);
  static const Color darkTextPrimary = Color(0xFFF2F0F5);
  static const Color darkTextSecondary = Color(0xFFA8A3B3);
  static const Color darkTextHint = Color(0xFF6F6B78);
  static const Color darkPrimarySurface = Color(0xFF2B2340);
  static const Color darkSuccessSurface = Color(0xFF173225);
  static const Color darkWarningSurface = Color(0xFF3A2E18);
  static const Color darkErrorSurface = Color(0xFF3A1E22);
  static const Color darkInfoSurface = Color(0xFF1A2740);

  // Text
  static const Color textPrimary = Color(0xFF181125);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textHint = Color(0xFF9CA3AF);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSurface = Color(0xFFDBEAFE);

  // Veg / non-veg
  static const Color veg = Color(0xFF16A34A);
  static const Color nonVeg = Color(0xFFEF4444);

  // Order status
  static const Color statusPlaced = Color(0xFF3B82F6);
  static const Color statusAccepted = Color(0xFF8B5CF6);
  static const Color statusPreparing = Color(0xFFF59E0B);
  static const Color statusReady = Color(0xFF22C55E);
  static const Color statusOnTheWay = Color(0xFF06B6D4);
  static const Color statusDelivering = Color(0xFF06B6D4);
  static const Color statusDelivered = Color(0xFF22C55E);
  static const Color statusCancelled = Color(0xFFEF4444);

  // Divider & border
  static const Color divider = Color(0xFFEAE5F4);
  static const Color border = Color(0xFFE7E1F2);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C3FC5), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFB083F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF1A1528), Color(0xFF3D2A6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Theme-aware color accessors.
class AdaptiveAppColors {
  const AdaptiveAppColors._(this._isDark);

  final bool _isDark;

  factory AdaptiveAppColors.of(BuildContext context) =>
      AdaptiveAppColors._(Theme.of(context).brightness == Brightness.dark);

  bool get isDark => _isDark;

  Color get background =>
      _isDark ? AppColors.darkBackground : AppColors.background;

  Color get surface =>
      _isDark ? AppColors.darkSurfaceElevated : AppColors.white;

  Color get surfaceContainer =>
      _isDark ? AppColors.darkSurface : AppColors.surface;

  Color get surfaceHighlight =>
      _isDark ? AppColors.darkSurfaceHighlight : AppColors.background;

  Color get cardBorder =>
      _isDark ? AppColors.darkCardBorder : AppColors.cardBorder;

  Color get textPrimary =>
      _isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get textSecondary =>
      _isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get textHint => _isDark ? AppColors.darkTextHint : AppColors.textHint;

  Color get primarySurface =>
      _isDark ? AppColors.darkPrimarySurface : AppColors.primarySurface;

  Color get primaryColor =>
      _isDark ? AppColors.primaryLight : AppColors.primary;

  Color get successSurface =>
      _isDark ? AppColors.darkSuccessSurface : AppColors.successSurface;

  Color get errorSurface =>
      _isDark ? AppColors.darkErrorSurface : AppColors.errorSurface;

  Color get warningSurface =>
      _isDark ? AppColors.darkWarningSurface : AppColors.warningSurface;

  Color get infoSurface =>
      _isDark ? AppColors.darkInfoSurface : AppColors.infoSurface;

  Color get cardShadow => _isDark
      ? Colors.black.withValues(alpha: 0.42)
      : Colors.black.withValues(alpha: 0.035);

  LinearGradient get primaryGradient => AppColors.primaryGradient;

  LinearGradient get cardGradient =>
      _isDark ? AppColors.darkHeroGradient : AppColors.cardGradient;
}

extension AdaptiveAppColorsContext on BuildContext {
  AdaptiveAppColors get adaptive => AdaptiveAppColors.of(this);
}
