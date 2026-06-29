import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/restaurant_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/menu_item_card.dart';

/// Full-screen restaurant menu — no shell header, name in AppBar + back.
class RestaurantDetailView extends ConsumerStatefulWidget {
  const RestaurantDetailView({
    super.key,
    required this.branchId,
    this.initialName,
  });

  final String branchId;
  final String? initialName;

  @override
  ConsumerState<RestaurantDetailView> createState() =>
      _RestaurantDetailViewState();
}

class _RestaurantDetailViewState extends ConsumerState<RestaurantDetailView> {
  String? _addingItemId;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.discovery);
    }
  }

  Future<void> _addToCart(String menuItemId) async {
    setState(() => _addingItemId = menuItemId);
    final returnPath = RoutePaths.restaurantDetail(widget.branchId);
    final success = await ref.read(cartControllerProvider.notifier).addItem(
          menuItemId: menuItemId,
          branchId: widget.branchId,
          returnPath: returnPath,
        );
    if (!mounted) return;
    setState(() => _addingItemId = null);

    if (!success) {
      context.push(RoutePaths.login);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.go(RoutePaths.cart),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantControllerProvider(widget.branchId));
    final padding = AppDimensions.pagePadding(context);
    final title = state.restaurant?.name ??
        widget.initialName ??
        (state.isLoading ? 'Loading…' : 'Restaurant');

    if (state.isLoading && state.restaurant == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          title: Text(
            widget.initialName ?? 'Restaurant',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: const LoadingView(message: 'Loading menu…'),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          title: Text(
            widget.initialName ?? 'Restaurant',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: ErrorStateView(
          message: state.error!,
          onRetry: () => ref
              .read(restaurantControllerProvider(widget.branchId).notifier)
              .load(),
        ),
      );
    }

    final restaurant = state.restaurant;
    final categories = state.filteredCategories;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (restaurant?.rating != null)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spacingSm),
              child: Center(
                child: Chip(
                  avatar: const Icon(
                    Icons.star,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(restaurant!.rating!.toStringAsFixed(1)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              padding,
              AppDimensions.spacingSm,
              padding,
              AppDimensions.spacingSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search items in this restaurant…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (q) => ref
                      .read(
                        restaurantControllerProvider(widget.branchId).notifier,
                      )
                      .setSearch(q),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Wrap(
                  spacing: AppDimensions.spacingXs,
                  runSpacing: AppDimensions.spacingXs,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: state.vegFilter == VegFilter.all,
                      onTap: () => ref
                          .read(
                            restaurantControllerProvider(widget.branchId)
                                .notifier,
                          )
                          .setVegFilter(VegFilter.all),
                    ),
                    _FilterChip(
                      label: 'Veg',
                      selected: state.vegFilter == VegFilter.veg,
                      onTap: () => ref
                          .read(
                            restaurantControllerProvider(widget.branchId)
                                .notifier,
                          )
                          .setVegFilter(VegFilter.veg),
                    ),
                    _FilterChip(
                      label: 'Non-veg',
                      selected: state.vegFilter == VegFilter.nonVeg,
                      onTap: () => ref
                          .read(
                            restaurantControllerProvider(widget.branchId)
                                .notifier,
                          )
                          .setVegFilter(VegFilter.nonVeg),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: categories.isEmpty
                ? const EmptyStateView(
                    title: 'No items found',
                    subtitle: 'Try changing filters or search',
                    icon: Icons.fastfood_outlined,
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    itemCount: categories.length,
                    itemBuilder: (_, ci) {
                      final category = categories[ci];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.spacingSm,
                            ),
                            child: Text(
                              category.displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          ...category.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppDimensions.spacingSm,
                              ),
                              child: MenuItemCard(
                                item: item,
                                isAdding: _addingItemId == item.id,
                                onAdd: () => _addToCart(item.id),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _ViewCartBar(branchId: widget.branchId),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primarySurface,
    );
  }
}

class _ViewCartBar extends ConsumerWidget {
  const _ViewCartBar({required this.branchId});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartControllerProvider).value?.itemCount ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      color: AppColors.primaryLight,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () => context.go(RoutePaths.cart),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingXl,
              vertical: AppDimensions.spacingMd,
            ),
            child: Row(
              children: [
                Text(
                  '$count item${count == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                      ),
                ),
                const Spacer(),
                Text(
                  'View Cart',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                      ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
