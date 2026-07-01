import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../../controllers/discovery_controller.dart';
import '../../core/constants/app_dimensions.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/hero_video_banner.dart';
import '../../widgets/common/restaurant_card.dart';
import '../../widgets/discovery/discovery_loading_skeleton.dart';
import '../../widgets/discovery/discovery_sections.dart';

/// Home / discovery screen — mirrors web customer discovery.
class DiscoveryView extends ConsumerStatefulWidget {
  const DiscoveryView({super.key});

  @override
  ConsumerState<DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends ConsumerState<DiscoveryView> {
  final _refreshCtrl = RefreshController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(discoveryControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(discoveryControllerProvider.notifier).refresh();
    _refreshCtrl.refreshCompleted();
  }

  void _runSearch(String query) {
    ref.read(discoveryControllerProvider.notifier).search(query);
  }

  SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(int columns) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: AppDimensions.spacingMd,
      mainAxisSpacing: AppDimensions.spacingMd,
      mainAxisExtent: RestaurantCard.discoveryGridExtent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryControllerProvider);
    final padding = AppDimensions.pagePadding(context);
    final columns = AppDimensions.restaurantGridColumns(context);

    if (state.error != null && state.restaurants.isEmpty && !state.isLoading) {
      return ErrorStateView(
        message: state.error!,
        onRetry: () =>
            ref.read(discoveryControllerProvider.notifier).loadInitial(),
      );
    }

    final isInitialLoad = state.isLoading && state.restaurants.isEmpty;

    return SmartRefresher(
      controller: _refreshCtrl,
      onRefresh: _onRefresh,
      enablePullDown: true,
      child: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          const SliverToBoxAdapter(child: HeroVideoBanner()),
          SliverToBoxAdapter(
            child: DiscoveryTrendingChips(onChipTap: _runSearch),
          ),
          SliverToBoxAdapter(
            child: DiscoveryCategoryRow(
              selectedQuery: state.searchQuery,
              onCategoryTap: _runSearch,
            ),
          ),
          const SliverToBoxAdapter(
            child: DiscoverySectionTitle(
              title: "Today's Deals",
              subtitle: 'Exclusive offers for you',
            ),
          ),
          const SliverToBoxAdapter(child: DiscoveryOffersRow()),
          const SliverToBoxAdapter(
            child: DiscoverySectionTitle(
              title: 'Food Mood Cravings',
              subtitle: 'Pick a vibe, we find the food',
            ),
          ),
          SliverToBoxAdapter(
            child: DiscoveryMoodsRow(onMoodTap: _runSearch),
          ),
          SliverToBoxAdapter(
            child: DiscoverySectionTitle(
              title: 'Trending Near You',
              subtitle: state.searchQuery.isNotEmpty
                  ? 'Results for "${state.searchQuery}"'
                  : (isInitialLoad
                      ? 'Loading restaurants near you…'
                      : 'Popular restaurants around you'),
            ),
          ),
          if (isInitialLoad)
            SliverToBoxAdapter(
              child: DiscoveryLoadingSkeleton(
                columns: columns,
                padding: padding,
              ),
            )
          else if (state.restaurants.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                title: 'No restaurants found',
                subtitle: 'Try a different search or location',
                icon: Icons.restaurant_outlined,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                padding,
                0,
                padding,
                AppDimensions.spacingMd,
              ),
              sliver: SliverGrid(
                gridDelegate: _gridDelegate(columns),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= state.restaurants.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final restaurant = state.restaurants[index];
                    return RestaurantCard(
                      restaurant: restaurant,
                      index: index,
                      onTap: () => context.push(
                        RoutePaths.restaurantDetail(restaurant.branchId),
                        extra: restaurant.name,
                      ),
                    );
                  },
                  childCount: state.restaurants.length +
                      (state.isLoadingMore ? 1 : 0),
                ),
              ),
            ),
          if (state.restaurants.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: DiscoveryQuickReorderRow(
                restaurants: state.restaurants,
                onRestaurantTap: (r) => context.push(
                  RoutePaths.restaurantDetail(r.branchId),
                  extra: r.name,
                ),
                onHistoryTap: () => context.go(RoutePaths.orders),
              ),
            ),
            SliverToBoxAdapter(
              child: DiscoveryRestaurantCarousel(
                title: 'Late Night Cravings',
                subtitle: 'Perfect for midnight hunger pangs',
                emoji: '🌙',
                restaurants: state.restaurants.take(6).toList(),
                onRestaurantTap: (r) => context.push(
                  RoutePaths.restaurantDetail(r.branchId),
                  extra: r.name,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: DiscoveryRestaurantCarousel(
                title: 'Healthy & Fresh',
                subtitle: "Good food that's good for you",
                emoji: '🥗',
                restaurants: state.restaurants.reversed.take(6).toList(),
                onRestaurantTap: (r) => context.push(
                  RoutePaths.restaurantDetail(r.branchId),
                  extra: r.name,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingXl),
            ),
          ],
        ],
      ),
    );
  }
}
