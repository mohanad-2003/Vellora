import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import 'l10n/app_localizations.dart';

/// Resolves a stable string key (from failures / validators / onboarding
/// entities) to its localized value. Keeps copy in the ARB files while letting
/// non-widget layers pass keys around.
String tr(BuildContext context, String key) => _lookup(context.l10n, key);

String _lookup(AppLocalizations l, String key) {
  switch (key) {
    // Validation.
    case 'fieldRequired':
      return l.fieldRequired;
    case 'invalidEmail':
      return l.invalidEmail;
    case 'passwordTooShort':
      return l.passwordTooShort;
    case 'passwordsDoNotMatch':
      return l.passwordsDoNotMatch;
    case 'nameTooShort':
      return l.nameTooShort;
    case 'invalidOtp':
      return l.invalidOtp;
    case 'invalidCredentials':
      return l.invalidCredentials;
    case 'emailTaken':
      return l.emailTaken;
    case 'pleaseLogin':
      return l.pleaseLogin;
    case 'mustAcceptTerms':
      return l.mustAcceptTerms;
    // Failures.
    case 'serverError':
      return l.serverError;
    case 'cacheError':
      return l.cacheError;
    case 'noConnection':
      return l.noConnection;
    case 'somethingWentWrong':
      return l.somethingWentWrong;
    case 'unexpectedError':
      return l.unexpectedError;
    // Onboarding.
    case 'onboardingTitle1':
      return l.onboardingTitle1;
    case 'onboardingBody1':
      return l.onboardingBody1;
    case 'onboardingTitle2':
      return l.onboardingTitle2;
    case 'onboardingBody2':
      return l.onboardingBody2;
    case 'onboardingTitle3':
      return l.onboardingTitle3;
    case 'onboardingBody3':
      return l.onboardingBody3;
    // Mock notifications.
    case 'notifOrderShippedTitle':
      return l.notifOrderShippedTitle;
    case 'notifOrderShippedBody':
      return l.notifOrderShippedBody;
    case 'notifFlashSaleTitle':
      return l.notifFlashSaleTitle;
    case 'notifFlashSaleBody':
      return l.notifFlashSaleBody;
    case 'notifOrderDeliveredTitle':
      return l.notifOrderDeliveredTitle;
    case 'notifOrderDeliveredBody':
      return l.notifOrderDeliveredBody;
    case 'notifWelcomeTitle':
      return l.notifWelcomeTitle;
    case 'notifWelcomeBody':
      return l.notifWelcomeBody;
    case 'notifNewArrivalsTitle':
      return l.notifNewArrivalsTitle;
    case 'notifNewArrivalsBody':
      return l.notifNewArrivalsBody;
    default:
      return l.somethingWentWrong;
  }
}

/// Localized category name for a category [id] (`men`, `shoes`, …). Falls back
/// to the backend-provided [fallback] for ids this build does not know.
String categoryLabel(BuildContext context, String id, {String? fallback}) {
  final l = context.l10n;
  switch (id) {
    case 'men':
      return l.categoryMen;
    case 'women':
      return l.categoryWomen;
    case 'shoes':
      return l.categoryShoes;
    case 'accessories':
      return l.categoryAccessories;
    case 'beauty':
      return l.categoryBeauty;
    case 'electronics':
      return l.categoryElectronics;
    case 'grocery':
      return l.categoryGrocery;
    default:
      return fallback ?? id;
  }
}

/// Localized product-colour name (`Black`, `Sand`, …). Unknown names pass
/// through unchanged so API-provided colours still render.
String colorLabel(BuildContext context, String name) {
  final l = context.l10n;
  switch (name.toLowerCase()) {
    case 'black':
      return l.colorBlack;
    case 'white':
      return l.colorWhite;
    case 'red':
      return l.colorRed;
    case 'navy':
      return l.colorNavy;
    case 'sand':
      return l.colorSand;
    case 'olive':
      return l.colorOlive;
    default:
      return name;
  }
}

/// Icon used for a category when no photo is available.
IconData categoryIcon(String id) {
  switch (id) {
    case 'men':
      return Icons.checkroom_rounded;
    case 'women':
      return Icons.woman_rounded;
    case 'shoes':
      return Icons.ice_skating_rounded;
    case 'accessories':
      return Icons.watch_rounded;
    case 'beauty':
      return Icons.spa_rounded;
    case 'electronics':
      return Icons.devices_rounded;
    case 'grocery':
      return Icons.local_grocery_store_rounded;
    default:
      return Icons.category_rounded;
  }
}
