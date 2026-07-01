import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/cart_restaurant_cache.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/profile_model.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';

/// Cart / checkout — mirrors foodeez_frontend-dev /customer/cart.
class CartView extends ConsumerStatefulWidget {
  const CartView({super.key});

  @override
  ConsumerState<CartView> createState() => _CartViewState();
}

class _CartViewState extends ConsumerState<CartView> {
  final _couponCtrl = TextEditingController();
  String? _paymentMethod;
  String? _selectedAddressId;
  bool _placing = false;
  bool _noContact = false;
  String? _couponMsg;
  String? _error;
  String? _fallbackRestaurantName;
  String? _fallbackRestaurantLocation;

  final _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    Future.microtask(_init);
  }

  Future<void> _init() async {
    final cached = await CartRestaurantCache.read();
    if (cached != null && mounted) {
      setState(() {
        _fallbackRestaurantName = cached.name;
        _fallbackRestaurantLocation = cached.location;
      });
    }
    if (ref.read(authControllerProvider).value == true) {
      await Future.wait([
        ref.read(cartControllerProvider.notifier).fetchCart(),
        ref.read(profileControllerProvider.notifier).refresh(),
      ]);
    }
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(CartModel cart) async {
    if (_selectedAddressId == null) {
      setState(() => _error = 'Please select a delivery address.');
      return;
    }
    if (_paymentMethod == null || _paymentMethod!.isEmpty) {
      setState(
        () => _error =
            'Please select a payment method before placing your order.',
      );
      return;
    }
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final order = await ref.read(orderControllerProvider.notifier).placeOrder(
            addressId: _selectedAddressId!,
            paymentMethod: _paymentMethod!,
            instructions: _noContact
                ? 'Please leave the delivery at the door without contact.'
                : null,
          );
      if (!mounted) return;
      ref.read(cartControllerProvider.notifier).clearLocalCart();
      context.go(RoutePaths.orderById(order.id));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authed = ref.watch(authControllerProvider).value == true;
    if (!authed) {
      return EmptyStateView(
        title: 'Sign in to view your cart',
        subtitle: 'Browse restaurants and add items after signing in',
        icon: Icons.shopping_cart_outlined,
        actionLabel: 'Sign in',
        onAction: () => context.push(RoutePaths.login),
      );
    }

    final cartAsync = ref.watch(cartControllerProvider);
    final profileAsync = ref.watch(profileControllerProvider);
    final padding = AppDimensions.pagePadding(context);

    return cartAsync.when(
      loading: () => const LoadingView(message: 'Loading cart…'),
      error: (e, _) => ErrorStateView.fromError(
        e,
        onRetry: () => ref.read(cartControllerProvider.notifier).fetchCart(),
      ),
      data: (cart) {
        if (cart.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu_outlined,
                    size: 96,
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                          alpha: 0.35,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  FilledButton(
                    onPressed: () => context.go(RoutePaths.discovery),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingXl,
                        vertical: AppDimensions.spacingMd,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusXl),
                      ),
                    ),
                    child: const Text('Explore restaurants'),
                  ),
                ],
              ),
            ),
          );
        }

        final addresses = profileAsync.value?.addresses ?? [];
        _selectedAddressId ??= addresses
            .where((a) => a.isDefault)
            .map((a) => a.id)
            .firstOrNull ??
            addresses.firstOrNull?.id;

        final restaurantName =
            cart.restaurantName ?? _fallbackRestaurantName ?? 'Your Restaurant';
        final restaurantLocation =
            cart.restaurantLocation ?? _fallbackRestaurantLocation ?? '';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppDimensions.tabletBreakpoint;
            final panelHeight = isWide
                ? MediaQuery.sizeOf(context).height - 160
                : null;

            final leftColumn = SingleChildScrollView(
              child: _CheckoutLeftColumn(
                addresses: addresses,
                selectedAddressId: _selectedAddressId,
                paymentMethod: _paymentMethod,
                onAddressSelected: (id) =>
                    setState(() => _selectedAddressId = id),
                onPaymentSelected: (m) => setState(() => _paymentMethod = m),
                onAddAddress: () => context.go(RoutePaths.profile),
              ),
            );

            final orderSummary = _OrderSummaryPanel(
              cart: cart,
              restaurantName: restaurantName,
              restaurantLocation: restaurantLocation,
              currency: _currency,
              couponCtrl: _couponCtrl,
              couponMsg: _couponMsg,
              noContact: _noContact,
              placing: _placing,
              paymentMethod: _paymentMethod,
              error: _error,
              stretch: isWide,
              onNoContactChanged: (v) => setState(() => _noContact = v),
              onApplyCoupon: () async {
                if (_couponCtrl.text.trim().isEmpty) return;
                setState(() => _couponMsg = null);
                try {
                  await ref
                      .read(cartControllerProvider.notifier)
                      .applyCoupon(_couponCtrl.text);
                  setState(() => _couponMsg = 'Coupon applied!');
                } on ApiException catch (e) {
                  setState(() => _couponMsg = e.message);
                }
              },
              onRemoveCoupon: () async {
                await ref.read(cartControllerProvider.notifier).removeCoupon();
                _couponCtrl.clear();
                setState(() => _couponMsg = null);
              },
              onIncrement: (item) => ref
                  .read(cartControllerProvider.notifier)
                  .updateQuantity(item.id, item.quantity + 1),
              onDecrement: (item) {
                if (item.quantity <= 1) {
                  ref.read(cartControllerProvider.notifier).removeItem(item.id);
                } else {
                  ref
                      .read(cartControllerProvider.notifier)
                      .updateQuantity(item.id, item.quantity - 1);
                }
              },
              onPlaceOrder: () => _placeOrder(cart),
            );

            if (isWide && panelHeight != null) {
              return Padding(
                padding: EdgeInsets.all(padding),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppDimensions.maxContentWidth,
                    ),
                    child: SizedBox(
                      height: panelHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 6, child: leftColumn),
                          const SizedBox(width: AppDimensions.spacingLg),
                          Expanded(flex: 4, child: orderSummary),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      leftColumn,
                      const SizedBox(height: AppDimensions.spacingLg),
                      orderSummary,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CheckoutLeftColumn extends StatelessWidget {
  const _CheckoutLeftColumn({
    required this.addresses,
    required this.selectedAddressId,
    required this.paymentMethod,
    required this.onAddressSelected,
    required this.onPaymentSelected,
    required this.onAddAddress,
  });

  final List<AddressModel> addresses;
  final String? selectedAddressId;
  final String? paymentMethod;
  final ValueChanged<String> onAddressSelected;
  final ValueChanged<String> onPaymentSelected;
  final VoidCallback onAddAddress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a delivery address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                'Multiple addresses in this location',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              if (addresses.isEmpty)
                _EmptyAddressCard(onAdd: onAddAddress)
              else ...[
                ...addresses.map(
                  (addr) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.spacingMd,
                    ),
                    child: _AddressCard(
                      address: addr,
                      selected: selectedAddressId == addr.id,
                      onTap: () => onAddressSelected(addr.id),
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: onAddAddress,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingLg,
                    ),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor,
                      style: BorderStyle.solid,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                    ),
                  ),
                  child: const Text('Add New Address'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        _PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _PaymentOption(
                title: 'UPI Payment',
                subtitle: 'Pay using Google Pay, PhonePe, or BHIM',
                value: 'WALLET',
                groupValue: paymentMethod,
                onSelected: onPaymentSelected,
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              _PaymentOption(
                title: 'Cash on Delivery',
                subtitle: 'Pay when your order arrives at your door',
                value: 'COD',
                groupValue: paymentMethod,
                onSelected: onPaymentSelected,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryPanel extends StatelessWidget {
  const _OrderSummaryPanel({
    required this.cart,
    required this.restaurantName,
    required this.restaurantLocation,
    required this.currency,
    required this.couponCtrl,
    required this.noContact,
    required this.placing,
    required this.paymentMethod,
    required this.onNoContactChanged,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
    required this.onIncrement,
    required this.onDecrement,
    required this.onPlaceOrder,
    this.couponMsg,
    this.error,
    this.stretch = false,
  });

  final CartModel cart;
  final String restaurantName;
  final String restaurantLocation;
  final NumberFormat currency;
  final TextEditingController couponCtrl;
  final bool noContact;
  final bool placing;
  final String? paymentMethod;
  final String? couponMsg;
  final String? error;
  final bool stretch;
  final ValueChanged<bool> onNoContactChanged;
  final VoidCallback onApplyCoupon;
  final VoidCallback onRemoveCoupon;
  final void Function(CartItemModel item) onIncrement;
  final void Function(CartItemModel item) onDecrement;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR ORDER',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (restaurantLocation.isNotEmpty)
                      Text(
                        restaurantLocation,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingSm,
                  vertical: AppDimensions.spacingXs,
                ),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Text(
                  '${cart.items.length} item${cart.items.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final body = _buildOrderBody(context);
    final footer = Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: placing || paymentMethod == null ? null : onPlaceOrder,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radius2xl),
              ),
            ),
            child: Text(
              placing ? 'Placing order…' : 'Proceed to Pay',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
    );

    return _PanelCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (stretch)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingLg,
                ),
                child: body,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingLg,
              ),
              child: body,
            ),
          footer,
        ],
      ),
    );
  }

  Widget _buildOrderBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                if (cart.effectiveCouponDiscount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cart.couponCode != null
                              ? '${cart.couponCode} eligible items'
                              : 'Coupon savings',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: AppDimensions.spacingXxs),
                        Text(
                          'You just saved ${currency.format(cart.effectiveCouponDiscount)} on these items!',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                ],
                ...cart.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.spacingMd,
                    ),
                    child: _CartLineItem(
                      item: item,
                      currency: currency,
                      onIncrement: () => onIncrement(item),
                      onDecrement: () => onDecrement(item),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: Text(
                    'Any suggestions? We will pass it on...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                _NoContactTile(
                  value: noContact,
                  onChanged: onNoContactChanged,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                if (cart.couponCode != null)
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cart.couponCode!,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                'Offer applied on the bill',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: onRemoveCoupon,
                          child: const Text(
                            'REMOVE',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: couponCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Coupon code',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingSm),
                            FilledButton(
                              onPressed: onApplyCoupon,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('APPLY'),
                            ),
                          ],
                        ),
                        if (couponMsg != null) ...[
                          const SizedBox(height: AppDimensions.spacingSm),
                          Text(
                            couponMsg!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: AppDimensions.spacingMd),
                _BillBreakdown(cart: cart, currency: currency),
                const SizedBox(height: AppDimensions.spacingMd),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'TO PAY',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      Text(
                        currency.format(cart.grandTotal),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
        const SizedBox(height: AppDimensions.spacingLg),
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyAddressCard extends StatelessWidget {
  const _EmptyAddressCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingXl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Text('📍', style: TextStyle(fontSize: 28)),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            'No delivery address saved',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppDimensions.spacingXxs),
          Text(
            'Add an address to place your order',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('ADD NEW'),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primarySurface
          : Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : Theme.of(context).dividerColor,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.label,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppDimensions.spacingSm),
                        Text(
                          address.addressLine1,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          address.city,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingSm,
                      vertical: AppDimensions.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusPill),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      'DELIVER HERE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              Text(
                '51 MINS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final String value;
  final String? groupValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == value;
    return Material(
      color: selected
          ? AppColors.primarySurface
          : Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : Theme.of(context).dividerColor,
        ),
      ),
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppDimensions.spacingXxs),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: (_) => onSelected(value),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartLineItem extends StatelessWidget {
  const _CartLineItem({
    required this.item,
    required this.currency,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CartItemModel item;
  final NumberFormat currency;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text(
                      'Customize',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _QtyButton(label: '−', onTap: onDecrement),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${item.quantity}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  _QtyButton(label: '+', onTap: onIncrement),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Text(
                '${currency.format(item.unitPrice)} each',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                currency.format(item.lineTotal),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoContactTile extends StatelessWidget {
  const _NoContactTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: AppColors.primary,
        title: const Text('Opt in for No-contact Delivery'),
        subtitle: const Text(
          'Unwell, or avoiding contact? Please select no-contact delivery. '
          'Partner will safely place the order outside your door (not for COD)',
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
        ),
      ),
    );
  }
}

class _BillBreakdown extends StatelessWidget {
  const _BillBreakdown({required this.cart, required this.currency});

  final CartModel cart;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        children: [
          _BillRow(label: 'Item Total', value: currency.format(cart.subtotal)),
          _BillRow(
            label: 'Delivery Fee | ${cart.deliveryFee == 0 ? '0 km' : '2.6 kms'}',
            value: currency.format(cart.deliveryFee),
          ),
          _BillRow(
            label: 'Item Discount',
            value: '−${currency.format(cart.effectiveCouponDiscount)}',
            valueColor: Colors.green.shade700,
          ),
          _BillRow(
            label: 'GST & Other Charges',
            value: currency.format(cart.taxAmount),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
