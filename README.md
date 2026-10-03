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

> **There is no backend yet.** Data comes from in-memory mocks
> ([`lib/core/mock/mock_catalog.dart`](lib/core/mock/mock_catalog.dart)) and local
> storage (Hive, SharedPreferences, secure storage). The data layer is built so a real
> API can replace the mocks without touching the UI.

---

## ✨ Features

| Area | Highlights |
|------|-----------|
| 🌐 **Language gate** | First-launch English / Arabic choice, applied live (the screen flips to RTL instantly) |
| 🚀 **Onboarding** | Immersive full-bleed pages with parallax, skip / next flow |
| 🔐 **Authentication** | Welcome, Login, Sign Up (with password-strength meter), Forgot Password, 4-digit OTP, new password, success |
| 🏠 **Home** | Promo banners, categories, curated product rows, countdown deals |
| 🧭 **Explore & Search** | Category browsing, search with sort and filter sheet |
| 📦 **Product details** | Gallery, size / colour variants, reviews, related products |
| ❤️ **Wishlist** | Favourite products synced across every screen |
| 🛒 **Cart & Checkout** | Quantity control, live totals, delivery methods, order success |
| 🧾 **Orders** | Order history and details (mock store) |
| 🔔 **Notifications** | Notification centre (mock) |
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
│   ├── mock/                 # Mock catalogue data
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
| **Networking (ready, unused by mocks)** | `dio`, `retrofit`, `pretty_dio_logger` |
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

flutter pub get
dart run build_runner build --delete-conflicting-outputs   # DI, freezed, json
flutter gen-l10n                                           # localizations
flutter run
```

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
- [ ] Backend API integration (currently mock-driven)
- [ ] Payment gateway
- [ ] Localized mock content (orders, notifications and product copy are English-only)
- [ ] iOS and tablet / landscape verification on real devices

---

## 📄 License

This project is **private** and not published to pub.dev (`publish_to: none`).
All rights reserved © 2026.
