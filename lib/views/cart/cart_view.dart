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
              padding: const EdgeInsets.symmetric(vertical: 16),
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
    final scheme = Theme.of(context).colorScheme;
    final adaptive = context.adaptive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                if (cart.effectiveCouponDiscount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      border: Border(
                        bottom: BorderSide(color: adaptive.cardBorder),
                      ),
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
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
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
                const SizedBox(height: AppDimensions.spacingMd),
                _NoContactTile(
                  value: noContact,
                  onChanged: onNoContactChanged,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                if (cart.couponCode != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.spacingMd,
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
                                'Coupon applied',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: onRemoveCoupon,
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.spacingMd,
                    ),
                    child: Row(
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
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                if (couponMsg != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.spacingMd,
                    ),
                    child: Text(
                      couponMsg!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
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
    return Padding(
      padding: padding ?? const EdgeInsets.all(AppDimensions.spacingLg),
      child: child,
    );
  }
}

class _EmptyAddressCard extends StatelessWidget {
  const _EmptyAddressCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingLg),
      child: Column(
        children: [
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
            child: const Text('Add address'),
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
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: scheme.primary,
              size: 22,
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppDimensions.spacingXxs),
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
          ],
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
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onSelected(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: scheme.primary,
              size: 22,
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: AppDimensions.spacingSm),
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
          Divider(height: 24, color: Theme.of(context).dividerColor),
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
    return InkWell(
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
    );
  }
}

class _NoContactTile extends StatelessWidget {
  const _NoContactTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      activeColor: Theme.of(context).colorScheme.primary,
      title: const Text('No-contact delivery'),
      subtitle: const Text('Leave order at the door'),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _BillBreakdown extends StatelessWidget {
  const _BillBreakdown({required this.cart, required this.currency});

  final CartModel cart;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BillRow(label: 'Item total', value: currency.format(cart.subtotal)),
        _BillRow(
          label: 'Delivery fee',
          value: currency.format(cart.deliveryFee),
        ),
        _BillRow(
          label: 'Discount',
          value: '−${currency.format(cart.effectiveCouponDiscount)}',
          valueColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gold
              : Colors.green.shade700,
        ),
        _BillRow(
          label: 'Taxes',
          value: currency.format(cart.taxAmount),
        ),
      ],
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
