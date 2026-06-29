import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/route_paths.dart';

/// Standard screen chrome for routes outside home — AppBar + back to home.
class CustomerPageScaffold extends StatelessWidget {
  const CustomerPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.fallbackLocation,
    this.actions,
  });

  final String title;
  final Widget child;
  final String? fallbackLocation;
  final List<Widget>? actions;

  static void goBack(
    BuildContext context, {
    String? fallbackLocation,
  }) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(fallbackLocation ?? RoutePaths.discovery);
  }

  void _onBack(BuildContext context) {
    goBack(context, fallbackLocation: fallbackLocation);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onBack(context),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: actions,
        ),
        body: child,
      ),
    );
  }
}
