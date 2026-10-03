// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Vellora';

  @override
  String get onboardingTitle1 => 'Discover Premium Products';

  @override
  String get onboardingBody1 =>
      'Browse a curated collection of the finest products, handpicked just for you.';

  @override
  String get onboardingTitle2 => 'Effortless Shopping';

  @override
  String get onboardingBody2 =>
      'Add to cart, track your bag and check out in just a few taps.';

  @override
  String get onboardingTitle3 => 'Fast & Secure Delivery';

  @override
  String get onboardingBody3 =>
      'Enjoy safe payments and lightning-fast delivery right to your door.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Sign Up';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginSubtitle => 'Log in to continue shopping with us.';

  @override
  String get createAccount => 'Create Account';

  @override
  String get registerSubtitle => 'Sign up to start your shopping journey.';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get forgotPasswordTitle => 'Reset Password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send you a 4-digit code to reset your password.';

  @override
  String get sendResetLink => 'Send Code';

  @override
  String get resetLinkSent => 'A reset link has been sent to your email.';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get backToLogin => 'Back to Log In';

  @override
  String get selectLanguage => 'Choose Your Language';

  @override
  String get selectLanguageSubtitle =>
      'Select your preferred language to continue. You can change it later in settings.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get welcomeTitle => 'Welcome to Vellora';

  @override
  String get welcomeTagline =>
      'Shop smarter. Discover premium products and enjoy a seamless, delightful shopping experience.';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get otpTitle => 'Verification Code';

  @override
  String get otpSubtitle => 'Enter the 4-digit code we sent to';

  @override
  String get verify => 'Verify';

  @override
  String get didntReceiveCode => 'Didn\'t receive the code?';

  @override
  String get resendCode => 'Resend Code';

  @override
  String resendIn(String seconds) {
    return 'Resend in $seconds';
  }

  @override
  String get invalidOtp =>
      'The code you entered is incorrect. Please try again.';

  @override
  String get resetPasswordTitle => 'Create New Password';

  @override
  String get resetPasswordSubtitle =>
      'Your new password must be different from previously used passwords.';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordStrength => 'Password strength';

  @override
  String get weak => 'Weak';

  @override
  String get medium => 'Medium';

  @override
  String get strong => 'Strong';

  @override
  String get passwordResetSuccessTitle => 'Password Reset';

  @override
  String get passwordResetSuccessBody =>
      'Your password has been reset successfully. You can now log in with your new password.';

  @override
  String get agreeToTerms => 'I agree to the ';

  @override
  String get termsAndPrivacy => 'Terms & Privacy Policy';

  @override
  String get mustAcceptTerms =>
      'Please accept the Terms & Privacy Policy to continue.';

  @override
  String get termsPrivacyTitle => 'Terms & Privacy';

  @override
  String get termsSectionUseTitle => '1. Use of Service';

  @override
  String get termsSectionUseBody =>
      'By accessing or using Vellora, you agree to be bound by these terms. You are responsible for maintaining the confidentiality of your account and for all activity that occurs under it.';

  @override
  String get termsSectionPurchasesTitle => '2. Orders & Payments';

  @override
  String get termsSectionPurchasesBody =>
      'All purchases are subject to product availability and price confirmation. We reserve the right to cancel any order in cases of suspected fraud or pricing errors.';

  @override
  String get termsSectionPrivacyTitle => '3. Privacy & Data';

  @override
  String get termsSectionPrivacyBody =>
      'We collect only the information needed to provide and improve our services. Your personal data is never sold to third parties and is protected using industry-standard security measures.';

  @override
  String get termsSectionContactTitle => '4. Contact Us';

  @override
  String get termsSectionContactBody =>
      'If you have any questions about these terms or how we handle your data, reach out to our support team at support@vellora.com.';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get nameTooShort => 'Name must be at least 2 characters';

  @override
  String get home => 'Home';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get searchHint => 'Search for products';

  @override
  String get categories => 'Categories';

  @override
  String get seeAll => 'See All';

  @override
  String get featured => 'Featured';

  @override
  String get flashSale => 'Flash Sale';

  @override
  String get newArrivals => 'New Arrivals';

  @override
  String get bestSellers => 'Best Sellers';

  @override
  String get endsIn => 'Ends in';

  @override
  String get popularSearches => 'Popular searches';

  @override
  String get noProductsTitle => 'No products yet';

  @override
  String get noProductsBody =>
      'There are no products in this category right now.';

  @override
  String get noResultsTitle => 'No results found';

  @override
  String noResultsBody(String query) {
    return 'We couldn\'t find anything for \"$query\". Try a different keyword.';
  }

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get productDetails => 'Product Details';

  @override
  String get selectColor => 'Color';

  @override
  String get selectSize => 'Size';

  @override
  String get description => 'Description';

  @override
  String get reviews => 'Reviews';

  @override
  String get relatedProducts => 'You may also like';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get buyNow => 'Buy Now';

  @override
  String get addedToCart => 'Added to your cart';

  @override
  String get quantity => 'Quantity';

  @override
  String get inStock => 'In Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get cart => 'Cart';

  @override
  String get myCart => 'My Cart';

  @override
  String get emptyCartTitle => 'Your cart is empty';

  @override
  String get emptyCartBody =>
      'Looks like you haven\'t added anything to your cart yet.';

  @override
  String get startShopping => 'Start Shopping';

  @override
  String get promoCode => 'Promo code';

  @override
  String get apply => 'Apply';

  @override
  String get promoApplied => 'Promo code applied';

  @override
  String get invalidPromo => 'Invalid promo code';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get shipping => 'Shipping';

  @override
  String get total => 'Total';

  @override
  String get free => 'Free';

  @override
  String get checkout => 'Checkout';

  @override
  String get removeItem => 'Remove';

  @override
  String get itemRemoved => 'Item removed from cart';

  @override
  String get each => 'each';

  @override
  String get secureCheckout => 'Secure checkout';

  @override
  String get freeShippingUnlocked => 'You\'ve unlocked free shipping!';

  @override
  String addForFreeShipping(String amount) {
    return 'Add $amount more for free shipping';
  }

  @override
  String cartItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get retry => 'Retry';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get noConnection => 'No internet connection';

  @override
  String get serverError => 'Server error, please try again later';

  @override
  String get cacheError => 'Failed to load local data';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get loading => 'Loading...';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get logout => 'Log Out';

  @override
  String get wishlist => 'Wishlist';

  @override
  String get emptyWishlistTitle => 'Your wishlist is empty';

  @override
  String get emptyWishlistBody =>
      'Save your favorite items here to buy them later.';

  @override
  String get browseProducts => 'Browse Products';

  @override
  String get removedFromWishlist => 'Removed from wishlist';

  @override
  String get profile => 'Profile';

  @override
  String get account => 'Account';

  @override
  String get preferences => 'Preferences';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get savedAddresses => 'Saved Addresses';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get security => 'Security';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get guest => 'Guest';

  @override
  String get guestPrompt => 'Sign in to sync your data';

  @override
  String get cancel => 'Cancel';

  @override
  String get logoutConfirmTitle => 'Log Out?';

  @override
  String get logoutConfirmBody =>
      'Are you sure you want to log out of your account?';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get delete => 'Delete';

  @override
  String get defaultLabel => 'Default';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get addNewAddress => 'Add New Address';

  @override
  String get addressAdded => 'Address added';

  @override
  String get saveAddress => 'Save Address';

  @override
  String get addressLabel => 'Label';

  @override
  String get addressLabelHint => 'Home, Work, ...';

  @override
  String get recipientName => 'Recipient Name';

  @override
  String get streetAddress => 'Street Address';

  @override
  String get cityRegion => 'City / Region';

  @override
  String get noAddressesTitle => 'No saved addresses';

  @override
  String get noAddressesBody => 'Add a shipping address to speed up checkout.';

  @override
  String get addCard => 'Add Card';

  @override
  String get cardAdded => 'Card added';

  @override
  String get saveCard => 'Save Card';

  @override
  String get cardNumber => 'Card Number';

  @override
  String get cardHolder => 'Cardholder Name';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get expires => 'Expires';

  @override
  String get noPaymentTitle => 'No payment methods';

  @override
  String get noPaymentBody =>
      'Add a card to check out faster and more securely.';

  @override
  String get signInSecurity => 'Sign-in & Security';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordChanged => 'Password changed successfully';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get biometricLoginSub => 'Use fingerprint or face to sign in';

  @override
  String get twoFactorAuth => 'Two-Factor Authentication';

  @override
  String get twoFactorAuthSub => 'Add an extra layer of security';

  @override
  String get alerts => 'Alerts';

  @override
  String get loginAlerts => 'Login Alerts';

  @override
  String get loginAlertsSub => 'Get notified of new sign-ins';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmTitle => 'Delete Account?';

  @override
  String get deleteAccountConfirmBody =>
      'This will permanently remove your account and all data. This action cannot be undone.';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get shippingAddress => 'Shipping Address';

  @override
  String get change => 'Change';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get estimatedDelivery => 'Estimated delivery';

  @override
  String get deliveryWindow => '3–5 business days';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get orderPlacedTitle => 'Order Placed!';

  @override
  String get orderPlacedBody =>
      'Thank you for your purchase. Your order is confirmed and will be on its way to you shortly.';

  @override
  String get orderNumber => 'Order Number';

  @override
  String get continueShopping => 'Continue Shopping';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get comingSoonBody => 'This feature is on its way. Stay tuned!';

  @override
  String get decreaseQuantity => 'Decrease quantity';

  @override
  String get increaseQuantity => 'Increase quantity';

  @override
  String wasPrice(String price) {
    return 'was $price';
  }

  @override
  String percentOff(int percent) {
    return '$percent% off';
  }

  @override
  String get addToWishlist => 'Add to wishlist';

  @override
  String get removeFromWishlist => 'Remove from wishlist';

  @override
  String pageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get explore => 'Explore';

  @override
  String get notifications => 'Notifications';

  @override
  String get splashTagline => 'Premium shopping, simplified';

  @override
  String get languageEnglishHint => 'English';

  @override
  String get languageArabicHint => 'Arabic';

  @override
  String get onboardingChipSecure => 'Secure payment';

  @override
  String get onboardingChipFast => 'Fast delivery';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithFacebook => 'Continue with Facebook';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get shopNow => 'Shop now';

  @override
  String get viewCart => 'View cart';

  @override
  String get featuredSubtitle => 'Handpicked for you';

  @override
  String get newArrivalsSubtitle => 'Fresh drops this week';

  @override
  String get recommendedForYou => 'Recommended for you';

  @override
  String get recommendedSubtitle => 'Based on what is popular';

  @override
  String get bannerSummerTitle => 'Summer Collection';

  @override
  String get bannerSummerSubtitle => 'Up to 50% off selected styles';

  @override
  String get bannerFlashTitle => 'Flash Sale';

  @override
  String get bannerFlashSubtitle => 'Ends soon — grab it fast';

  @override
  String get bannerNewTitle => 'New Arrivals';

  @override
  String get bannerNewSubtitle => 'Fresh drops every week';

  @override
  String endsInSemantics(int hours, int minutes) {
    return 'Ends in $hours hours $minutes minutes';
  }

  @override
  String get categoryMen => 'Men';

  @override
  String get categoryWomen => 'Women';

  @override
  String get categoryShoes => 'Shoes';

  @override
  String get categoryAccessories => 'Accessories';

  @override
  String get categoryBeauty => 'Beauty';

  @override
  String get categoryElectronics => 'Electronics';

  @override
  String get categoryGrocery => 'Grocery';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorWhite => 'White';

  @override
  String get colorRed => 'Red';

  @override
  String get colorNavy => 'Navy';

  @override
  String get colorSand => 'Sand';

  @override
  String get colorOlive => 'Olive';

  @override
  String get filters => 'Filters';

  @override
  String get sortBy => 'Sort';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String get sortPriceLowHigh => 'Price: low to high';

  @override
  String get sortPriceHighLow => 'Price: high to low';

  @override
  String get sortTopRated => 'Top rated';

  @override
  String get category => 'Category';

  @override
  String get priceRange => 'Price range';

  @override
  String get brand => 'Brand';

  @override
  String get rating => 'Rating';

  @override
  String get anyRating => 'Any';

  @override
  String get onSaleOnly => 'On sale only';

  @override
  String get clearAll => 'Clear all';

  @override
  String applyFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count results',
      one: 'Show 1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get listView => 'List view';

  @override
  String get gridView => 'Grid view';

  @override
  String get notifOrderShippedTitle => 'Your order is on its way';

  @override
  String get notifOrderShippedBody =>
      'Order #SH-20418 has shipped and arrives in 2–3 days.';

  @override
  String get notifFlashSaleTitle => 'Flash sale is live';

  @override
  String get notifFlashSaleBody =>
      'Up to 50% off on selected items, today only.';

  @override
  String get notifOrderDeliveredTitle => 'Order delivered';

  @override
  String get notifOrderDeliveredBody =>
      'Order #SH-20377 was delivered. Enjoy! Tell us what you think.';

  @override
  String get notifWelcomeTitle => 'Welcome to Vellora';

  @override
  String get notifWelcomeBody =>
      'Discover premium products picked just for you.';

  @override
  String get notifNewArrivalsTitle => 'New arrivals are here';

  @override
  String get notifNewArrivalsBody =>
      'Fresh styles just landed. Be the first to shop them.';

  @override
  String get exploreSubtitle => 'Browse every category';

  @override
  String get exploreProducts => 'Explore products';

  @override
  String get products => 'Products';

  @override
  String productsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
      zero: 'No products',
    );
    return '$_temp0';
  }

  @override
  String get noFilterResultsTitle => 'No products match';

  @override
  String get noFilterResultsBody =>
      'Try removing a filter or two to see more products.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get browseCategories => 'Browse categories';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Link copied to clipboard';

  @override
  String youSave(String amount) {
    return 'You save $amount';
  }

  @override
  String get perkDeliveryTitle => 'Free delivery over \$100';

  @override
  String get perkDeliveryBody => 'Arrives in 3–5 business days';

  @override
  String get perkReturnsTitle => 'Easy returns';

  @override
  String get perkReturnsBody => '30-day hassle-free returns';

  @override
  String get perkSecureTitle => 'Secure payment';

  @override
  String get perkSecureBody => 'Your payment details are protected';

  @override
  String get showLess => 'Show less';

  @override
  String get readMore => 'Read more';

  @override
  String get undo => 'Undo';

  @override
  String get deliveryMethod => 'Delivery method';

  @override
  String get deliveryStandard => 'Standard delivery';

  @override
  String get deliveryExpress => 'Express delivery';

  @override
  String deliveryEta(int min, int max) {
    return '$min–$max business days';
  }

  @override
  String get cashOnDelivery => 'Cash on Delivery';

  @override
  String get payOnArrival => 'Pay when your order arrives';

  @override
  String get addressHome => 'Home';

  @override
  String get addressWork => 'Work';

  @override
  String get trackOrder => 'Track order';

  @override
  String get myOrders => 'My Orders';

  @override
  String get ordersAll => 'All';

  @override
  String get orderStatusProcessing => 'Processing';

  @override
  String get orderStatusShipped => 'Shipped';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get viewDetails => 'View details';

  @override
  String get noOrdersTitle => 'No orders yet';

  @override
  String get noOrdersBody => 'When you place an order, it will show up here.';

  @override
  String get orderDetails => 'Order details';

  @override
  String get orderNotFoundTitle => 'Order not found';

  @override
  String get orderNotFoundBody =>
      'We could not find this order. It may have been removed.';

  @override
  String get orderTracking => 'Order tracking';

  @override
  String get orderItems => 'Items';

  @override
  String get trackPlaced => 'Order placed';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotificationsTitle => 'You are all caught up';

  @override
  String get noNotificationsBody =>
      'New updates about your orders and offers will appear here.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get earlier => 'Earlier';

  @override
  String get unread => 'Unread';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get privacy => 'Privacy';

  @override
  String get about => 'About';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get notifPrefOrders => 'Order updates';

  @override
  String get notifPrefOrdersSub => 'Shipping and delivery status';

  @override
  String get notifPrefPromos => 'Offers & promotions';

  @override
  String get notifPrefPromosSub => 'Sales, new arrivals and deals';

  @override
  String get myShopping => 'My shopping';

  @override
  String get support => 'Support';

  @override
  String get helpSupport => 'Help & support';

  @override
  String get helpBody =>
      'Questions about an order or your account? Our team is happy to help.';

  @override
  String get pageNotFoundTitle => 'Page not found';

  @override
  String get pageNotFoundBody =>
      'The page you are looking for does not exist or has moved.';

  @override
  String get goHome => 'Go to Home';
}
