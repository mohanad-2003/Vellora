import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Vellora'**
  String get appName;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Discover Premium Products'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Browse a curated collection of the finest products, handpicked just for you.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Effortless Shopping'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Add to cart, track your bag and check out in just a few taps.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Fast & Secure Delivery'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Enjoy safe payments and lightning-fast delivery right to your door.'**
  String get onboardingBody3;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get register;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue shopping with us.'**
  String get loginSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to start your shopping journey.'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a 4-digit code to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'A reset link has been sent to your email.'**
  String get resetLinkSent;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Log In'**
  String get backToLogin;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get selectLanguage;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language to continue. You can change it later in settings.'**
  String get selectLanguageSubtitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Vellora'**
  String get welcomeTitle;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Shop smarter. Discover premium products and enjoy a seamless, delightful shopping experience.'**
  String get welcomeTagline;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4-digit code we sent to'**
  String get otpSubtitle;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}'**
  String resendIn(String seconds);

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'The code you entered is incorrect. Please try again.'**
  String get invalidOtp;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from previously used passwords.'**
  String get resetPasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get passwordStrength;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @passwordResetSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reset'**
  String get passwordResetSuccessTitle;

  /// No description provided for @passwordResetSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset successfully. You can now log in with your new password.'**
  String get passwordResetSuccessBody;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToTerms;

  /// No description provided for @termsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy Policy'**
  String get termsAndPrivacy;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms & Privacy Policy to continue.'**
  String get mustAcceptTerms;

  /// No description provided for @termsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsPrivacyTitle;

  /// No description provided for @termsSectionUseTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Use of Service'**
  String get termsSectionUseTitle;

  /// No description provided for @termsSectionUseBody.
  ///
  /// In en, this message translates to:
  /// **'By accessing or using Vellora, you agree to be bound by these terms. You are responsible for maintaining the confidentiality of your account and for all activity that occurs under it.'**
  String get termsSectionUseBody;

  /// No description provided for @termsSectionPurchasesTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Orders & Payments'**
  String get termsSectionPurchasesTitle;

  /// No description provided for @termsSectionPurchasesBody.
  ///
  /// In en, this message translates to:
  /// **'All purchases are subject to product availability and price confirmation. We reserve the right to cancel any order in cases of suspected fraud or pricing errors.'**
  String get termsSectionPurchasesBody;

  /// No description provided for @termsSectionPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Privacy & Data'**
  String get termsSectionPrivacyTitle;

  /// No description provided for @termsSectionPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'We collect only the information needed to provide and improve our services. Your personal data is never sold to third parties and is protected using industry-standard security measures.'**
  String get termsSectionPrivacyBody;

  /// No description provided for @termsSectionContactTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Contact Us'**
  String get termsSectionContactTitle;

  /// No description provided for @termsSectionContactBody.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions about these terms or how we handle your data, reach out to our support team at support@vellora.com.'**
  String get termsSectionContactBody;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for products'**
  String get searchHint;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @flashSale.
  ///
  /// In en, this message translates to:
  /// **'Flash Sale'**
  String get flashSale;

  /// No description provided for @newArrivals.
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get newArrivals;

  /// No description provided for @bestSellers.
  ///
  /// In en, this message translates to:
  /// **'Best Sellers'**
  String get bestSellers;

  /// No description provided for @endsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in'**
  String get endsIn;

  /// No description provided for @popularSearches.
  ///
  /// In en, this message translates to:
  /// **'Popular searches'**
  String get popularSearches;

  /// No description provided for @noProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsTitle;

  /// No description provided for @noProductsBody.
  ///
  /// In en, this message translates to:
  /// **'There are no products in this category right now.'**
  String get noProductsBody;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsTitle;

  /// No description provided for @noResultsBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find anything for \"{query}\". Try a different keyword.'**
  String noResultsBody(String query);

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String resultsCount(int count);

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get selectColor;

  /// No description provided for @selectSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get selectSize;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @relatedProducts.
  ///
  /// In en, this message translates to:
  /// **'You may also like'**
  String get relatedProducts;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to your cart'**
  String get addedToCart;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @myCart.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get myCart;

  /// No description provided for @emptyCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get emptyCartTitle;

  /// No description provided for @emptyCartBody.
  ///
  /// In en, this message translates to:
  /// **'Looks like you haven\'t added anything to your cart yet.'**
  String get emptyCartBody;

  /// No description provided for @startShopping.
  ///
  /// In en, this message translates to:
  /// **'Start Shopping'**
  String get startShopping;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @promoApplied.
  ///
  /// In en, this message translates to:
  /// **'Promo code applied'**
  String get promoApplied;

  /// No description provided for @invalidPromo.
  ///
  /// In en, this message translates to:
  /// **'Invalid promo code'**
  String get invalidPromo;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeItem;

  /// No description provided for @itemRemoved.
  ///
  /// In en, this message translates to:
  /// **'Item removed from cart'**
  String get itemRemoved;

  /// No description provided for @each.
  ///
  /// In en, this message translates to:
  /// **'each'**
  String get each;

  /// No description provided for @secureCheckout.
  ///
  /// In en, this message translates to:
  /// **'Secure checkout'**
  String get secureCheckout;

  /// No description provided for @freeShippingUnlocked.
  ///
  /// In en, this message translates to:
  /// **'You\'ve unlocked free shipping!'**
  String get freeShippingUnlocked;

  /// No description provided for @addForFreeShipping.
  ///
  /// In en, this message translates to:
  /// **'Add {amount} more for free shipping'**
  String addForFreeShipping(String amount);

  /// No description provided for @cartItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String cartItemsCount(int count);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noConnection;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error, please try again later'**
  String get serverError;

  /// No description provided for @cacheError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load local data'**
  String get cacheError;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @emptyWishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get emptyWishlistTitle;

  /// No description provided for @emptyWishlistBody.
  ///
  /// In en, this message translates to:
  /// **'Save your favorite items here to buy them later.'**
  String get emptyWishlistBody;

  /// No description provided for @browseProducts.
  ///
  /// In en, this message translates to:
  /// **'Browse Products'**
  String get browseProducts;

  /// No description provided for @removedFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Removed from wishlist'**
  String get removedFromWishlist;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get savedAddresses;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @guestPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data'**
  String get guestPrompt;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get logoutConfirmBody;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// No description provided for @addressAdded.
  ///
  /// In en, this message translates to:
  /// **'Address added'**
  String get addressAdded;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddress;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get addressLabel;

  /// No description provided for @addressLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Home, Work, ...'**
  String get addressLabelHint;

  /// No description provided for @recipientName.
  ///
  /// In en, this message translates to:
  /// **'Recipient Name'**
  String get recipientName;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @cityRegion.
  ///
  /// In en, this message translates to:
  /// **'City / Region'**
  String get cityRegion;

  /// No description provided for @noAddressesTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses'**
  String get noAddressesTitle;

  /// No description provided for @noAddressesBody.
  ///
  /// In en, this message translates to:
  /// **'Add a shipping address to speed up checkout.'**
  String get noAddressesBody;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add Card'**
  String get addCard;

  /// No description provided for @cardAdded.
  ///
  /// In en, this message translates to:
  /// **'Card added'**
  String get cardAdded;

  /// No description provided for @saveCard.
  ///
  /// In en, this message translates to:
  /// **'Save Card'**
  String get saveCard;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @cardHolder.
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get cardHolder;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @noPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'No payment methods'**
  String get noPaymentTitle;

  /// No description provided for @noPaymentBody.
  ///
  /// In en, this message translates to:
  /// **'Add a card to check out faster and more securely.'**
  String get noPaymentBody;

  /// No description provided for @signInSecurity.
  ///
  /// In en, this message translates to:
  /// **'Sign-in & Security'**
  String get signInSecurity;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @biometricLoginSub.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face to sign in'**
  String get biometricLoginSub;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @twoFactorAuthSub.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security'**
  String get twoFactorAuthSub;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @loginAlerts.
  ///
  /// In en, this message translates to:
  /// **'Login Alerts'**
  String get loginAlerts;

  /// No description provided for @loginAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Get notified of new sign-ins'**
  String get loginAlertsSub;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove your account and all data. This action cannot be undone.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get shippingAddress;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @estimatedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Estimated delivery'**
  String get estimatedDelivery;

  /// No description provided for @deliveryWindow.
  ///
  /// In en, this message translates to:
  /// **'3–5 business days'**
  String get deliveryWindow;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @orderPlacedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Placed!'**
  String get orderPlacedTitle;

  /// No description provided for @orderPlacedBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase. Your order is confirmed and will be on its way to you shortly.'**
  String get orderPlacedBody;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orderNumber;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get continueShopping;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This feature is on its way. Stay tuned!'**
  String get comingSoonBody;

  /// No description provided for @decreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get decreaseQuantity;

  /// No description provided for @increaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get increaseQuantity;

  /// No description provided for @wasPrice.
  ///
  /// In en, this message translates to:
  /// **'was {price}'**
  String wasPrice(String price);

  /// No description provided for @percentOff.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off'**
  String percentOff(int percent);

  /// No description provided for @addToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Add to wishlist'**
  String get addToWishlist;

  /// No description provided for @removeFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from wishlist'**
  String get removeFromWishlist;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageOf(int current, int total);

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Premium shopping, simplified'**
  String get splashTagline;

  /// No description provided for @languageEnglishHint.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishHint;

  /// No description provided for @languageArabicHint.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabicHint;

  /// No description provided for @onboardingChipSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure payment'**
  String get onboardingChipSecure;

  /// No description provided for @onboardingChipFast.
  ///
  /// In en, this message translates to:
  /// **'Fast delivery'**
  String get onboardingChipFast;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get continueWithFacebook;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @shopNow.
  ///
  /// In en, this message translates to:
  /// **'Shop now'**
  String get shopNow;

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View cart'**
  String get viewCart;

  /// No description provided for @featuredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Handpicked for you'**
  String get featuredSubtitle;

  /// No description provided for @newArrivalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh drops this week'**
  String get newArrivalsSubtitle;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYou;

  /// No description provided for @recommendedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based on what is popular'**
  String get recommendedSubtitle;

  /// No description provided for @bannerSummerTitle.
  ///
  /// In en, this message translates to:
  /// **'Summer Collection'**
  String get bannerSummerTitle;

  /// No description provided for @bannerSummerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Up to 50% off selected styles'**
  String get bannerSummerSubtitle;

  /// No description provided for @bannerFlashTitle.
  ///
  /// In en, this message translates to:
  /// **'Flash Sale'**
  String get bannerFlashTitle;

  /// No description provided for @bannerFlashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ends soon — grab it fast'**
  String get bannerFlashSubtitle;

  /// No description provided for @bannerNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get bannerNewTitle;

  /// No description provided for @bannerNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh drops every week'**
  String get bannerNewSubtitle;

  /// No description provided for @endsInSemantics.
  ///
  /// In en, this message translates to:
  /// **'Ends in {hours} hours {minutes} minutes'**
  String endsInSemantics(int hours, int minutes);

  /// No description provided for @categoryMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get categoryMen;

  /// No description provided for @categoryWomen.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get categoryWomen;

  /// No description provided for @categoryShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get categoryShoes;

  /// No description provided for @categoryAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get categoryAccessories;

  /// No description provided for @categoryBeauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get categoryBeauty;

  /// No description provided for @categoryElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryElectronics;

  /// No description provided for @categoryGrocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get categoryGrocery;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorNavy.
  ///
  /// In en, this message translates to:
  /// **'Navy'**
  String get colorNavy;

  /// No description provided for @colorSand.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get colorSand;

  /// No description provided for @colorOlive.
  ///
  /// In en, this message translates to:
  /// **'Olive'**
  String get colorOlive;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortBy;

  /// No description provided for @sortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get sortRelevance;

  /// No description provided for @sortPriceLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceLowHigh;

  /// No description provided for @sortPriceHighLow.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceHighLow;

  /// No description provided for @sortTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get sortTopRated;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get priceRange;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @anyRating.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get anyRating;

  /// No description provided for @onSaleOnly.
  ///
  /// In en, this message translates to:
  /// **'On sale only'**
  String get onSaleOnly;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{Show 1 result} other{Show {count} results}}'**
  String applyFilters(int count);

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get gridView;

  /// No description provided for @notifOrderShippedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your order is on its way'**
  String get notifOrderShippedTitle;

  /// No description provided for @notifOrderShippedBody.
  ///
  /// In en, this message translates to:
  /// **'Order #SH-20418 has shipped and arrives in 2–3 days.'**
  String get notifOrderShippedBody;

  /// No description provided for @notifFlashSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Flash sale is live'**
  String get notifFlashSaleTitle;

  /// No description provided for @notifFlashSaleBody.
  ///
  /// In en, this message translates to:
  /// **'Up to 50% off on selected items, today only.'**
  String get notifFlashSaleBody;

  /// No description provided for @notifOrderDeliveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Order delivered'**
  String get notifOrderDeliveredTitle;

  /// No description provided for @notifOrderDeliveredBody.
  ///
  /// In en, this message translates to:
  /// **'Order #SH-20377 was delivered. Enjoy! Tell us what you think.'**
  String get notifOrderDeliveredBody;

  /// No description provided for @notifWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Vellora'**
  String get notifWelcomeTitle;

  /// No description provided for @notifWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Discover premium products picked just for you.'**
  String get notifWelcomeBody;

  /// No description provided for @notifNewArrivalsTitle.
  ///
  /// In en, this message translates to:
  /// **'New arrivals are here'**
  String get notifNewArrivalsTitle;

  /// No description provided for @notifNewArrivalsBody.
  ///
  /// In en, this message translates to:
  /// **'Fresh styles just landed. Be the first to shop them.'**
  String get notifNewArrivalsBody;

  /// No description provided for @exploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse every category'**
  String get exploreSubtitle;

  /// No description provided for @exploreProducts.
  ///
  /// In en, this message translates to:
  /// **'Explore products'**
  String get exploreProducts;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No products} =1{1 product} other{{count} products}}'**
  String productsCount(int count);

  /// No description provided for @noFilterResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No products match'**
  String get noFilterResultsTitle;

  /// No description provided for @noFilterResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try removing a filter or two to see more products.'**
  String get noFilterResultsBody;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse categories'**
  String get browseCategories;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String reviewsCount(int count);

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;

  /// No description provided for @youSave.
  ///
  /// In en, this message translates to:
  /// **'You save {amount}'**
  String youSave(String amount);

  /// No description provided for @perkDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Free delivery over \$100'**
  String get perkDeliveryTitle;

  /// No description provided for @perkDeliveryBody.
  ///
  /// In en, this message translates to:
  /// **'Arrives in 3–5 business days'**
  String get perkDeliveryBody;

  /// No description provided for @perkReturnsTitle.
  ///
  /// In en, this message translates to:
  /// **'Easy returns'**
  String get perkReturnsTitle;

  /// No description provided for @perkReturnsBody.
  ///
  /// In en, this message translates to:
  /// **'30-day hassle-free returns'**
  String get perkReturnsBody;

  /// No description provided for @perkSecureTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure payment'**
  String get perkSecureTitle;

  /// No description provided for @perkSecureBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment details are protected'**
  String get perkSecureBody;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @deliveryMethod.
  ///
  /// In en, this message translates to:
  /// **'Delivery method'**
  String get deliveryMethod;

  /// No description provided for @deliveryStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard delivery'**
  String get deliveryStandard;

  /// No description provided for @deliveryExpress.
  ///
  /// In en, this message translates to:
  /// **'Express delivery'**
  String get deliveryExpress;

  /// No description provided for @deliveryEta.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} business days'**
  String deliveryEta(int min, int max);

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashOnDelivery;

  /// No description provided for @payOnArrival.
  ///
  /// In en, this message translates to:
  /// **'Pay when your order arrives'**
  String get payOnArrival;

  /// No description provided for @addressHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addressHome;

  /// No description provided for @addressWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get addressWork;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track order'**
  String get trackOrder;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @ordersAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersAll;

  /// No description provided for @orderStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get orderStatusProcessing;

  /// No description provided for @orderStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderStatusShipped;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @noOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersTitle;

  /// No description provided for @noOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'When you place an order, it will show up here.'**
  String get noOrdersBody;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetails;

  /// No description provided for @orderNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFoundTitle;

  /// No description provided for @orderNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'We could not find this order. It may have been removed.'**
  String get orderNotFoundBody;

  /// No description provided for @orderTracking.
  ///
  /// In en, this message translates to:
  /// **'Order tracking'**
  String get orderTracking;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get orderItems;

  /// No description provided for @trackPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get trackPlaced;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up'**
  String get noNotificationsTitle;

  /// No description provided for @noNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'New updates about your orders and offers will appear here.'**
  String get noNotificationsBody;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlier;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @notifPrefOrders.
  ///
  /// In en, this message translates to:
  /// **'Order updates'**
  String get notifPrefOrders;

  /// No description provided for @notifPrefOrdersSub.
  ///
  /// In en, this message translates to:
  /// **'Shipping and delivery status'**
  String get notifPrefOrdersSub;

  /// No description provided for @notifPrefPromos.
  ///
  /// In en, this message translates to:
  /// **'Offers & promotions'**
  String get notifPrefPromos;

  /// No description provided for @notifPrefPromosSub.
  ///
  /// In en, this message translates to:
  /// **'Sales, new arrivals and deals'**
  String get notifPrefPromosSub;

  /// No description provided for @myShopping.
  ///
  /// In en, this message translates to:
  /// **'My shopping'**
  String get myShopping;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupport;

  /// No description provided for @helpBody.
  ///
  /// In en, this message translates to:
  /// **'Questions about an order or your account? Our team is happy to help.'**
  String get helpBody;

  /// No description provided for @pageNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFoundTitle;

  /// No description provided for @pageNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist or has moved.'**
  String get pageNotFoundBody;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goHome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
