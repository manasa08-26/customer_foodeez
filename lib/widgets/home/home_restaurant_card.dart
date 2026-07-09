import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/discovery_content.dart';
import '../../core/theme/reference_colors.dart';
import '../../core/utils/media_url_resolver.dart';
import '../../data/models/restaurant_model.dart';

/// Vertical restaurant card — matches Desktop reference home list.
class HomeRestaurantCard extends StatelessWidget {
  const HomeRestaurantCard({
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
    final gold = ReferenceColors.gold(context);
    final imageUrl = resolveMediaUrl(restaurant.imageUrl) ??
        CuisineFallbackImages.forCuisine(restaurant.cuisine, index);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: ReferenceColors.card(context),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: ReferenceColors.border(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (restaurant.isVeg == true)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PURE VEG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ReferenceColors.onGold(context),
                        ),
                      ),
                    ),
                  ),
                if (restaurant.deliveryFee != null && restaurant.deliveryFee! == 0)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ReferenceColors.gold(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Free delivery',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ReferenceColors.onGold(context),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (restaurant.cuisine != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      restaurant.cuisine!,
                      style: TextStyle(
                        fontSize: 13,
                        color: ReferenceColors.sub(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (restaurant.rating != null) ...[
                        Icon(Icons.star, size: 14, color: gold),
                        Text(
                          ' ${restaurant.rating!.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (restaurant.deliveryTime != null) ...[
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: ReferenceColors.sub(context),
                        ),
                        Text(
                          ' ${restaurant.deliveryTime} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: ReferenceColors.sub(context),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (restaurant.deliveryFee != null)
                        Text(
                          'Min ₹${restaurant.deliveryFee!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: ReferenceColors.sub(context),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
