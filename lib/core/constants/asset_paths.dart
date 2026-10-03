/// Bundled image assets. Only the brand and the pre-login screens ship images
/// inside the app; product, category and banner photos come from the Vellora
/// API.
///
/// ```
/// assets/branding/        logo and app-icon sources
/// assets/images/
///   onboarding/           onboarding / welcome imagery
///   social/               social-login brand marks (Login / Register)
/// ```
/// Never hardcode `assets/...` strings elsewhere — add a constant here.
class AssetPaths {
  AssetPaths._();

  static const String _img = 'assets/images';
  static const String _brand = 'assets/branding';

  // Vellora brand assets (see design/branding_source/ for the masters).
  /// Rounded-square app mark; works on any background.
  static const String brandMark = '$_brand/vellora_mark.png';

  /// Horizontal logo (navy wordmark) for light surfaces.
  static const String brandLogo = '$_brand/vellora_logo.png';

  /// Horizontal logo (gold mark + white wordmark) for dark surfaces.
  static const String brandLogoDark = '$_brand/vellora_logo_dark.png';

  /// White wordmark only, for use beside [brandMark] on dark imagery.
  static const String brandWordmarkLight = '$_brand/vellora_wordmark_light.png';

  // Onboarding / welcome imagery.
  static const String onboardingRack = '$_img/onboarding/onboarding_rack.jpg';
  static const String onboardingDiscover =
      '$_img/onboarding/onboarding_discover.jpg';
  static const String onboardingShopping =
      '$_img/onboarding/onboarding_shopping.jpg';
  static const String onboardingDelivery =
      '$_img/onboarding/onboarding_delivery.jpg';

  // Social login brand marks.
  static const String socialFacebook = '$_img/social/facebook.png';
  static const String socialApple = '$_img/social/apple.png';
  static const String socialGoogle = '$_img/social/google.png';
}
