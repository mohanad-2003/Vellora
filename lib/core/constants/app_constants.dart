/// App-wide constants that are not tied to a specific feature.
class AppConstants {
  AppConstants._();

  static const String appName = 'Vellora';

  /// Keep in sync with `version:` in pubspec.yaml.
  static const String appVersion = '1.0.0';

  static const String supportEmail = 'support@vellora.com';

  /// Placeholder base url — unused by the Phase 1 mocks but wired so a real
  /// API is a drop-in swap later.
  static const String baseUrl = 'https://api.vellora.example.com/v1';

  /// Placeholder public site used for shareable links. Replace with the real
  /// domain when the web presence exists.
  static const String webBaseUrl = 'https://vellora.example.com';

  static String productUrl(String id) => '$webBaseUrl/product/$id';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Hive box names.
  static const String cartBox = 'cart_box';
  static const String favoritesBox = 'favorites_box';
  static const String userBox = 'user_box';

  // SharedPreferences keys.
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefLocale = 'pref_locale';
  static const String prefOnboardingSeen = 'pref_onboarding_seen';
  static const String prefLanguageSelected = 'pref_language_selected';

  // Secure storage keys.
  static const String secureAuthToken = 'secure_auth_token';

  // Simulated latency for mock datasources.
  static const Duration mockDelay = Duration(milliseconds: 1200);
  static const Duration mockShortDelay = Duration(milliseconds: 800);

  /// Reserved input that deterministically triggers a failure in mock
  /// datasources so error/retry states are reachable without a backend.
  static const String reservedExistingEmail = 'existing@vellora.com';
  static const String reservedFailEmail = 'fail@vellora.com';
  static const String unknownProductId = 'unknown';

  /// OTP code that deterministically verifies in the mock reset flow. Any other
  /// 4-digit code fails with a validation failure so error UI is reachable.
  static const String reservedOtpCode = '1234';
}
