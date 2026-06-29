import 'package:flutter/material.dart';

/// Centralized spacing, sizing, and responsive breakpoints.
class AppDimensions {
  AppDimensions._();

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Spacing scale
  static const double spacingXxs = 4;
  static const double spacingXs = 8;
  static const double spacingSm = 12;
  static const double spacingMd = 16;
  static const double spacingLg = 20;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;
  static const double spacing3xl = 40;

  // Radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 22;
  static const double radius2xl = 28;
  static const double radiusPill = 999;

  // Icon sizes
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 28;

  // Component heights
  static const double buttonHeight = 48;
  static const double inputHeight = 52;
  static const double appBarHeight = 56;
  static const double bottomNavHeight = 56;
  static const double bottomNavIconSize = 22;
  static const double bottomNavLabelSize = 10;
  static const double homeSearchHeight = 48;
  static const double homeHeaderRowHeight = 44;
  static const double homeLocationIconSize = 20;
  static const double restaurantCardImageHeight = 160;

  // Content width
  static const double maxContentWidth = 1200;

  /// Returns horizontal page padding based on screen width.
  static double pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return spacing3xl;
    if (width >= tabletBreakpoint) return spacingXl;
    return spacingMd;
  }

  /// Grid column count for restaurant cards.
  static int restaurantGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return 4;
    if (width >= tabletBreakpoint) return 3;
    if (width >= mobileBreakpoint) return 2;
    return 1;
  }

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  /// Narrow phones where header/nav should use compact layout.
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 420;
}
