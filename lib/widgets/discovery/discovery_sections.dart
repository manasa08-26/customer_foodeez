import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/discovery_content.dart';
import '../../data/models/restaurant_model.dart';
import '../../core/utils/media_url_resolver.dart';

/// Horizontal category pills — same images as web discovery.
class DiscoveryCategoryRow extends StatelessWidget {
  const DiscoveryCategoryRow({
    super.key,
    required this.selectedQuery,
    required this.onCategoryTap,
  });

  final String selectedQuery;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padding),
        itemCount: DiscoveryContent.categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.spacingSm),
        itemBuilder: (_, i) {
          final cat = DiscoveryContent.categories[i];
          final selected = selectedQuery == cat.query;
          return _CategoryTile(
            category: cat,
            selected: selected,
            onTap: () => onCategoryTap(cat.query),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final DiscoveryCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: selected
                    ? Border.all(
                        color: category.gradientStart,
                        width: 2,
                      )
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: category.gradientStart.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  selected
                      ? AppDimensions.radiusMd - 2
                      : AppDimensions.radiusMd,
                ),
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => ColoredBox(
                    color: category.gradientStart.withValues(alpha: 0.2),
                  ),
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: category.gradientStart.withValues(alpha: 0.2),
                    child: const Icon(Icons.restaurant, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXxs),
            Text(
              category.label,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoverySectionTitle extends StatelessWidget {
  const DiscoverySectionTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding(context),
        AppDimensions.spacingMd,
        AppDimensions.pagePadding(context),
        AppDimensions.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: AppDimensions.spacingXxs),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class DiscoveryOffersRow extends StatelessWidget {
  const DiscoveryOffersRow({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padding),
        itemCount: DiscoveryContent.offers.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.spacingSm),
        itemBuilder: (_, i) {
          final offer = DiscoveryContent.offers[i];
          return Container(
            width: 200,
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: offer.gradient,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.tag,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                ),
                const Spacer(),
                Text(
                  '${offer.emoji} ${offer.title}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  offer.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DiscoveryMoodsRow extends StatelessWidget {
  const DiscoveryMoodsRow({super.key, required this.onMoodTap});

  final ValueChanged<String> onMoodTap;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padding),
        itemCount: DiscoveryContent.moods.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.spacingSm),
        itemBuilder: (_, i) {
          final mood = DiscoveryContent.moods[i];
          return InkWell(
            onTap: () => onMoodTap(mood.query),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: mood.gradient,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 22)),
                  const Spacer(),
                  Text(
                    mood.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    mood.description,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DiscoveryTrendingChips extends StatelessWidget {
  const DiscoveryTrendingChips({
    super.key,
    required this.onChipTap,
  });

  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(
        padding,
        AppDimensions.spacingSm,
        padding,
        0,
      ),
      child: Row(
        children: DiscoveryContent.trendingChips.map((chip) {
          final (label, query) = chip;
          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingXs),
            child: ActionChip(
              label: Text(label),
              onPressed: () => onChipTap(query),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Quick reorder row — mirrors web "Your Regulars".
class DiscoveryQuickReorderRow extends StatelessWidget {
  const DiscoveryQuickReorderRow({
    super.key,
    required this.restaurants,
    required this.onRestaurantTap,
    this.onHistoryTap,
  });

  final List<RestaurantModel> restaurants;
  final ValueChanged<RestaurantModel> onRestaurantTap;
  final VoidCallback? onHistoryTap;

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) return const SizedBox.shrink();
    final items = restaurants.take(6).toList();
    final padding = AppDimensions.pagePadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, AppDimensions.spacingLg, padding, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚡ Quick Reorder',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                    ),
                    Text(
                      'Your Regulars',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              if (onHistoryTap != null)
                TextButton(onPressed: onHistoryTap, child: const Text('History →')),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: padding),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppDimensions.spacingMd),
            itemBuilder: (_, i) {
              final r = items[i];
              return _QuickReorderTile(
                restaurant: r,
                index: i,
                onTap: () => onRestaurantTap(r),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickReorderTile extends StatelessWidget {
  const _QuickReorderTile({
    required this.restaurant,
    required this.index,
    required this.onTap,
  });

  final RestaurantModel restaurant;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(restaurant.imageUrl) ??
        CuisineFallbackImages.forCuisine(restaurant.cuisine, index);
    final accent = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 80,
                height: 80,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.restaurant, size: 28),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              restaurant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reorder',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal restaurant carousel — Late Night / Healthy sections.
class DiscoveryRestaurantCarousel extends StatelessWidget {
  const DiscoveryRestaurantCarousel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.restaurants,
    required this.onRestaurantTap,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final List<RestaurantModel> restaurants;
  final ValueChanged<RestaurantModel> onRestaurantTap;

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) return const SizedBox.shrink();
    final padding = AppDimensions.pagePadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, AppDimensions.spacingLg, padding, 0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: padding),
            itemCount: restaurants.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppDimensions.spacingSm),
            itemBuilder: (_, i) {
              final r = restaurants[i];
              return _HorizontalRestaurantTile(
                restaurant: r,
                index: i,
                onTap: () => onRestaurantTap(r),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact horizontal card — matches web MoodSection, no overflow.
class _HorizontalRestaurantTile extends StatelessWidget {
  const _HorizontalRestaurantTile({
    required this.restaurant,
    required this.index,
    required this.onTap,
  });

  final RestaurantModel restaurant;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(restaurant.imageUrl) ??
        CuisineFallbackImages.forCuisine(restaurant.cuisine, index);

    return SizedBox(
      width: 176,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Icon(Icons.restaurant),
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
                              Colors.black.withValues(alpha: 0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (restaurant.rating != null)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Text(
                          '★ ${restaurant.rating!.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (restaurant.deliveryTime != null)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Text(
                          '⏱ ${restaurant.deliveryTime}m',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (restaurant.cuisine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        restaurant.cuisine!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
