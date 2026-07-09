import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/reference_colors.dart';
import '../../data/models/order_model.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/shell_tab_header.dart';

/// Order history with All / Live / Past tabs.
class OrdersView extends ConsumerStatefulWidget {
  const OrdersView({super.key});

  @override
  ConsumerState<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends ConsumerState<OrdersView> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        ref.read(orderControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.value == true && next.value == false) {
        ref.read(orderControllerProvider.notifier).loadOrders();
      }
    });

    final state = ref.watch(orderControllerProvider);
    final padding = AppDimensions.pagePadding(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: ReferenceColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            const ShellTabHeader(title: 'Orders'),
            Padding(
              padding: EdgeInsets.all(padding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 380;
                  final filter = SegmentedButton<OrderFilter>(
                    segments: const [
                      ButtonSegment(value: OrderFilter.all, label: Text('All')),
                      ButtonSegment(value: OrderFilter.live, label: Text('Live')),
                      ButtonSegment(value: OrderFilter.past, label: Text('Past')),
                    ],
                    selected: {state.filter},
                    onSelectionChanged: (s) => ref
                        .read(orderControllerProvider.notifier)
                        .setFilter(s.first),
                  );

                  if (compact) {
                    return filter;
                  }

                  return Align(
                    alignment: Alignment.centerRight,
                    child: filter,
                  );
                },
              ),
            ),
            Expanded(child: _buildList(state, padding, currency)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(OrdersState state, double padding, NumberFormat currency) {
    if (state.isLoading) return const LoadingView();
    if (state.error != null && state.orders.isEmpty) {
      final needsLogin = state.error!.toLowerCase().contains('auth');
      return ErrorStateView(
        message: needsLogin
            ? 'Please sign in to view your orders'
            : state.error!,
        onRetry: needsLogin
            ? () => context.push(RoutePaths.login)
            : () => ref.read(orderControllerProvider.notifier).loadOrders(),
      );
    }

    final orders = state.filteredOrders;
    if (orders.isEmpty) {
      return const EmptyStateView(
        title: 'No orders yet',
        subtitle: 'Your order history will appear here',
        icon: Icons.receipt_long_outlined,
      );
    }

    return ListView.separated(
      controller: _scrollCtrl,
      padding: EdgeInsets.all(padding),
      itemCount: orders.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.spacingSm),
      itemBuilder: (_, i) {
        if (i >= orders.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return _OrderCard(
          order: orders[i],
          currency: currency,
          onTap: () => context.push(RoutePaths.orderById(orders[i].id)),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.currency,
    required this.onTap,
  });

  final OrderModel order;
  final NumberFormat currency;
  final VoidCallback onTap;

  Color _statusColor(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return AppColors.gold;
    }
    switch (order.status.toUpperCase()) {
      case 'DELIVERED':
        return AppColors.statusDelivered;
      case 'CANCELLED':
        return AppColors.statusCancelled;
      case 'ON_THE_WAY':
      case 'PICKED_UP':
        return AppColors.statusOnTheWay;
      case 'PREPARING':
        return AppColors.statusPreparing;
      default:
        return AppColors.statusPlaced;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.restaurantName ?? 'Order #${order.id}',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (order.createdAt != null)
                      Text(
                        timeago.format(order.createdAt!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingSm,
                        vertical: AppDimensions.spacingXxs,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(context).withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusPill),
                      ),
                      child: Text(
                        order.status.replaceAll('_', ' '),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _statusColor(context),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Text(
                  currency.format(order.grandTotal),
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
