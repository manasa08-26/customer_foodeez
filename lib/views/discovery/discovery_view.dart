import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/discovery_controller.dart';
import '../../controllers/location_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/reference_colors.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/discovery/discovery_sections.dart';
import '../../widgets/home/home_restaurant_card.dart';

/// Home — UI aligned with Desktop `foodeez_customer_flutter` + live APIs.
class DiscoveryView extends ConsumerStatefulWidget {
  const DiscoveryView({super.key});

  @override
  ConsumerState<DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends ConsumerState<DiscoveryView> {
  final _refreshCtrl = RefreshController();
  final _scrollCtrl = ScrollController();
  int _activeBanner = 0;
  String _activeCatQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryControllerProvider);
    final location = ref.watch(deliveryLocationProvider);
    final restaurants = state.displayRestaurants;
    final authed = ref.watch(authControllerProvider).value == true;
    final profile = authed ? ref.watch(profileControllerProvider).value : null;
    final profileName = profile?.name?.isNotEmpty == true
        ? profile!.name!
        : (authed ? 'U' : 'G');

    if (state.error != null && state.restaurants.isEmpty && !state.isLoading) {
      return ErrorStateView(
        message: state.error!,
        onRetry: () =>
            ref.read(discoveryControllerProvider.notifier).loadInitial(),
      );
    }

    return Scaffold(
      backgroundColor: ReferenceColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _HomeHeader(
              locationLabel: location.label,
              avatarLetter: profileName.substring(0, 1).toUpperCase(),
              onLocationTap: () => context.push(RoutePaths.locationPicker),
              onNotifications: () => context.push(RoutePaths.notifications),
              onProfile: () => context.go(RoutePaths.profile),
            ),
            Expanded(
              child: SmartRefresher(
                controller: _refreshCtrl,
                onRefresh: _onRefresh,
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    _SearchBar(onTap: () => context.push(RoutePaths.search)),
                    _BannerCarousel(
                      active: _activeBanner,
                      onChanged: (i) => setState(() => _activeBanner = i),
                    ),
                    _BannerDots(
                      count: AppAssets.homeBanners.length,
                      active: _activeBanner,
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "What's on your mind?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    DiscoveryCategoryRow(
                      selectedQuery: _activeCatQuery.isEmpty
                          ? state.searchQuery
                          : _activeCatQuery,
                      onCategoryTap: (q) {
                        setState(() => _activeCatQuery = q);
                        _runSearch(q);
                      },
                    ),
                    _FilterChips(
                      vegOnly: state.vegOnly,
                      onVegToggle: () => ref
                          .read(discoveryControllerProvider.notifier)
                          .toggleVegOnly(),
                      onComingSoon: (label) => ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(content: Text('$label — coming soon')),
                      ),
                    ),
                    if (state.trending.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Trending near you',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.trending.length,
                          itemBuilder: (context, i) {
                            final r = state.trending[i];
                            return SizedBox(
                              width: 280,
                              child: HomeRestaurantCard(
                                restaurant: r,
                                index: i,
                                onTap: () => context.push(
                                  RoutePaths.restaurantDetail(r.branchId),
                                  extra: r.name,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            state.isLoading
                                ? 'Loading restaurants…'
                                : '${restaurants.length} restaurants near you',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                context.push(RoutePaths.allRestaurants),
                            child: Text(
                              'See all',
                              style: TextStyle(
                                color: ReferenceColors.gold(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.isLoading && restaurants.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (restaurants.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: EmptyStateView(
                          title: 'No restaurants found',
                          subtitle: 'Try another location or search',
                          icon: Icons.restaurant_outlined,
                        ),
                      )
                    else
                      ...restaurants.asMap().entries.map(
                        (e) => HomeRestaurantCard(
                          restaurant: e.value,
                          index: e.key,
                          onTap: () => context.push(
                            RoutePaths.restaurantDetail(e.value.branchId),
                            extra: e.value.name,
                          ),
                        ),
                      ),
                    if (state.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({
    required this.locationLabel,
    required this.avatarLetter,
    required this.onLocationTap,
    required this.onNotifications,
    required this.onProfile,
  });

  final String locationLabel;
  final String avatarLetter;
  final VoidCallback onLocationTap;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gold = ReferenceColors.gold(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? ReferenceColors.bg(context) : AppColors.white,
        border: Border(
          bottom: BorderSide(color: ReferenceColors.border(context), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onLocationTap,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ReferenceColors.card(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ReferenceColors.border(context)),
                    ),
                    child: Icon(Icons.location_on, size: 14, color: gold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivering to',
                          style: TextStyle(
                            fontSize: 11,
                            color: ReferenceColors.sub(context),
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ReferenceColors.text(context),
                                ),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, size: 14, color: gold),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // IconButton(
          //   tooltip: isDark ? 'Light mode' : 'Dark mode',
          //   onPressed: () {
          //     ref.read(themeModeProvider.notifier).setMode(
          //           isDark ? ThemeMode.light : ThemeMode.dark,
          //         );
          //   },
          //   icon: Container(
          //     padding: const EdgeInsets.all(8),
          //     decoration: BoxDecoration(
          //       color: ReferenceColors.card(context),
          //       borderRadius: BorderRadius.circular(12),
          //       border: Border.all(color: ReferenceColors.border(context)),
          //     ),
          //     child: Icon(
          //       isDark ? Icons.dark_mode : Icons.light_mode_outlined,
          //       size: 20,
          //       color: gold,
          //     ),
          //   ),
          // ),
         
          IconButton(
            onPressed: onNotifications,
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ReferenceColors.card(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ReferenceColors.border(context)),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 20,
                    color: ReferenceColors.text(context),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ReferenceColors.gold(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onProfile,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                avatarLetter,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: ReferenceColors.onGold(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ReferenceColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ReferenceColors.border(context)),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: ReferenceColors.sub(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search restaurants or dishes...',
                style: TextStyle(color: ReferenceColors.sub(context)),
              ),
            ),
            Icon(Icons.mic_none, size: 18, color: ReferenceColors.gold(context)),
          ],
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({
    required this.active,
    required this.onChanged,
  });

  final int active;
  final ValueChanged<int> onChanged;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = AppAssets.homeBanners;

    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _pageCtrl,
        itemCount: banners.length,
        onPageChanged: widget.onChanged,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(left: 16, right: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                banners[i],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BannerDots extends StatelessWidget {
  const _BannerDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? ReferenceColors.gold(context)
                : ReferenceColors.border(context),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.vegOnly,
    required this.onVegToggle,
    required this.onComingSoon,
  });

  final bool vegOnly;
  final VoidCallback onVegToggle;
  final void Function(String label) onComingSoon;

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('Relevance', false),
      ('Rating 4.0+', false),
      ('Fast Delivery', false),
      ('Offers', false),
      ('Pure Veg', true),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((f) {
          final (label, isVeg) = f;
          final selected = isVeg && vegOnly;
          return GestureDetector(
            onTap: () {
              if (isVeg) {
                onVegToggle();
              } else {
                onComingSoon(label);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? ReferenceColors.gold(context).withValues(alpha: 0.15)
                    : ReferenceColors.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? ReferenceColors.gold(context)
                      : ReferenceColors.border(context),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? ReferenceColors.gold(context)
                          : ReferenceColors.sub(context),
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 12,
                    color: ReferenceColors.sub(context),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
