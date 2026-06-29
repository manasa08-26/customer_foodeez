import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/cart_model.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/veg_dot.dart';

/// Cart and checkout screen.
class CartView extends ConsumerStatefulWidget {
  const CartView({super.key});

  @override
  ConsumerState<CartView> createState() => _CartViewState();
}

class _CartViewState extends ConsumerState<CartView> {
  final _couponCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  String? _paymentMethod;
  String? _selectedAddressId;
  bool _placing = false;
  bool _noContact = false;

  final _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(authControllerProvider).value == true) {
        ref.read(cartControllerProvider.notifier).fetchCart();
        ref.read(profileControllerProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(CartModel cart) async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }
    if (_paymentMethod == null || _paymentMethod!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method before placing your order'),
        ),
      );
      return;
    }
    setState(() => _placing = true);
    try {
      String? instructions;
      final note = _instructionsCtrl.text.trim();
      if (_noContact) {
        instructions =
            'Please leave the delivery at the door without contact.';
      } else if (note.isNotEmpty) {
        instructions = note;
      }
      if (_noContact && _paymentMethod == 'COD') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No-contact delivery is not available for COD'),
            ),
          );
          setState(() => _placing = false);
        }
        return;
      }
      final order = await ref.read(orderControllerProvider.notifier).placeOrder(
            addressId: _selectedAddressId!,
            paymentMethod: _paymentMethod!,
            instructions: instructions,
          );
      if (!mounted) return;
      await ref.read(cartControllerProvider.notifier).fetchCart();
      context.go(RoutePaths.orderById(order.id));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
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
          return EmptyStateView(
            title: 'Your cart is empty',
            subtitle: 'Add items from a restaurant menu',
            icon: Icons.shopping_cart_outlined,
            actionLabel: 'Browse restaurants',
            onAction: () => context.go(RoutePaths.discovery),
          );
        }

        final addresses = profileAsync.value?.addresses ?? [];
        _selectedAddressId ??= addresses
            .where((a) => a.isDefault)
            .map((a) => a.id)
            .firstOrNull ??
            addresses.firstOrNull?.id;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.spacingMd),
                ...cart.items.map((item) => _CartItemTile(
                      item: item,
                      currency: _currency,
                      onIncrement: () => ref
                          .read(cartControllerProvider.notifier)
                          .updateQuantity(item.id, item.quantity + 1),
                      onDecrement: () {
                        if (item.quantity <= 1) {
                          ref
                              .read(cartControllerProvider.notifier)
                              .removeItem(item.id);
                        } else {
                          ref
                              .read(cartControllerProvider.notifier)
                              .updateQuantity(item.id, item.quantity - 1);
                        }
                      },
                    )),
                const SizedBox(height: AppDimensions.spacingLg),
                _SectionTitle(title: 'Delivery address'),
                if (addresses.isEmpty)
                  Row(
                    children: [
                      const Expanded(
                        child: Text('No saved addresses yet.'),
                      ),
                      TextButton(
                        onPressed: () => context.push(RoutePaths.profile),
                        child: const Text('Add in Profile'),
                      ),
                    ],
                  )
                else
                  ...addresses.map(
                    (a) => RadioListTile<String>(
                      value: a.id,
                      groupValue: _selectedAddressId,
                      onChanged: (v) => setState(() => _selectedAddressId = v),
                      title: Text(a.label),
                      subtitle: Text(a.fullAddress),
                    ),
                  ),
                const SizedBox(height: AppDimensions.spacingMd),
                _SectionTitle(title: 'Payment method'),
                RadioListTile<String>(
                  value: 'WALLET',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v),
                  title: const Text('UPI Payment'),
                  subtitle: const Text(
                    'Pay using Google Pay, PhonePe, or BHIM',
                  ),
                ),
                RadioListTile<String>(
                  value: 'COD',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v),
                  title: const Text('Cash on Delivery'),
                  subtitle: const Text(
                    'Pay when your order arrives at your door',
                  ),
                ),
                CheckboxListTile(
                  value: _noContact,
                  onChanged: (v) => setState(() => _noContact = v ?? false),
                  title: const Text('No-contact delivery'),
                  subtitle: const Text(
                    'Partner will place the order outside your door (not for COD)',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                if (cart.couponCode != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Coupon: ${cart.couponCode}'),
                    trailing: TextButton(
                      onPressed: () async {
                        await ref
                            .read(cartControllerProvider.notifier)
                            .removeCoupon();
                        _couponCtrl.clear();
                      },
                      child: const Text('Remove'),
                    ),
                  ),
                ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Coupon code',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(cartControllerProvider.notifier)
                              .applyCoupon(_couponCtrl.text.trim());
                        } on ApiException catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                          }
                        }
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                TextField(
                  controller: _instructionsCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Special instructions (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _PriceRow(
                  label: 'Subtotal',
                  value: _currency.format(cart.subtotal),
                ),
                _PriceRow(
                  label: 'Delivery fee',
                  value: _currency.format(cart.deliveryFee),
                ),
                _PriceRow(
                  label: 'Tax',
                  value: _currency.format(cart.taxAmount),
                ),
                if (cart.discountAmount > 0)
                  _PriceRow(
                    label: 'Discount',
                    value: '-${_currency.format(cart.discountAmount)}',
                  ),
                const Divider(),
                _PriceRow(
                  label: 'Grand total',
                  value: _currency.format(cart.grandTotal),
                  bold: true,
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                AppButton(
                  label: _placing ? 'Placing order…' : 'Place order',
                  isLoading: _placing,
                  onPressed: () => _placeOrder(cart),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.currency,
    required this.onIncrement,
    required this.onDecrement,
  });

  final dynamic item;
  final NumberFormat currency;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSm,
          vertical: AppDimensions.spacingXs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VegDot(isVeg: item.isVeg),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currency.format(item.lineTotal),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: onDecrement,
                  visualDensity: VisualDensity.compact,
                ),
                Text('${item.quantity}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: onIncrement,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}
