import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Centralized typography — responsive via Theme text scale.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle displayLarge(Color color) => _base(
        size: 32,
        weight: FontWeight.w900,
        color: color,
        letterSpacing: -1.0,
        height: 1.08,
      );

  static TextStyle displayMedium(Color color) => _base(
        size: 28,
        weight: FontWeight.w900,
        color: color,
        letterSpacing: -0.8,
        height: 1.1,
      );

  static TextStyle headlineLarge(Color color) => _base(
        size: 24,
        weight: FontWeight.w900,
        color: color,
        letterSpacing: -0.6,
        height: 1.12,
      );

  static TextStyle headlineMedium(Color color) => _base(
        size: 21,
        weight: FontWeight.w900,
        color: color,
        letterSpacing: -0.45,
        height: 1.15,
      );

  static TextStyle headlineSmall(Color color) => _base(
        size: 18,
        weight: FontWeight.w900,
        color: color,
        letterSpacing: -0.35,
        height: 1.18,
      );

  static TextStyle titleLarge(Color color) => _base(
        size: 17,
        weight: FontWeight.w900,
        color: color,
        letterSpacing: -0.35,
        height: 1.2,
      );

  static TextStyle titleMedium(Color color) => _base(
        size: 15,
        weight: FontWeight.w800,
        color: color,
        letterSpacing: -0.2,
        height: 1.25,
      );

  static TextStyle titleSmall(Color color) => _base(
        size: 13,
        weight: FontWeight.w800,
        color: color,
        letterSpacing: -0.1,
        height: 1.22,
      );

  static TextStyle bodyLarge(Color color) => _base(
        size: 15,
        weight: FontWeight.w500,
        color: color,
        height: 1.35,
      );

  static TextStyle bodyMedium(Color color) => _base(
        size: 14,
        weight: FontWeight.w500,
        color: color,
        height: 1.35,
      );

  static TextStyle bodySmall(Color color) => _base(
        size: 12,
        weight: FontWeight.w500,
        color: color,
        height: 1.3,
      );

  static TextStyle labelLarge(Color color) => _base(
        size: 13.5,
        weight: FontWeight.w800,
        color: color,
        letterSpacing: -0.1,
      );

  static TextStyle labelMedium(Color color) => _base(
        size: 12,
        weight: FontWeight.w700,
        color: color,
      );

  static TextStyle labelSmall(Color color) => _base(
        size: 10.5,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: 0.1,
      );

  /// Builds a full TextTheme for the given brightness.
  static TextTheme textTheme(Brightness brightness) {
    final onSurface = brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final onSurfaceVariant = brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return TextTheme(
      displayLarge: displayLarge(onSurface),
      displayMedium: displayMedium(onSurface),
      headlineLarge: headlineLarge(onSurface),
      headlineMedium: headlineMedium(onSurface),
      headlineSmall: headlineSmall(onSurface),
      titleLarge: titleLarge(onSurface),
      titleMedium: titleMedium(onSurface),
      titleSmall: titleSmall(onSurface),
      bodyLarge: bodyLarge(onSurface),
      bodyMedium: bodyMedium(onSurface),
      bodySmall: bodySmall(onSurfaceVariant),
      labelLarge: labelLarge(AppColors.white),
      labelMedium: labelMedium(onSurfaceVariant),
      labelSmall: labelSmall(
        brightness == Brightness.dark
            ? AppColors.darkTextHint
            : AppColors.textHint,
      ),
    );
  }
}
