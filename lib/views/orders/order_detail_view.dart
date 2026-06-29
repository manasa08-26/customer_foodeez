import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';

/// Single order detail with cancel, reorder, and review actions.
class OrderDetailView extends ConsumerStatefulWidget {
  const OrderDetailView({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends ConsumerState<OrderDetailView> {
  final _cancelReasonCtrl = TextEditingController();
  bool _showCancel = false;
  bool _cancelling = false;
  bool _reordering = false;

  @override
  void dispose() {
    _cancelReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final reason = _cancelReasonCtrl.text.trim();
    if (reason.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason (min 5 chars)')),
      );
      return;
    }
    setState(() => _cancelling = true);
    try {
      await ref
          .read(orderControllerProvider.notifier)
          .cancelOrder(widget.orderId, reason);
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) {
        setState(() => _showCancel = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _reorder() async {
    setState(() => _reordering = true);
    try {
      await ref.read(orderControllerProvider.notifier).reorder(widget.orderId);
      await ref.read(cartControllerProvider.notifier).fetchCart();
      if (!mounted) return;
      context.go(RoutePaths.cart);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final padding = AppDimensions.pagePadding(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return orderAsync.when(
      loading: () => const LoadingView(message: 'Loading order…'),
      error: (e, _) => ErrorStateView.fromError(
        e,
        onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
      ),
      data: (order) => SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppDimensions.maxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName ?? 'Order',
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Text('Status: ${order.status}'),
                      if (order.paymentMethod != null)
                        Text('Payment: ${order.paymentMethod}'),
                      if (order.deliveryAddress != null) ...[
                        const SizedBox(height: AppDimensions.spacingSm),
                        Text(
                          order.deliveryAddress!,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppDimensions.spacingSm),
              ...order.items.map(
                (item) => ListTile(
                  title: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${item.quantity} × ${currency.format(item.price)}',
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: Text(
                  currency.format(order.grandTotal),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              if (order.isDelivered) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: _reordering ? 'Adding…' : 'Reorder',
                        isLoading: _reordering,
                        onPressed: _reorder,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Expanded(
                      child: AppButton(
                        label: 'Rate order',
                        variant: AppButtonVariant.outline,
                        onPressed: () => context.push(
                          RoutePaths.reviewForOrder(widget.orderId),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (order.isCancellable && !_showCancel) ...[
                const SizedBox(height: AppDimensions.spacingSm),
                AppButton(
                  label: 'Cancel order',
                  variant: AppButtonVariant.outline,
                  onPressed: () => setState(() => _showCancel = true),
                ),
              ],
              if (_showCancel) ...[
                const SizedBox(height: AppDimensions.spacingMd),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(
                        alpha: 0.25,
                      ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Cancel order',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppDimensions.spacingSm),
                        TextField(
                          controller: _cancelReasonCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText:
                                'Reason for cancellation (min 5 characters)…',
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSm),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: _cancelling ? 'Cancelling…' : 'Confirm',
                                isLoading: _cancelling,
                                onPressed: _cancel,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingSm),
                            Expanded(
                              child: AppButton(
                                label: 'Go back',
                                variant: AppButtonVariant.outline,
                                onPressed: () =>
                                    setState(() => _showCancel = false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
