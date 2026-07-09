import 'package:flutter/material.dart';

/// Local asset paths.
class AppAssets {
  AppAssets._();

  // Brand logos — theme-aware (customer_light / customer_dark)
  static const String customerLight = 'assets/images/customer_light.png';
  static const String customerDark = 'assets/images/customer_dark.png';

  static String customerLogoFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? customerDark
        : customerLight;
  }

  // Discovery / marketing (non-logo)
  static const String heroVideo = 'assets/images/herosection.mp4';
  static const String biryani = 'assets/images/biriyanipng.png';

  static const List<String> homeBanners = [
    'assets/images/offer_40off.png',
    'assets/images/offer_bogo.png',
    'assets/images/offer_cashback.png',
    'assets/images/offer_free_delivery.png',
  ];

  // Social / auth
  static const String googleIcon = 'assets/icons/google.png';
}
