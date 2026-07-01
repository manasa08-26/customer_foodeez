import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';

/// Official multicolor Google "G" logo.
class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.googleIcon,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
