import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Centered loading indicator.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Text(message!, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
