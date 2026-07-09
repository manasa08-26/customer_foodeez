/// Centralized route path constants.
class RoutePaths {
  RoutePaths._();

  static const splash = '/';
  static const discovery = '/discovery';
  static const home = '/home';
  static const dinein = '/dinein';
  static const search = '/search';
  static const restaurant = '/restaurants/:branchId';
  static String restaurantDetail(String branchId) => '/restaurants/$branchId';
  static const cart = '/cart';
  static const orders = '/orders';
  static const orderDetail = '/orders/:orderId';
  static String orderById(String orderId) => '/orders/$orderId';
  static const profile = '/profile';
  static const profileAddresses = '/profile/addresses';
  static const profileSettings = '/profile/settings';
  static const payments = '/payments';
  static const paymentMethods = '/paymentmethods';
  static const support = '/support';
  static const help = '/help';
  static const favourites = '/favourites';
  static const offers = '/offers';
  static const notifications = '/notifications';
  static const locationPicker = '/locationpicker';
  static const tracking = '/tracking';
  static const allRestaurants = '/allrestaurants';
  static const settings = '/settings';
  static const editProfile = '/editprofile';
  static const selectTable = '/selecttable';
  static const bookingHistory = '/bookinghistory';
  static const refundStatus = '/refundstatus';
  static const rewards = '/rewards';
  static const referral = '/referral';
  static const safety = '/safety';
  static const about = '/about';
  static const sessions = '/sessions';
  static const notificationSettings = '/notificationsettings';
  static const privacy = '/privacy';
  static const language = '/language';
  static const changePhone = '/changephone';
  static const deleteAccount = '/deleteaccount';
  static const review = '/reviews/new/:orderId';
  static String reviewForOrder(String orderId) => '/reviews/new/$orderId';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const resetPassword = '/auth/reset-password';
}
