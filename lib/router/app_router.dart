import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../views/auth/login_view.dart';
import '../views/auth/reset_password_view.dart';
import '../views/auth/signup_view.dart';
import '../views/cart/cart_view.dart';
import '../views/discovery/discovery_view.dart';
import '../views/orders/order_detail_view.dart';
import '../views/orders/orders_view.dart';
import '../views/payments/payments_view.dart';
import '../views/profile/profile_view.dart';
import '../views/restaurant/restaurant_detail_view.dart';
import '../views/reviews/review_view.dart';
import '../views/sessions/sessions_view.dart';
import '../views/splash/splash_view.dart';
import '../views/support/support_view.dart';
import '../widgets/common/customer_page_scaffold.dart';
import '../widgets/common/customer_shell.dart';
import 'route_paths.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

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
                  Text(
                    state.uri.path,
                    textAlign: TextAlign.center,
                  ),
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
      final auth = ref.read(authControllerProvider);

      if (auth.isLoading) return null;

      final authed = auth.value == true;

      const protected = {
        RoutePaths.orders,
        RoutePaths.profile,
        RoutePaths.support,
        RoutePaths.sessions,
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
      GoRoute(
        path: RoutePaths.discovery,
        builder: (_, __) => const CustomerShell(child: DiscoveryView()),
      ),
      GoRoute(
        path: RoutePaths.restaurant,
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
        builder: (_, __) => const CustomerPageScaffold(
          title: 'Cart',
          child: CartView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.orders,
        builder: (_, __) => const CustomerPageScaffold(
          title: 'Orders',
          child: OrdersView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.orderDetail,
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
        path: RoutePaths.profile,
        builder: (_, __) => const CustomerPageScaffold(
          title: 'Profile',
          child: ProfileView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.payments,
        builder: (_, __) => const CustomerPageScaffold(
          title: 'Wallet',
          child: PaymentsView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.support,
        builder: (_, __) => const CustomerPageScaffold(
          title: 'Support',
          child: SupportView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.sessions,
        builder: (_, __) => const CustomerPageScaffold(
          title: 'Sessions',
          child: SessionsView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.review,
        builder: (_, state) {
          final orderId = state.pathParameters['orderId']!;
          return CustomerPageScaffold(
            title: 'Rate your order',
            fallbackLocation: RoutePaths.orderById(orderId),
            child: ReviewView(orderId: orderId),
          );
        },
      ),
    ],
  );

  ref.listen(authControllerProvider, (_, __) => router.refresh());
  return router;
});

/// Navigate after successful login using stored redirect path.
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
