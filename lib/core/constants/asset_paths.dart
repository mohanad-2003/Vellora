/// Centralised references to bundled image assets.
///
/// Layout (declared as directories in `pubspec.yaml`):
/// ```
/// assets/images/
///   (branding lives in assets/branding/, see [AssetPaths.brand*])
///   products/      product photography
///   banners/       promotional banners
///   onboarding/    onboarding / welcome imagery
///   categories/    small category glyphs
///   social/        social-login brand marks
///   payment/       payment-scheme marks
///   avatars/       default avatars
///   icons/         misc small icons
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

  // Illustrations.

  // Banners.
  static const String bannerShoppingWoman =
      '$_img/banners/banner_shopping_woman.png';
  static const String bannerHotSummerSale =
      '$_img/banners/banner_hot_summer_sale.png';
  static const String bannerBoatShoesSale =
      '$_img/banners/banner_boat_shoes_sale.png';

  // Avatars.
  static const String avatarDefault = '$_img/avatars/avatar_default.png';

  // Social login brand marks.
  static const String socialFacebook = '$_img/social/facebook.png';
  static const String socialApple = '$_img/social/apple.png';
  static const String socialGoogle = '$_img/social/google.png';

  // Payment scheme marks.
  static const String payVisa = '$_img/payment/visa.png';
  static const String payPaypal = '$_img/payment/paypal.png';
  static const String payMaestro = '$_img/payment/maestro.png';

  // Product photography.
  static const String hoodieBlack = '$_img/products/product_hoodie_black.png';
  static const String shirtStarPrint =
      '$_img/products/product_shirt_star_print.png';
  static const String dressBlackTrench =
      '$_img/products/product_dress_black_trench.png';
  static const String dressMaxiRose =
      '$_img/products/product_dress_maxi_rose.png';
  static const String dressFloralBag =
      '$_img/products/product_dress_floral_bag.png';
  static const String dressFloralGarden =
      '$_img/products/product_dress_floral_garden.png';
  static const String outfitBlueShorts =
      '$_img/products/product_outfit_blue_shorts.png';
  static const String sneakerBlackAir =
      '$_img/products/product_sneaker_black_air.png';
  static const String smartphoneBlue =
      '$_img/products/product_smartphone_blue.png';
  static const String gameConsoleBundle =
      '$_img/products/product_game_console_bundle.png';
  static const String jacketBomber = '$_img/products/product_jacket_bomber.png';
  static const String cameraDslr = '$_img/products/product_camera_dslr.png';
  static const String shoesLeatherBrogue =
      '$_img/products/product_shoes_leather_brogue.png';
  static const String muesliChocolate =
      '$_img/products/product_muesli_chocolate.png';
  static const String hotChocolate = '$_img/products/product_hot_chocolate.png';
  static const String sneakersStreetOrange =
      '$_img/products/product_sneakers_street_orange.png';
  static const String sneakerCornerRed =
      '$_img/products/product_sneaker_corner_red.png';
  static const String sneakersHighTopMono =
      '$_img/products/product_sneakers_high_top_mono.png';
  static const String sneakersDunkTrio =
      '$_img/products/product_sneakers_dunk_trio.png';
  static const String sneakersRetroRed =
      '$_img/products/product_sneakers_retro_red.png';
  static const String sneakersHighTopGrey =
      '$_img/products/product_sneakers_high_top_grey.png';
  static const String sneakerRedPanel =
      '$_img/products/product_sneaker_red_panel.png';
  static const String sneakersRedWhite =
      '$_img/products/product_sneakers_red_white.png';
  static const String sneakersDunkFlatlay =
      '$_img/products/product_sneakers_dunk_flatlay.png';
  static const String sneakerBasketballRed =
      '$_img/products/product_sneaker_basketball_red.png';
  static const String hairStyler = '$_img/products/product_hair_styler.png';
  static const String watchSteelGrey =
      '$_img/products/product_watch_steel_grey.png';
  static const String bagBlueTote = '$_img/products/product_bag_blue_tote.png';
  static const String sandalsBeige = '$_img/products/product_sandals_beige.png';
  static const String lipstickRed = '$_img/products/product_lipstick_red.png';
  static const String watchAviator = '$_img/products/product_watch_aviator.png';
  static const String sneakersWhiteMinimal =
      '$_img/products/product_sneakers_white_minimal.png';
  static const String heelsWhite = '$_img/products/product_heels_white.png';

  /// Extra shoe shots used to pad out product galleries.
  static const List<String> shoeGallery = [
    sneakersDunkFlatlay,
    sneakersHighTopMono,
    sneakersRetroRed,
    sneakersRedWhite,
  ];

  /// Photos shot on a plain light background. These are shown whole
  /// (`BoxFit.contain`, blended into the card backdrop) instead of cropped.
  /// Network images will carry this as a flag from the API instead.
  static const Set<String> packshots = {
    shirtStarPrint,
    sneakerBlackAir,
    smartphoneBlue,
    gameConsoleBundle,
    shoesLeatherBrogue,
    muesliChocolate,
    sneakerBasketballRed,
    sandalsBeige,
    lipstickRed,
    heelsWhite,
    watchSteelGrey,
  };
}
