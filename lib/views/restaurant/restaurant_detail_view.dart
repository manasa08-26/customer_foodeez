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
import '../../data/models/cart_model.dart';
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
  String? _updatingItemId;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.discovery);
    }
  }

  Future<void> _addToCart(String menuItemId) async {
    setState(() => _updatingItemId = menuItemId);
    final returnPath = RoutePaths.restaurantDetail(widget.branchId);
    final success = await ref.read(cartControllerProvider.notifier).addItem(
          menuItemId: menuItemId,
          branchId: widget.branchId,
          returnPath: returnPath,
        );
    if (!mounted) return;
    setState(() => _updatingItemId = null);

    if (!success) {
      context.push(RoutePaths.login);
      return;
    }

    _showAddedSnackBar();
  }

  Future<void> _incrementCartItem(String menuItemId) async {
    final cartItem = _cartItemForMenu(menuItemId);
    if (cartItem == null) {
      await _addToCart(menuItemId);
      return;
    }

    setState(() => _updatingItemId = menuItemId);
    await ref.read(cartControllerProvider.notifier).updateQuantity(
          cartItem.id,
          cartItem.quantity + 1,
        );
    if (mounted) setState(() => _updatingItemId = null);
  }

  Future<void> _decrementCartItem(String menuItemId) async {
    final cartItem = _cartItemForMenu(menuItemId);
    if (cartItem == null) return;

    setState(() => _updatingItemId = menuItemId);
    final notifier = ref.read(cartControllerProvider.notifier);
    if (cartItem.quantity <= 1) {
      await notifier.removeItem(cartItem.id);
    } else {
      await notifier.updateQuantity(cartItem.id, cartItem.quantity - 1);
    }
    if (mounted) setState(() => _updatingItemId = null);
  }

  CartItemModel? _cartItemForMenu(String menuItemId) {
    final items = ref.read(cartControllerProvider).value?.items ?? [];
    for (final item in items) {
      if (item.menuItemId == menuItemId) return item;
    }
    return null;
  }

  int _quantityForMenu(String menuItemId) {
    return _cartItemForMenu(menuItemId)?.quantity ?? 0;
  }

  void _showAddedSnackBar() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: const Text(
          'Added to cart',
          style: TextStyle(color: AppColors.white),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(cartControllerProvider.notifier).fetchCart(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(cartControllerProvider);
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
                  avatar: Icon(
                    Icons.star,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
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
                      indicatorColor: AppColors.veg,
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
                      indicatorColor: AppColors.nonVeg,
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
                                quantity: _quantityForMenu(item.id),
                                isUpdating: _updatingItemId == item.id,
                                onAdd: () => _addToCart(item.id),
                                onIncrement: () => _incrementCartItem(item.id),
                                onDecrement: () => _decrementCartItem(item.id),
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
    this.indicatorColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? indicatorColor;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (indicatorColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
                border: Border.all(color: indicatorColor!, width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
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
    final barColor = Theme.of(context).colorScheme.primary;
    final onBarColor = AppColors.white;

    return Material(
      color: barColor,
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
                        color: onBarColor,
                      ),
                ),
                const Spacer(),
                Text(
                  'View Cart',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onBarColor,
                      ),
                ),
                Icon(Icons.chevron_right, color: onBarColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
