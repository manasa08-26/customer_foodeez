import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../views/auth/login_view.dart';
import '../views/auth/reset_password_view.dart';
import '../views/auth/signup_view.dart';
import '../views/cart/cart_view.dart';
import '../views/dinein/dinein_view.dart';
import '../views/discovery/discovery_view.dart';
import '../views/misc/location_picker_view.dart';
import '../views/orders/order_detail_view.dart';
import '../views/orders/orders_view.dart';
import '../views/payments/payments_view.dart';
import '../views/profile/profile_addresses_view.dart';
import '../views/profile/profile_settings_view.dart';
import '../views/profile/profile_view.dart';
import '../views/restaurant/restaurant_detail_view.dart';
import '../views/reviews/review_view.dart';
import '../views/search/search_view.dart';
import '../views/sessions/sessions_view.dart';
import '../views/splash/splash_view.dart';
import '../views/support/support_view.dart';
import '../widgets/common/coming_soon_view.dart';
import '../widgets/common/customer_page_scaffold.dart';
import '../widgets/common/customer_shell.dart';
import 'coming_soon_routes.dart';
import 'route_paths.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    errorBuilder: (context, state) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Page not found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(state.uri.path, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go(RoutePaths.discovery),
                    child: const Text('Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    redirect: (context, state) {
      final path = state.matchedLocation;
      if (path == RoutePaths.home) return RoutePaths.discovery;

      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) return null;

      final authed = auth.value == true;
      const protected = {
        RoutePaths.orders,
        RoutePaths.profile,
        RoutePaths.support,
        RoutePaths.sessions,
        RoutePaths.profileAddresses,
        RoutePaths.editProfile,
        RoutePaths.payments,
      };
      final isProtected = protected.any(
        (p) => path == p || path.startsWith('$p/'),
      );
      if (isProtected && !authed) {
        ref.read(authRedirectProvider.notifier).set(path);
        return RoutePaths.login;
      }
      if (path.startsWith('/reviews/') && !authed) {
        ref.read(authRedirectProvider.notifier).set(path);
        return RoutePaths.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (_, __) => const SplashView(),
      ),
      GoRoute(
        path: RoutePaths.home,
        redirect: (_, __) => RoutePaths.discovery,
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (_, __) => const LoginView(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        builder: (_, __) => const SignupView(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        builder: (_, __) => const ResetPasswordView(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.discovery,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: DiscoveryView()),
          ),
          GoRoute(
            path: RoutePaths.dinein,
            pageBuilder: (_, __) => const NoTransitionPage(child: DineInView()),
          ),
          GoRoute(
            path: RoutePaths.orders,
            pageBuilder: (_, __) => const NoTransitionPage(child: OrdersView()),
          ),
          GoRoute(
            path: RoutePaths.profile,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ProfileView()),
            routes: [
              GoRoute(
                path: 'settings',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) =>
                    const ComingSoonView(title: 'Settings'),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.search,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SearchView(),
      ),
      GoRoute(
        path: RoutePaths.restaurant,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final branchId = state.pathParameters['branchId']!;
          final name = state.extra is String ? state.extra as String : null;
          return RestaurantDetailView(
            branchId: branchId,
            initialName: name,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.cart,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CustomerPageScaffold(
          title: 'Cart',
          child: CartView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.orderDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final orderId = state.pathParameters['orderId']!;
          return CustomerPageScaffold(
            title: 'Order details',
            fallbackLocation: RoutePaths.orders,
            child: OrderDetailView(orderId: orderId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.profileAddresses,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ProfileAddressesView(),
      ),
      GoRoute(
        path: RoutePaths.editProfile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ProfileSettingsView(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ComingSoonView(title: 'Settings'),
      ),
      GoRoute(
        path: RoutePaths.payments,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CustomerPageScaffold(
          title: 'Wallet',
          child: PaymentsView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.paymentMethods,
        redirect: (_, __) => RoutePaths.payments,
      ),
      GoRoute(
        path: RoutePaths.support,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CustomerPageScaffold(
          title: 'Support',
          child: SupportView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.help,
        redirect: (_, __) => RoutePaths.support,
      ),
      GoRoute(
        path: RoutePaths.sessions,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CustomerPageScaffold(
          title: 'Sessions',
          child: SessionsView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.locationPicker,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const LocationPickerView(),
      ),
      GoRoute(
        path: RoutePaths.review,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final orderId = state.pathParameters['orderId']!;
          return CustomerPageScaffold(
            title: 'Rate your order',
            fallbackLocation: RoutePaths.orderById(orderId),
            child: ReviewView(orderId: orderId),
          );
        },
      ),
      ...ComingSoonRoutes.entries.entries
          .where(
            (e) =>
                e.key != RoutePaths.settings &&
                e.key != RoutePaths.profileSettings,
          )
          .map(
        (e) => GoRoute(
          path: e.key,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => ComingSoonView(title: e.value),
        ),
      ),
    ],
  );

  ref.listen(authControllerProvider, (_, __) => router.refresh());
  return router;
});

void navigateAfterAuth(BuildContext context, WidgetRef ref) {
  final redirect = ref.read(authRedirectProvider);
  ref.read(authRedirectProvider.notifier).clear();
  ref.read(cartControllerProvider.notifier).fetchCart();

  if (redirect != null && redirect.isNotEmpty) {
    context.go(redirect);
  } else {
    context.go(RoutePaths.discovery);
  }
}
