import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/theme/reference_colors.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/shell_tab_header.dart';

/// Dine-in hub — matches Desktop reference; sub-routes are coming soon.
class DineInView extends StatelessWidget {
  const DineInView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReferenceColors.bg(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
          children: [
            const ShellTabHeader(
              title: 'Dine In',
              subtitle: 'Book a table at your favourite restaurant',
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingMd,
              ),
              child: Column(
                children: [
                  _DineInCard(
                    title: 'Select Table',
                    subtitle: 'Choose your preferred table',
                    icon: Icons.table_restaurant_rounded,
                    onTap: () => context.push(RoutePaths.selectTable),
                  ),
                  _DineInCard(
                    title: 'Booking History',
                    subtitle: 'View past dine-in bookings',
                    icon: Icons.history_rounded,
                    onTap: () => context.push(RoutePaths.bookingHistory),
                  ),
                  _DineInCard(
                    title: 'Nearby Restaurants',
                    subtitle: 'Find restaurants with dine-in',
                    icon: Icons.near_me_rounded,
                    onTap: () => context.go(RoutePaths.discovery),
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

class _DineInCard extends StatelessWidget {
  const _DineInCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gold = ReferenceColors.gold(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: ReferenceColors.card(context),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: ReferenceColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(icon, color: gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: ReferenceColors.sub(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ReferenceColors.sub(context)),
          ],
        ),
      ),
    );
  }
}
