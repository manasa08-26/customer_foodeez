import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/responsive_page.dart';

/// Wallet screen — mirrors foodeez_frontend-dev /customer/payments.
class PaymentsView extends ConsumerStatefulWidget {
  const PaymentsView({super.key});

  @override
  ConsumerState<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends ConsumerState<PaymentsView> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authed = ref.watch(authControllerProvider).value == true;

    if (!authed) {
      return ResponsivePage(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 48),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              'Sign in to view your wallet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            AppButton(
              label: 'Sign in',
              onPressed: () => context.push(RoutePaths.login),
            ),
          ],
        ),
      );
    }

    final walletAsync = ref.watch(walletControllerProvider);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return walletAsync.when(
      loading: () => const LoadingView(message: 'Loading wallet…'),
      error: (e, _) => ErrorStateView.fromError(
        e,
        onRetry: () => ref.read(walletControllerProvider.notifier).refresh(),
      ),
      data: (state) => ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available balance',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    currency.format(state.wallet?.balance ?? 0),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (state.wallet?.currency != null) ...[
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      '${state.wallet!.currency} · FooDeeZ Wallet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            Text('Add money', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppDimensions.spacingSm),
            Wrap(
              spacing: AppDimensions.spacingXs,
              runSpacing: AppDimensions.spacingXs,
              children: [50, 100, 200, 500].map((amt) {
                return ActionChip(
                  label: Text('₹$amt'),
                  onPressed: () => _amountCtrl.text = '$amt',
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter amount (min ₹10)',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            AppButton(
              label: 'Top up wallet',
              onPressed: () async {
                final amount = double.tryParse(_amountCtrl.text.trim());
                if (amount == null || amount < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Minimum top-up is ₹10')),
                  );
                  return;
                }
                await ref
                    .read(walletControllerProvider.notifier)
                    .topUp(amount);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Top-up initiated')),
                  );
                }
              },
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            Text(
              'Transaction history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            if (state.transactions.isEmpty)
              const Text('No transactions yet')
            else
              ...state.transactions.map(
                (tx) => Card(
                  child: ListTile(
                    title: Text(
                      tx.description ?? tx.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: tx.createdAt != null
                        ? Text(
                            tx.createdAt!.toLocal().toString().split('.').first,
                          )
                        : null,
                    trailing: Text(
                      currency.format(tx.amount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
