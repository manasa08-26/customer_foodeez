import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_dimensions.dart';
import '../../router/route_paths.dart';

/// Large tappable search bar — opens Search tab.
class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          onTap: () => context.go(RoutePaths.search),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: AppDimensions.spacingMd),
                Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                Expanded(
                  child: Text(
                    'Search restaurants & dishes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
