import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/utils/media_url_resolver.dart';
import '../../data/models/menu_model.dart';
import 'veg_dot.dart';

/// Menu item row with image and − / + quantity stepper.
class MenuItemCard extends StatelessWidget {
  MenuItemCard({
    super.key,
    required this.item,
    required this.onAdd,
    this.quantity = 0,
    this.onIncrement,
    this.onDecrement,
    this.isUpdating = false,
  });

  final MenuItemModel item;
  final VoidCallback onAdd;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool isUpdating;

  final _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(item.imageUrl);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spacingSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VegDot(isVeg: item.resolvedIsVeg),
                    const SizedBox(width: AppDimensions.spacingXs),
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spacingXxs),
                  Text(
                    item.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  _currency.format(item.price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Column(
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(Icons.fastfood, color: scheme.primary),
                ),
              const SizedBox(height: AppDimensions.spacingXs),
              SizedBox(
                width: 88,
                height: 36,
                child: _QuantityStepper(
                  quantity: quantity,
                  isUpdating: isUpdating,
                  onDecrement: quantity > 0 ? onDecrement : null,
                  onIncrement: quantity > 0 ? onIncrement : onAdd,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.isUpdating,
    required this.onDecrement,
    required this.onIncrement,
    required this.color,
  });

  final int quantity;
  final bool isUpdating;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final minusColor =
        onDecrement != null ? color : color.withValues(alpha: 0.35);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        color: color.withValues(alpha: 0.08),
      ),
      child: isUpdating
          ? Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onDecrement,
                    child: Center(
                      child: Text(
                        '−',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: minusColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
                Text(
                  '$quantity',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: onIncrement,
                    child: Center(
                      child: Text(
                        '+',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
