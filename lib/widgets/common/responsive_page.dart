import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Scrollable page wrapper — max width + safe padding for phones/tablets.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final horizontal = AppDimensions.pagePadding(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: AppDimensions.spacingMd,
              ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppDimensions.maxContentWidth,
                minHeight: constraints.maxHeight > 0
                    ? constraints.maxHeight - AppDimensions.spacingMd * 2
                    : 0,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
