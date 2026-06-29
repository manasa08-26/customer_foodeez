import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/support_controller.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/responsive_page.dart';

/// Support tickets — mirrors web /customer/support.
class SupportView extends ConsumerStatefulWidget {
  const SupportView({super.key});

  @override
  ConsumerState<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends ConsumerState<SupportView> {
  final _descCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();
  String _type = 'OTHER';
  String _priority = 'MEDIUM';
  bool _showForm = false;
  bool _submitting = false;

  static const _types = [
    ('MISSING_ITEM', 'Missing item'),
    ('WRONG_ORDER', 'Wrong order'),
    ('DELIVERY_ISSUE', 'Delivery issue'),
    ('PAYMENT_ISSUE', 'Payment issue'),
    ('REFUND_REQUEST', 'Refund request'),
    ('FOOD_QUALITY', 'Food quality'),
    ('OTHER', 'Other'),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description must be at least 10 characters')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(supportControllerProvider.notifier).createTicket(
            type: _type,
            description: _descCtrl.text.trim(),
            priority: _priority,
            orderId: _orderCtrl.text.trim().isEmpty
                ? null
                : _orderCtrl.text.trim(),
          );
      if (mounted) {
        setState(() {
          _showForm = false;
          _descCtrl.clear();
          _orderCtrl.clear();
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportControllerProvider);

    return ticketsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorStateView.fromError(
        e,
        onRetry: () => ref.read(supportControllerProvider.notifier).refresh(),
      ),
      data: (tickets) => ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close : Icons.add),
                  label: Text(_showForm ? 'Close' : 'New ticket'),
                ),
              ],
            ),
            if (_showForm) ...[
              const SizedBox(height: AppDimensions.spacingMd),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Issue type'),
                        items: _types
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.$1,
                                child: Text(t.$2),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                      const SizedBox(height: AppDimensions.spacingSm),
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: const [
                          DropdownMenuItem(value: 'LOW', child: Text('Low')),
                          DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                          DropdownMenuItem(value: 'HIGH', child: Text('High')),
                        ],
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                      const SizedBox(height: AppDimensions.spacingSm),
                      TextField(
                        controller: _orderCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Order ID (optional)',
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingSm),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe your issue…',
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      AppButton(
                        label: _submitting ? 'Submitting…' : 'Submit ticket',
                        isLoading: _submitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.spacingLg),
            if (tickets.isEmpty)
              const Text('No support tickets yet')
            else
              ...tickets.map(
                (t) => Card(
                  margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                  child: ListTile(
                    title: Text(
                      t.type.replaceAll('_', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      t.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Chip(
                      label: Text(
                        t.status,
                        style: const TextStyle(fontSize: 10),
                      ),
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
