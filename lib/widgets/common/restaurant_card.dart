import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/discovery_content.dart';
import '../../core/utils/media_url_resolver.dart';
import '../../data/models/restaurant_model.dart';

/// Minimal restaurant tile — image, name, rating, time, cuisine, price hint.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.index = 0,
    this.compact = false,
  });

  static const double discoveryImageHeight = 120.0;
  static const double discoveryGridExtent = 188.0;
  static const double horizontalWidth = 168.0;

  final RestaurantModel restaurant;
  final VoidCallback onTap;
  final int index;
  final bool compact;

  String? get _priceHint {
    if (restaurant.deliveryFee != null && restaurant.deliveryFee! > 0) {
      return 'From ₹${restaurant.deliveryFee!.toStringAsFixed(0)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = context.adaptive;
    final resolved = resolveMediaUrl(restaurant.imageUrl);
    final imageUrl = resolved ??
        CuisineFallbackImages.forCuisine(restaurant.cuisine, index);

    if (compact) {
      return SizedBox(
        width: horizontalWidth,
        child: _RestaurantTile(
          imageUrl: imageUrl,
          adaptive: adaptive,
          restaurant: restaurant,
          priceHint: _priceHint,
          onTap: onTap,
        ),
      );
    }

    return _RestaurantTile(
      imageUrl: imageUrl,
      adaptive: adaptive,
      restaurant: restaurant,
      priceHint: _priceHint,
      onTap: onTap,
    );
  }
}

class _RestaurantTile extends StatelessWidget {
  const _RestaurantTile({
    required this.imageUrl,
    required this.adaptive,
    required this.restaurant,
    required this.priceHint,
    required this.onTap,
  });

  final String imageUrl;
  final AdaptiveAppColors adaptive;
  final RestaurantModel restaurant;
  final String? priceHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        ColoredBox(color: adaptive.primarySurface),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: adaptive.primarySurface,
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: adaptive.primaryColor,
                        size: 36,
                      ),
                    ),
                  ),
                  if (restaurant.rating != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _RatingBadge(rating: restaurant.rating!),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            restaurant.name,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (restaurant.deliveryTime != null)
                Text(
                  '${restaurant.deliveryTime} min',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              if (restaurant.cuisine != null) ...[
                if (restaurant.deliveryTime != null)
                  Text(
                    ' · ',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                Expanded(
                  child: Text(
                    restaurant.cuisine!,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (priceHint != null) ...[
            const SizedBox(height: 2),
            Text(
              priceHint!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 12,
            color: isDark ? AppColors.gold : AppColors.customerAccent,
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
