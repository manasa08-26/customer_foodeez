import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_dimensions.dart';
import '../common/restaurant_card.dart';

/// Shimmer placeholders while restaurants load.
class DiscoveryLoadingSkeleton extends StatelessWidget {
  const DiscoveryLoadingSkeleton({
    super.key,
    required this.columns,
    required this.padding,
  });

  final int columns;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: base.withValues(alpha: 0.55),
      highlightColor: highlight,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppDimensions.spacingMd,
            mainAxisSpacing: AppDimensions.spacingMd,
            mainAxisExtent: RestaurantCard.discoveryGridExtent,
          ),
          itemCount: columns * 2,
          itemBuilder: (_, __) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}
