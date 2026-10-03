/// Centralised route paths + names. Reserved paths for later phases are
/// declared so features slot in without router rework.
class RouteNames {
  RouteNames._();

  // Implemented in Phase 1.
  static const String splash = '/splash';
  static const String languageSelect = '/language-select';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String createNewPassword = '/create-new-password';
  static const String passwordResetSuccess = '/password-reset-success';
  static const String termsPrivacy = '/terms-privacy';
  static const String home = '/home';
  static const String product = '/product/:id';
  static const String cart = '/cart';
  static const String catalog = '/catalog';
  static const String explore = '/explore';
  static const String orderDetails = '/orders/:id';
  static const String orderSuccess = '/order-success';

  static String orderDetailsPath(String id) => '/orders/$id';

  static String productPath(String id) => '/product/$id';

  static const String wishlist = '/wishlist';
  static const String checkout = '/checkout';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String savedAddresses = '/profile/addresses';
  static const String paymentMethods = '/profile/payment-methods';
  static const String security = '/profile/security';

  static const String orders = '/orders';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String search = '/search';

  // Route names (used for context.goNamed).
  static const String nSplash = 'splash';
  static const String nLanguageSelect = 'languageSelect';
  static const String nOnboarding = 'onboarding';
  static const String nWelcome = 'welcome';
  static const String nLogin = 'login';
  static const String nRegister = 'register';
  static const String nForgotPassword = 'forgotPassword';
  static const String nOtpVerification = 'otpVerification';
  static const String nCreateNewPassword = 'createNewPassword';
  static const String nPasswordResetSuccess = 'passwordResetSuccess';
  static const String nTermsPrivacy = 'termsPrivacy';
  static const String nHome = 'home';
  static const String nProduct = 'product';
  static const String nCart = 'cart';
  static const String nCatalog = 'catalog';
  static const String nWishlist = 'wishlist';
  static const String nCheckout = 'checkout';
  static const String nOrders = 'orders';
  static const String nProfile = 'profile';
  static const String nEditProfile = 'editProfile';
  static const String nSavedAddresses = 'savedAddresses';
  static const String nPaymentMethods = 'paymentMethods';
  static const String nSecurity = 'security';
  static const String nNotifications = 'notifications';
  static const String nSettings = 'settings';
  static const String nSearch = 'search';
  static const String nExplore = 'explore';
  static const String nOrderDetails = 'orderDetails';
  static const String nOrderSuccess = 'orderSuccess';
}
