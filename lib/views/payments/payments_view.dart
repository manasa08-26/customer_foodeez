import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/wallet_model.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/responsive_page.dart';

/// Wallet — mirrors foodeez_frontend-dev /customer/payments.
class PaymentsView extends ConsumerStatefulWidget {
  const PaymentsView({super.key});

  @override
  ConsumerState<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends ConsumerState<PaymentsView> {
  final _amountCtrl = TextEditingController();
  String _gateway = 'razorpay';
  bool _showTopup = false;
  bool _initiating = false;
  String? _topupMsg;

  static const _quickAmounts = [50, 100, 200, 500];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTopup() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount < 10) {
      setState(() => _topupMsg = 'Minimum top-up is ₹10.');
      return;
    }
    setState(() {
      _initiating = true;
      _topupMsg = null;
    });
    try {
      final id = await ref.read(walletControllerProvider.notifier).topUp(
            amount,
            gateway: _gateway,
          );
      if (!mounted) return;
      setState(() {
        _topupMsg =
            '✓ Top-up initiated (ID: ${id ?? 'pending'})';
        _amountCtrl.clear();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _topupMsg = e is ApiException
              ? e.message
              : 'Top-up failed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _initiating = false);
    }
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
              'Sign in to view your wallet.',
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
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

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
          
            const SizedBox(height: AppDimensions.spacingXxs),
            Text(
              'Your FooDeeZ balance & transactions',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            if (state.wallet != null)
              _BalanceCard(
                wallet: state.wallet!,
                onAddMoney: () => setState(() => _showTopup = true),
              ),
            const SizedBox(height: AppDimensions.spacingMd),
            _StatsRow(state: state, currency: currency),
            const SizedBox(height: AppDimensions.spacingLg),
            if (_showTopup) ...[
              _TopupPanel(
                amountCtrl: _amountCtrl,
                gateway: _gateway,
                quickAmounts: _quickAmounts,
                initiating: _initiating,
                topupMsg: _topupMsg,
                onClose: () => setState(() => _showTopup = false),
                onGatewayChanged: (g) => setState(() => _gateway = g),
                onQuickAmount: (amt) => setState(() => _amountCtrl.text = '$amt'),
                onSubmit: _handleTopup,
                onAmountChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
            ],
            Text(
              'TRANSACTION HISTORY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            if (state.transactions.isEmpty)
              _EmptyTransactions()
            else
              ..._groupedTransactions(state.transactions).entries.map(
                    (entry) => _TransactionDateGroup(
                      dateLabel: entry.key,
                      transactions: entry.value,
                      currency: currency,
                    ),
                  ),
            if (state.hasMore) ...[
              const SizedBox(height: AppDimensions.spacingMd),
              OutlinedButton(
                onPressed: state.isLoadingMore
                    ? null
                    : () => ref
                        .read(walletControllerProvider.notifier)
                        .loadMore(),
                child: Text(
                  state.isLoadingMore ? 'Loading…' : 'Load more',
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.spacingXl),
            Text(
              'SAVED PAYMENT METHODS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            const _SavedPaymentTile(
              icon: '🏦',
              label: 'UPI',
              subtitle: 'yourid@upi',
              tag: 'Primary',
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            const _SavedPaymentTile(
              icon: '💳',
              label: 'Card',
              subtitle: '**** **** **** 4242',
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<WalletTransactionModel>> _groupedTransactions(
    List<WalletTransactionModel> transactions,
  ) {
    final grouped = <String, List<WalletTransactionModel>>{};
    for (final tx in transactions) {
      final date = tx.createdAt?.toLocal();
      final key = date != null
          ? DateFormat('d MMM y').format(date)
          : 'Unknown date';
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.wallet,
    required this.onAddMoney,
  });

  final WalletModel wallet;
  final VoidCallback onAddMoney;

  @override
  Widget build(BuildContext context) {
    final monthYear = DateFormat('MMM y').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingXl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radius2xl),
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE BALANCE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            '₹${wallet.balance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppDimensions.spacingXxs),
          Text(
            '${wallet.currency} · FooDeeZ Wallet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              _BalanceActionButton(
                label: 'Add Money',
                icon: Icons.add,
                filled: true,
                onTap: onAddMoney,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              _BalanceActionButton(
                label: 'History',
                icon: Icons.history,
                onTap: () {},
              ),
              const Spacer(),
              Text(
                monthYear,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceActionButton extends StatelessWidget {
  const _BalanceActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? Colors.white
          : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: filled ? AppColors.primary : Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: filled ? AppColors.primary : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state, required this.currency});

  final WalletState state;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('💸', 'Total Spent', currency.format(state.totalSpent)),
      ('🔄', 'Transactions', '${state.transactions.length}'),
      ('💰', 'Cashbacks', currency.format(state.totalCashback)),
    ];

    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: s.$2 == 'Cashbacks' ? 0 : AppDimensions.spacingSm,
                ),
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    Text(s.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: AppDimensions.spacingXxs),
                    Text(
                      s.$3,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      s.$2,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TopupPanel extends StatelessWidget {
  const _TopupPanel({
    required this.amountCtrl,
    required this.gateway,
    required this.quickAmounts,
    required this.initiating,
    required this.onClose,
    required this.onGatewayChanged,
    required this.onQuickAmount,
    required this.onSubmit,
    required this.onAmountChanged,
    this.topupMsg,
  });

  final TextEditingController amountCtrl;
  final String gateway;
  final List<int> quickAmounts;
  final bool initiating;
  final String? topupMsg;
  final VoidCallback onClose;
  final ValueChanged<String> onGatewayChanged;
  final ValueChanged<int> onQuickAmount;
  final VoidCallback onSubmit;
  final VoidCallback onAmountChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radius2xl),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Add Money to Wallet',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
         Row(
  children: quickAmounts.map((amt) {
    final isSelected = amountCtrl.text == '$amt';

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          right: amt == quickAmounts.last ? 0 : 8,
        ),
        child: OutlinedButton(
          onPressed: () => onQuickAmount(amt),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48), // Same height
            // or fixedSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: isSelected
                ? AppColors.primarySurface
                : null,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).dividerColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹$amt',
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }).toList(),
),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'CUSTOM AMOUNT (₹)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => onAmountChanged(),
            decoration: const InputDecoration(hintText: 'Min ₹10'),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Expanded(
                child: _GatewayChip(
                  label: '⚡ Razorpay',
                  value: 'razorpay',
                  selected: gateway == 'razorpay',
                  onTap: () => onGatewayChanged('razorpay'),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: _GatewayChip(
                  label: '💳 Stripe',
                  value: 'stripe',
                  selected: gateway == 'stripe',
                  onTap: () => onGatewayChanged('stripe'),
                ),
              ),
            ],
          ),
          if (topupMsg != null) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              topupMsg!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: topupMsg!.startsWith('✓')
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacingMd),
          FilledButton(
            onPressed: initiating ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              initiating
                  ? 'Processing…'
                  : 'Add ₹${amountCtrl.text.isEmpty ? '—' : amountCtrl.text} via $gateway',
            ),
          ),
        ],
      ),
    );
  }
}

class _GatewayChip extends StatelessWidget {
  const _GatewayChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected ? AppColors.primarySurface : null,
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radius2xl),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const Text('💳', style: TextStyle(fontSize: 36)),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppDimensions.spacingXxs),
          Text(
            'Add money or place an order to get started',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TransactionDateGroup extends StatelessWidget {
  const _TransactionDateGroup({
    required this.dateLabel,
    required this.transactions,
    required this.currency,
  });

  final String dateLabel;
  final List<WalletTransactionModel> transactions;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                for (var i = 0; i < transactions.length; i++)
                  _TransactionRow(
                    tx: transactions[i],
                    currency: currency,
                    showDivider: i > 0,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.tx,
    required this.currency,
    this.showDivider = false,
  });

  final WalletTransactionModel tx;
  final NumberFormat currency;
  final bool showDivider;

  static const _cfg = {
    'CREDIT': (icon: '↓', color: Color(0xFF4ADE80), sign: '+'),
    'TOPUP': (icon: '↓', color: Color(0xFF4ADE80), sign: '+'),
    'REFUND_CREDIT': (icon: '↩', color: Color(0xFF60A5FA), sign: '+'),
    'CASHBACK_CREDIT': (icon: '↩', color: Color(0xFF60A5FA), sign: '+'),
    'REFERRAL_CREDIT': (icon: '↩', color: Color(0xFF60A5FA), sign: '+'),
    'DEBIT': (icon: '↑', color: Color(0xFFF87171), sign: '−'),
    'REFUND': (icon: '↩', color: Color(0xFF60A5FA), sign: '+'),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg[tx.type] ??
        (icon: '·', color: Theme.of(context).colorScheme.onSurface, sign: '');
    final time = tx.createdAt != null
        ? DateFormat('hh:mm a').format(tx.createdAt!.toLocal())
        : '';

    return Column(
      children: [
        if (showDivider) Divider(height: 1, color: Theme.of(context).dividerColor),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingSm,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cfg.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Text(
                  cfg.icon,
                  style: TextStyle(
                    color: cfg.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description ?? tx.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      [
                        if (time.isNotEmpty) time,
                        if (tx.status != null) tx.status,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '${cfg.sign}₹${tx.amount.abs().toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cfg.color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SavedPaymentTile extends StatelessWidget {
  const _SavedPaymentTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.tag,
  });

  final String icon;
  final String label;
  final String subtitle;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
              child: Text(
                tag!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
