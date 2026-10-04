/// Vellora API paths (see `backend/README.md`).
class ApiEndpoints {
  ApiEndpoints._();

  // Auth & profile.
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String me = '/me';
  static const String changePassword = '/me/change-password';

  // Saved addresses and payment methods.
  static const String addresses = '/addresses';
  static String addressDefault(String id) => '/addresses/$id/default';
  static String address(String id) => '/addresses/$id';
  static const String paymentMethods = '/payment-methods';
  static String paymentMethodDefault(String id) =>
      '/payment-methods/$id/default';
  static String paymentMethod(String id) => '/payment-methods/$id';

  // Catalogue.
  static const String home = '/home';
  static const String categories = '/categories';
  static const String products = '/products';
  static String productDetails(String id) => '/products/$id';
  static String relatedProducts(String id) => '/products/$id/related';
  static String productReviews(String id) => '/products/$id/reviews';

  // Cart and checkout.
  static const String cart = '/cart';
  static const String deliveryOptions = '/delivery-options';

  // Wishlist.
  static const String wishlist = '/wishlist';
  static String wishlistItem(String id) => '/wishlist/$id';

  // Promos, orders, notifications.
  static const String promoValidate = '/promos/validate';
  static const String orders = '/orders';
  static String order(String id) => '/orders/$id';
  static String orderCancel(String id) => '/orders/$id/cancel';
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notification(String id) => '/notifications/$id';
}
