import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_dimensions.dart';
import '../../data/models/restaurant_model.dart';
import '../../router/route_paths.dart';
import '../common/restaurant_card.dart';

/// Horizontal restaurant strip for Featured / Recommended sections.
class RestaurantHorizontalList extends StatelessWidget {
  const RestaurantHorizontalList({
    super.key,
    required this.restaurants,
    this.startIndex = 0,
  });

  final List<RestaurantModel> restaurants;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) return const SizedBox.shrink();
    final padding = AppDimensions.pagePadding(context);

    return SizedBox(
      height: RestaurantCard.discoveryGridExtent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padding),
        itemCount: restaurants.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.spacingMd),
        itemBuilder: (_, i) {
          final r = restaurants[i];
          return RestaurantCard(
            restaurant: r,
            index: startIndex + i,
            compact: true,
            onTap: () => context.push(
              RoutePaths.restaurantDetail(r.branchId),
              extra: r.name,
            ),
          );
        },
      ),
    );
  }
}

/// Nearby restaurants grid section wrapper.
class NearbyRestaurantsSection extends StatelessWidget {
  const NearbyRestaurantsSection({
    super.key,
    required this.restaurants,
    required this.columns,
    required this.isLoadingMore,
    required this.onRestaurantTap,
  });

  final List<RestaurantModel> restaurants;
  final int columns;
  final bool isLoadingMore;
  final void Function(RestaurantModel restaurant, int index) onRestaurantTap;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(padding, 0, padding, AppDimensions.spacingXl),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppDimensions.spacingMd,
          mainAxisSpacing: AppDimensions.spacingMd,
          mainAxisExtent: RestaurantCard.discoveryGridExtent,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= restaurants.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final restaurant = restaurants[index];
            return RestaurantCard(
              restaurant: restaurant,
              index: index,
              onTap: () => onRestaurantTap(restaurant, index),
            );
          },
          childCount: restaurants.length + (isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }
}
