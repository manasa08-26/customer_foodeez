import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Veg / non-veg indicator dot matching web UI.
class VegDot extends StatelessWidget {
  const VegDot({super.key, required this.isVeg});

  final bool? isVeg;

  @override
  Widget build(BuildContext context) {
    if (isVeg == null) return const SizedBox.shrink();
    final color = isVeg! ? AppColors.veg : AppColors.nonVeg;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 2.5),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
