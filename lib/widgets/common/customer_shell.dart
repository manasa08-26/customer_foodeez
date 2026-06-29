import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/discovery_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../router/route_paths.dart';
import 'home_search_bar.dart';

/// Swiggy-style home chrome — location header, search, bottom nav (home only).
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
    Future.microtask(_syncCartBadge);
  }

  void _syncCartBadge() {
    if (ref.read(authControllerProvider).value == true) {
      ref.read(cartControllerProvider.notifier).fetchCart();
    }
  }

  void _goHome(BuildContext context) {
    context.go(RoutePaths.discovery);
  }

  void _goWallet(BuildContext context) {
    context.go(RoutePaths.payments);
  }

  void _goCart(BuildContext context) {
    if (ref.read(authControllerProvider).value == true) {
      ref.read(cartControllerProvider.notifier).fetchCart();
    }
    context.go(RoutePaths.cart);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.value != true && next.value == true) {
        ref.read(cartControllerProvider.notifier).fetchCart();
      }
    });

    final cartCount = ref.watch(cartControllerProvider).value?.itemCount ?? 0;
    final authed = ref.watch(authControllerProvider).value == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final horizontal = AppDimensions.pagePadding(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _HomeTopHeader(
            horizontalPadding: horizontal,
            authed: authed,
            isDark: isDark,
            onProfileSelected: (value) => _onProfileAction(context, value),
          ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: _HomeBottomNav(
        cartCount: cartCount,
        onHome: () => _goHome(context),
        onWallet: () => _goWallet(context),
        onCart: () => _goCart(context),
      ),
    );
  }

  void _onProfileAction(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        context.go(RoutePaths.profile);
      case 'orders':
        context.go(RoutePaths.orders);
      case 'support':
        context.go(RoutePaths.support);
      case 'sessions':
        context.go(RoutePaths.sessions);
      case 'theme':
        ref.read(themeModeProvider.notifier).toggle();
      case 'logout':
        ref.read(authControllerProvider.notifier).logout();
        context.go(RoutePaths.discovery);
      case 'login':
        context.push(RoutePaths.login);
    }
  }
}

class _HomeTopHeader extends ConsumerWidget {
  const _HomeTopHeader({
    required this.horizontalPadding,
    required this.authed,
    required this.isDark,
    required this.onProfileSelected,
  });

  final double horizontalPadding;
  final bool authed;
  final bool isDark;
  final ValueChanged<String> onProfileSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationResolverProvider).cached;
    final locationLabel = _locationLabel(location);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppDimensions.spacingXs,
            horizontalPadding,
            AppDimensions.spacingSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: AppDimensions.homeHeaderRowHeight,
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: AppDimensions.homeLocationIconSize,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    const SizedBox(width: AppDimensions.spacingXxs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'DELIVERY TO',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  locationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _ProfileMenuButton(
                      authed: authed,
                      isDark: isDark,
                      onSelected: onProfileSelected,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              const HomeSearchBar(),
            ],
          ),
        ),
      ),
    );
  }

  String _locationLabel(LocationState location) {
    if (location.lat == LocationState.fallback.lat &&
        location.lng == LocationState.fallback.lng) {
      return 'Hyderabad';
    }
    return 'Current location';
  }
}

class _ProfileMenuButton extends StatelessWidget {
  const _ProfileMenuButton({
    required this.authed,
    required this.isDark,
    required this.onSelected,
  });

  final bool authed;
  final bool isDark;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) => [
        if (authed) ...[
          const PopupMenuItem(value: 'profile', child: Text('Profile')),
          const PopupMenuItem(value: 'orders', child: Text('Orders')),
          const PopupMenuItem(value: 'support', child: Text('Support')),
          const PopupMenuItem(value: 'sessions', child: Text('Sessions')),
          const PopupMenuItem(value: 'logout', child: Text('Logout')),
        ] else
          const PopupMenuItem(value: 'login', child: Text('Sign in')),
        PopupMenuItem(
          value: 'theme',
          child: Text(isDark ? 'Light mode' : 'Dark mode'),
        ),
      ],
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: 20,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({
    required this.cartCount,
    required this.onHome,
    required this.onWallet,
    required this.onCart,
  });

  final int cartCount;
  final VoidCallback onHome;
  final VoidCallback onWallet;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.65);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppDimensions.bottomNavHeight,
          child: Row(
            children: [
              Expanded(
                child: _BottomNavItem(
                  label: 'Home',
                  icon: Icons.home_rounded,
                  selected: true,
                  onTap: onHome,
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  label: 'Wallet',
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: onWallet,
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  label: 'Cart',
                  icon: Icons.shopping_bag_outlined,
                  badge: cartCount,
                  onTap: onCart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    Widget iconWidget = Icon(
      icon,
      size: AppDimensions.bottomNavIconSize,
      color: color,
    );

    if (badge > 0) {
      iconWidget = badges.Badge(
        position: badges.BadgePosition.topEnd(top: -6, end: -8),
        badgeStyle: const badges.BadgeStyle(
          badgeColor: AppColors.primary,
          padding: EdgeInsets.all(4),
        ),
        badgeContent: Text(
          badge > 99 ? '99+' : '$badge',
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: iconWidget,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppDimensions.bottomNavLabelSize,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
