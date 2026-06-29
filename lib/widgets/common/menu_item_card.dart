import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/media_url_resolver.dart';
import '../../data/models/menu_model.dart';
import 'veg_dot.dart';

/// Menu item card with add action.
class MenuItemCard extends StatelessWidget {
  MenuItemCard({
    super.key,
    required this.item,
    required this.onAdd,
    this.isAdding = false,
  });

  final MenuItemModel item;
  final VoidCallback onAdd;
  final bool isAdding;

  final _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(item.imageUrl);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingSm),
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
                          color: AppColors.primary,
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
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: const Icon(Icons.fastfood, color: AppColors.primary),
                  ),
                const SizedBox(height: AppDimensions.spacingXs),
                SizedBox(
                  width: 88,
                  height: 36,
                  child: OutlinedButton(
                    onPressed: isAdding ? null : onAdd,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                    ),
                    child: isAdding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('ADD'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
