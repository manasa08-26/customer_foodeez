import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// UI palette — light theme: white, grey, and brand purple (#692B7E).
class ReferenceColors {
  ReferenceColors._();

  static Color bg(BuildContext context) => AppColors.background;

  static Color card(BuildContext context) => AppColors.cardSurface;

  static Color border(BuildContext context) => AppColors.cardBorder;

  static Color text(BuildContext context) => AppColors.textPrimary;

  static Color sub(BuildContext context) => AppColors.textSecondary;

  /// Brand accent — maps to primary purple (no gold).
  static Color gold(BuildContext context) => AppColors.primary;

  /// Text/icons on purple backgrounds.
  static Color onGold(BuildContext context) => AppColors.white;
}
