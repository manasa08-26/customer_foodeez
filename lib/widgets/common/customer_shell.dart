import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/reference_colors.dart';
import '../../router/route_paths.dart';

/// Main shell — Home · Dine In · Orders · Profile (Desktop reference).
class CustomerShell extends ConsumerStatefulWidget {
  const CustomerShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_syncCart);
  }

  void _syncCart() {
    if (ref.read(authControllerProvider).value == true) {
      ref.read(cartControllerProvider.notifier).fetchCart();
    }
  }

  int _tabIndex(String location) {
    if (location.startsWith(RoutePaths.dinein)) return 1;
    if (location.startsWith(RoutePaths.orders)) return 2;
    if (location.startsWith(RoutePaths.profile)) return 3;
    return 0;
  }

  void _onTabTap(int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.discovery);
      case 1:
        context.go(RoutePaths.dinein);
      case 2:
        context.go(RoutePaths.orders);
      case 3:
        context.go(RoutePaths.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.value != true && next.value == true) {
        ref.read(cartControllerProvider.notifier).fetchCart();
      }
    });

    final location = GoRouterState.of(context).matchedLocation;
    final selected = _tabIndex(location);
    final onHome = selected == 0;
    final gold = ReferenceColors.gold(context);
    final navBg = AppColors.white;
    final navUnselected = AppColors.textSecondary;

    return PopScope(
      canPop: onHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !onHome) {
          context.go(RoutePaths.discovery);
        }
      },
      child: Scaffold(
        backgroundColor: ReferenceColors.bg(context),
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navBg,
            border: Border(
              top: BorderSide(
                color: ReferenceColors.border(context),
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: selected,
            onTap: _onTabTap,
            backgroundColor: navBg,
            elevation: 0,
            selectedItemColor: gold,
            unselectedItemColor: navUnselected,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: AppDimensions.bottomNavLabelSize,
            unselectedFontSize: AppDimensions.bottomNavLabelSize,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_outlined),
                activeIcon: Icon(Icons.restaurant),
                label: 'Dine In',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
