import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import 'customer_logo.dart';

/// Header brand — theme-aware customer logo (compact on narrow screens).
class BrandHeaderLogo extends StatelessWidget {
  const BrandHeaderLogo({
    super.key,
    this.compact = false,
    this.onTap,
  });

  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final logo = CustomerLogo.appBar(compact: compact);

    final child = onTap == null
        ? logo
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: logo,
          );

    return Align(
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
