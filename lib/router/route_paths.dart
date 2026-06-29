/// Centralized route path constants.
class RoutePaths {
  RoutePaths._();

  static const splash = '/';
  static const discovery = '/discovery';
  static const restaurant = '/restaurants/:branchId';
  static String restaurantDetail(String branchId) => '/restaurants/$branchId';
  static const cart = '/cart';
  static const orders = '/orders';
  static const orderDetail = '/orders/:orderId';
  static String orderById(String orderId) => '/orders/$orderId';
  static const profile = '/profile';
  static const payments = '/payments';
  static const support = '/support';
  static const sessions = '/sessions';
  static const review = '/reviews/new/:orderId';
  static String reviewForOrder(String orderId) => '/reviews/new/$orderId';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const resetPassword = '/auth/reset-password';
}
