import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/theme/reference_colors.dart';
import '../../router/route_paths.dart';

/// Header for shell tabs (Dine In / Orders / Profile) with back to Home.
class ShellTabHeader extends StatelessWidget {
  const ShellTabHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingXs,
        AppDimensions.spacingSm,
        AppDimensions.spacingMd,
        AppDimensions.spacingSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Back to Home',
            onPressed: () => context.go(RoutePaths.discovery),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppDimensions.spacingXxs),
                  Text(
                    subtitle!,
                    style: TextStyle(color: ReferenceColors.sub(context)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
