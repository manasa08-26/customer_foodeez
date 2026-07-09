import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/theme/reference_colors.dart';
import '../../router/route_paths.dart';
import 'customer_logo.dart';

/// Placeholder screen — matches Desktop reference SimpleScreen + coming soon.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    super.key,
    required this.title,
    this.subtitle = 'This feature is coming soon.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReferenceColors.bg(context),
      appBar: AppBar(
        backgroundColor: ReferenceColors.bg(context),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.discovery);
            }
          },
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            color: ReferenceColors.border(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon(
              //   Icons.construction_outlined,
              //   size: 64,
              //   color: ReferenceColors.gold(context),
              // ),
              // const SizedBox(height: AppDimensions.spacingLg),
              const Center(
                child: CustomerLogo.custom(width: 120, height: 120),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: ReferenceColors.sub(context),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              FilledButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RoutePaths.discovery);
                  }
                },
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
