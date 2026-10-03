<div align="center">

<img src="assets/branding/vellora_logo.png" alt="Vellora" height="72"/>

**A premium fashion e-commerce app built with Flutter, Clean Architecture & Bloc.**

[![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![State Management](https://img.shields.io/badge/State-Bloc-13B9FD)](https://bloclibrary.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-4CAF50)](#-architecture)
[![License](https://img.shields.io/badge/License-Private-lightgrey)](#-license)

</div>

---

## 📖 Overview

**Vellora** is a complete shopping experience, from the first launch to order
confirmation: language choice, onboarding, authentication, a tabbed storefront
(Home, Explore, Wishlist, Cart, Profile), search with filters, checkout, orders,
notifications and settings.

It ships with full **English & Arabic** support (true RTL mirroring), **light and dark
themes**, responsive layouts, accessibility semantics, and skeleton / empty / error
states throughout.

> **Backend:** the Node.js API (Express + PostgreSQL, JWT auth, orders, wishlist,
> notifications) lives in its own repository,
> [`mohanad-2003/vellora-api`](https://github.com/mohanad-2003/vellora-api).
> The app talks to it by default; start it first (see *Getting Started*). Products, reviews
> and **all product, category and banner photos** are real data from the public
> [DummyJSON](https://dummyjson.com) API, served through the Vellora API. The app bundles
> only the logo, the onboarding / welcome pictures and the social-login icons.

---

## ✨ Features

| Area | Highlights |
|------|-----------|
| 🌐 **Language gate** | First-launch English / Arabic choice, applied live (the screen flips to RTL instantly) |
| 🚀 **Onboarding** | Immersive full-bleed pages with parallax, skip / next flow |
| 🔐 **Authentication** | Welcome, Login, Sign Up (with password-strength meter), Forgot Password, 4-digit OTP, new password, success |
| 🏠 **Home** | Promo banners, categories, curated product rows, countdown deals |
| 🧭 **Explore & Search** | Category browsing, search with sort and filter sheet |
| 📦 **Product details** | Gallery, size / colour variants, reviews (and writing one), related products |
| ❤️ **Wishlist** | Favourites work for guests and sync to the account on sign-in (merged, nothing lost) |
| 🛒 **Cart & Checkout** | Quantity control, live totals, delivery methods, order success |
| 🧾 **Orders** | Place orders, order history and details (server-side totals), cancel while processing |
| 📍 **Addresses & cards** | Saved on the server per account (cards keep only brand, last four digits and expiry); used at checkout |
| 🔒 **Account security** | Change password and delete account (password-confirmed) call the API |
| 🔔 **Notifications** | Notification centre (server feed, unread dot on Home) |
| ⚙️ **Settings & Profile** | Language, theme, account sections |
| 🎨 **Design system** | Colour tokens, Inter / Cairo typography, spacing and radius scales |
| ♿ **Accessibility** | Semantics labels, 48dp touch targets, text scale up to 1.6×, reduced-motion support |
| ✅ **Tested** | Bloc, flow, widget and overflow tests |

The bottom navigation uses `StatefulShellRoute` so each tab keeps its own stack and
scroll position, and the cart tab shows a live item-count badge.

---

## 🏗️ Architecture

Each feature follows **Clean Architecture** in three layers:

```
Presentation  ──▶  Domain  ──▶  Data
 (Bloc / UI)     (Entities,     (Models,
                  UseCases,      DataSources,
                  Repo contracts) Repo impls)
```

Cross-cutting code (DI, theme, routing, localization, shared widgets) lives in
[`lib/core/`](lib/core/).

```
lib/
├── app.dart                  # Root MaterialApp (theme, locale, router)
├── main.dart                 # Bootstrap: Hive, DI, runApp
├── core/
│   ├── constants/            # App constants, asset paths
│   ├── di/                   # get_it + injectable
│   ├── localization/l10n/    # ARB files & generated localizations
│   ├── mock/                 # Tiny fixtures for the test suite only
│   ├── responsive/           # Breakpoints, grid columns, page gutters
│   ├── routing/              # go_router config, shell, route names
│   ├── theme/                # Colours, typography, spacing, radius, themes
│   ├── utils/                # Haptics, validators, helpers
│   └── widgets/              # Shared components (buttons, cards, logo, states…)
└── features/
    ├── splash/   language_select/   onboarding/   auth/
    ├── home/     explore/           catalog/      product/
    ├── wishlist/ cart/              checkout/     orders/
    └── notifications/   settings/   profile/
```

---

## 🧰 Tech Stack

| Category | Packages |
|----------|----------|
| **State management** | `flutter_bloc`, `equatable` |
| **Routing** | `go_router` |
| **Dependency injection** | `get_it`, `injectable` |
| **Code generation** | `freezed`, `json_serializable`, `build_runner` |
| **Local storage** | `hive`, `shared_preferences`, `flutter_secure_storage` |
| **Networking** | `dio`, `retrofit`, `pretty_dio_logger` |
| **Functional errors** | `fpdart` |
| **UI** | `cached_network_image`, `flutter_svg`, `lottie`, `shimmer`, `responsive_framework` |
| **Testing** | `bloc_test`, `mocktail`, `flutter_test` |
| **Tooling** | `flutter_launcher_icons` |

---

## 🎨 Design System & Branding

- **Colours** — [`app_colors.dart`](lib/core/theme/app_colors.dart): brand palette, a
  `VelloraColors` theme extension (`context.vellora`), and the signature gold / navy
  (`kBrandGold`, `kBrandNavy`) used on the dark brand screens (language, onboarding,
  welcome).
- **Typography** — Inter (Latin) and Cairo (Arabic), bundled as variable fonts.
- **Tokens** — [`app_spacing.dart`](lib/core/theme/app_spacing.dart) (4pt scale),
  [`app_radius.dart`](lib/core/theme/app_radius.dart),
  [`app_theme.dart`](lib/core/theme/app_theme.dart) (light & dark, per locale).
- **Brand assets** — [`assets/branding/`](assets/branding/). The logo widgets
  (`VelloraLogo`, `VelloraMark`, `VelloraWordmark`) pick the right variant for light /
  dark and are never mirrored in RTL.
- **Regenerating brand images and icons** — sources are in
  [`design/branding_source/`](design/branding_source/):

  ```bash
  python design/branding_source/generate_branding.py   # rebuilds assets/branding/
  dart run flutter_launcher_icons                       # app icons for all platforms
  ```

Application id / bundle id is still `com.example.vellora`; change it before publishing.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **≥ 3.47** (Dart **≥ 3.13**)
- A device or emulator (Android, iOS, web or desktop)

### Run

```bash
git clone <your-repo-url>
cd ui_kit

# 1. Backend: clone and start the API (needs Node 22+), see its README
git clone https://github.com/mohanad-2003/vellora-api.git
cd vellora-api && npm install && npm start  # http://localhost:3000
cd ..

# 2. App
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # DI, freezed, json
flutter gen-l10n                                           # localizations
flutter run
```

The API address defaults to `http://10.0.2.2:3000` on the Android emulator and
`http://localhost:3000` elsewhere. For a real phone or a deployed server:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000
```

Deploying the API to Render: see the [API repository](https://github.com/mohanad-2003/vellora-api#deploy-on-render).

Debug and profile Android builds allow plain HTTP for local development; release builds
need an HTTPS `API_BASE_URL`. Without an email provider, the password-reset code is
printed in the backend log (and in the app's debug console).

### Localization

Strings live in [`lib/core/localization/l10n/`](lib/core/localization/l10n/)
(`app_en.arb` is the template, plus `app_ar.arb`). Regenerate after editing:

```bash
flutter gen-l10n
```

The brand name **Vellora** stays in Latin script in Arabic text.

---

## 🧪 Testing

```bash
flutter analyze
flutter test
```

| Suite | Covers |
|-------|--------|
| `test/app_flow_test.dart` | Splash, language, onboarding and navigation flow |
| `test/pre_home_flow_test.dart` | Welcome → Login / Register / Forgot password |
| `test/pre_home_overflow_test.dart` | Pre-home layouts at different sizes and text scales |
| `test/wishlist_profile_test.dart` | Wishlist and profile |
| `test/features/auth/auth_bloc_test.dart` | Auth Bloc |
| `test/features/cart/cart_bloc_test.dart` | Cart Bloc |

---

## 🗺️ Roadmap

- [x] Design system, branding, light / dark and RTL
- [x] Onboarding, authentication, storefront, search & filters
- [x] Cart, checkout, orders, notifications, settings
- [x] Node.js backend ([`vellora-api`](https://github.com/mohanad-2003/vellora-api), separate repository)
- [x] Flutter app connected to the backend (home, catalogue, product, auth, promo, orders, notifications)
- [ ] Payment gateway
- [ ] Localized product and notification text (the API returns English only)
- [ ] iOS and tablet / landscape verification on real devices

---

## 📄 License

This project is **private** and not published to pub.dev (`publish_to: none`).
All rights reserved © 2026.
