import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';

/// Change logo display sizes here — used across the whole app.
abstract final class CustomerLogoSizes {
  static const double appBarHeight = 28;
  static const double appBarWidth = 124;
  static const double appBarCompactHeight = 24;
  static const double appBarCompactWidth = 92;
  static const double auth = 56;
  static const double authWidth = 180;
  static const double authCompact = 48;
  static const double authCompactWidth = 150;
  static const double splashIcon = 52;
  static const double splashIconBox = 88;
  static const double splashWordmarkHeight = 36;
  static const double splashWordmarkWidth = 200;
}

/// Theme-aware customer logo: [AppAssets.customerLight] in light mode,
/// [AppAssets.customerDark] in dark mode.
class CustomerLogo extends StatelessWidget {
  const CustomerLogo.appBar({super.key, this.asset, bool compact = false})
      : width = compact
            ? CustomerLogoSizes.appBarCompactWidth
            : CustomerLogoSizes.appBarWidth,
        height = compact
            ? CustomerLogoSizes.appBarCompactHeight
            : CustomerLogoSizes.appBarHeight,
        _variant = _LogoVariant.appBar;

  const CustomerLogo.auth({super.key, bool compact = false, this.asset})
      : width = compact
            ? CustomerLogoSizes.authCompactWidth
            : CustomerLogoSizes.authWidth,
        height =
            compact ? CustomerLogoSizes.authCompact : CustomerLogoSizes.auth,
        _variant = _LogoVariant.auth;

  const CustomerLogo.splashIcon({super.key, this.asset})
      : width = CustomerLogoSizes.splashIcon,
        height = CustomerLogoSizes.splashIcon,
        _variant = _LogoVariant.splashIcon;

  const CustomerLogo.splashWordmark({super.key, this.asset})
      : width = CustomerLogoSizes.splashWordmarkWidth,
        height = CustomerLogoSizes.splashWordmarkHeight,
        _variant = _LogoVariant.splashWordmark;

  const CustomerLogo.custom({
    super.key,
    required this.width,
    required this.height,
    this.asset,
  }) : _variant = _LogoVariant.custom;

  final double width;
  final double height;
  final String? asset;
  final _LogoVariant _variant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = asset ?? AppAssets.customerLogoFor(context);

    Widget image = Image.asset(
      logoAsset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.center,
    );

    // PNG logos include a white matte — blend it away on dark headers.
    if (isDark && _variant == _LogoVariant.appBar) {
      final headerBg = Theme.of(context).appBarTheme.backgroundColor ??
          Theme.of(context).colorScheme.surface;
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(headerBg, BlendMode.multiply),
        child: image,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: image,
    );
  }
}

enum _LogoVariant { appBar, auth, splashIcon, splashWordmark, custom }
