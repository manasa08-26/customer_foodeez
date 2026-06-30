import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/discovery_content.dart';
import '../../core/utils/media_url_resolver.dart';
import '../../data/models/restaurant_model.dart';

/// Restaurant card for discovery grid — web-style with cuisine fallbacks.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.index = 0,
  });

  final RestaurantModel restaurant;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(restaurant.imageUrl);
    final imageUrl = resolved ??
        CuisineFallbackImages.forCuisine(restaurant.cuisine, index);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.primarySurface,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.primarySurface,
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (restaurant.rating != null)
                    Positioned(
                      top: AppDimensions.spacingXs,
                      right: AppDimensions.spacingXs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingXs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusPill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              restaurant.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingSm,
                AppDimensions.spacingXs,
                AppDimensions.spacingSm,
                AppDimensions.spacingSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (restaurant.cuisine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      restaurant.cuisine!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (restaurant.deliveryTime != null ||
                      restaurant.deliveryFee != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (restaurant.deliveryTime != null)
                          Flexible(
                            child: Text(
                              '${restaurant.deliveryTime} min',
                              style: Theme.of(context).textTheme.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (restaurant.deliveryFee != null) ...[
                          const SizedBox(width: AppDimensions.spacingXs),
                          Flexible(
                            child: Text(
                              '₹${restaurant.deliveryFee!.toStringAsFixed(0)} delivery',
                              style: Theme.of(context).textTheme.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
