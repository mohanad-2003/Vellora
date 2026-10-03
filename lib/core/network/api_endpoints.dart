/// Vellora API paths (see `backend/README.md`).
class ApiEndpoints {
  ApiEndpoints._();

  // Auth & profile.
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/me';

  // Catalogue.
  static const String home = '/home';
  static const String categories = '/categories';
  static const String products = '/products';
  static String productDetails(String id) => '/products/$id';
  static String relatedProducts(String id) => '/products/$id/related';

  // Promos, orders, notifications.
  static const String promoValidate = '/promos/validate';
  static const String orders = '/orders';
  static String order(String id) => '/orders/$id';
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notification(String id) => '/notifications/$id';
}
