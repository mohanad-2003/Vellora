import 'package:flutter/foundation.dart';

/// App-wide constants that are not tied to a specific feature.
class AppConstants {
  AppConstants._();

  static const String appName = 'Vellora';

  /// Keep in sync with `version:` in pubspec.yaml.
  static const String appVersion = '1.0.0';

  static const String supportEmail = 'support@vellora.com';

  /// The deployed Vellora API (Render).
  static const String productionApiUrl =
      'https://vellora-api-3kxz.onrender.com';

  /// Vellora API root. Override at build time:
  /// `flutter run --dart-define=API_BASE_URL=https://api.example.com`.
  ///
  /// Debug builds default to a backend on the development machine: the Android
  /// emulator reaches the host as `10.0.2.2`; everything else (iOS simulator,
  /// desktop, web) can use `localhost`. Release builds default to
  /// [productionApiUrl].
  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    // Release builds talk to the live service; debug builds to a backend on
    // the development machine.
    if (kReleaseMode) return productionApiUrl;
    final androidEmulator =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return androidEmulator ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  /// Placeholder public site used for shareable links. Replace with the real
  /// domain when the web presence exists.
  static const String webBaseUrl = 'https://vellora.example.com';

  static String productUrl(String id) => '$webBaseUrl/product/$id';

  // Generous: Render's free tier sleeps and can take ~50s to wake up.
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

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
