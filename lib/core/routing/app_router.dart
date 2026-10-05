import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/create_new_password_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/password_reset_success_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/terms_privacy_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/cart/domain/entities/promo_code_entity.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/catalog/presentation/pages/search_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/order_success_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/language_select/presentation/pages/language_select_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/orders/domain/order_entity.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/product/presentation/pages/product_details_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/payment_methods_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/saved_addresses_page.dart';
import '../../features/profile/presentation/pages/security_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../di/injection.dart';
import '../widgets/not_found_page.dart';
import 'main_shell.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Central go_router configuration.
///
/// * Splash decides the real destination.
/// * The five main tabs (Home, Explore, Wishlist, Cart, Profile) live in a
///   [StatefulShellRoute.indexedStack], so each keeps its own state and scroll
///   position.
/// * Everything else (product, catalog, search, checkout, orders…) is pushed
///   on the root navigator, above the tab bar.
/// * Auth guarding is intentionally minimal: Home is meant to be browsable.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    observers: [_SnackbarDismissObserver()],
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: RouteNames.nSplash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.languageSelect,
        name: RouteNames.nLanguageSelect,
        pageBuilder: (_, state) => _fade(state, const LanguageSelectPage()),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: RouteNames.nOnboarding,
        pageBuilder: (_, state) => _fade(state, const OnboardingPage()),
      ),
      GoRoute(
        path: RouteNames.welcome,
        name: RouteNames.nWelcome,
        pageBuilder: (_, state) => _fade(state, const WelcomePage()),
      ),
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.nLogin,
        pageBuilder: (_, state) => _fade(state, const LoginPage()),
      ),
      GoRoute(
        path: RouteNames.register,
        name: RouteNames.nRegister,
        pageBuilder: (_, state) => _slide(state, const RegisterPage()),
      ),
      GoRoute(
        path: RouteNames.termsPrivacy,
        name: RouteNames.nTermsPrivacy,
        pageBuilder: (_, state) => _slide(state, const TermsPrivacyPage()),
      ),

      // Password-reset chain shares a single AuthBloc so pendingEmail /
      // resetToken persist across ForgotPassword → OTP → CreateNewPassword.
      ShellRoute(
        builder: (_, _, child) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: RouteNames.forgotPassword,
            name: RouteNames.nForgotPassword,
            pageBuilder: (_, state) =>
                _slide(state, const ForgotPasswordPage()),
          ),
          GoRoute(
            path: RouteNames.otpVerification,
            name: RouteNames.nOtpVerification,
            pageBuilder: (_, state) =>
                _slide(state, const OtpVerificationPage()),
          ),
          GoRoute(
            path: RouteNames.createNewPassword,
            name: RouteNames.nCreateNewPassword,
            pageBuilder: (_, state) =>
                _slide(state, const CreateNewPasswordPage()),
          ),
          GoRoute(
            path: RouteNames.passwordResetSuccess,
            name: RouteNames.nPasswordResetSuccess,
            pageBuilder: (_, state) =>
                _slide(state, const PasswordResetSuccessPage()),
          ),
        ],
      ),

      // ── Main tabs ──────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                name: RouteNames.nHome,
                builder: (_, _) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.explore,
                name: RouteNames.nExplore,
                builder: (_, _) => const ExplorePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.wishlist,
                name: RouteNames.nWishlist,
                builder: (_, _) => const WishlistPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.cart,
                name: RouteNames.nCart,
                builder: (_, _) => const CartPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                name: RouteNames.nProfile,
                builder: (_, _) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // ── Pushed over the tabs ───────────────────────────────────────────
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.product,
        name: RouteNames.nProduct,
        pageBuilder: (_, state) => _slide(
          state,
          ProductDetailsPage(
            productId: state.pathParameters['id'] ?? '',
            heroTag: state.extra is String ? state.extra as String : null,
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.catalog,
        name: RouteNames.nCatalog,
        pageBuilder: (_, state) {
          final args = state.extra as CatalogArgs?;
          return _slide(
            state,
            CatalogPage(
              title: args?.title ?? '',
              categoryId: args?.categoryId,
              collection: args?.collection,
              brand: args?.brand,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.search,
        name: RouteNames.nSearch,
        pageBuilder: (_, state) => _fade(
          state,
          SearchPage(
            args: state.extra is SearchArgs ? state.extra as SearchArgs : null,
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.checkout,
        name: RouteNames.nCheckout,
        pageBuilder: (_, state) => _slide(
          state,
          CheckoutPage(
            promo: state.extra is PromoCodeEntity
                ? state.extra as PromoCodeEntity
                : null,
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.orderSuccess,
        name: RouteNames.nOrderSuccess,
        // A confirmation without an order (deep link, restored state) makes no
        // sense — send the user home instead.
        redirect: (_, state) =>
            state.extra is OrderEntity ? null : RouteNames.home,
        pageBuilder: (_, state) => _fade(
          state,
          OrderSuccessPage(order: state.extra! as OrderEntity),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.orders,
        name: RouteNames.nOrders,
        pageBuilder: (_, state) => _slide(state, const OrdersPage()),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.orderDetails,
        name: RouteNames.nOrderDetails,
        pageBuilder: (_, state) => _slide(
          state,
          OrderDetailsPage(orderId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.notifications,
        name: RouteNames.nNotifications,
        pageBuilder: (_, state) => _slide(state, const NotificationsPage()),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.settings,
        name: RouteNames.nSettings,
        pageBuilder: (_, state) => _slide(state, const SettingsPage()),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.editProfile,
        name: RouteNames.nEditProfile,
        pageBuilder: (_, state) => _slide(
          state,
          EditProfilePage(
            user: state.extra is UserEntity ? state.extra as UserEntity : null,
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.savedAddresses,
        name: RouteNames.nSavedAddresses,
        pageBuilder: (_, state) => _slide(state, const SavedAddressesPage()),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.paymentMethods,
        name: RouteNames.nPaymentMethods,
        pageBuilder: (_, state) => _slide(state, const PaymentMethodsPage()),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RouteNames.security,
        name: RouteNames.nSecurity,
        pageBuilder: (_, state) => _slide(state, const SecurityPage()),
      ),
    ],
    errorBuilder: (_, _) => const NotFoundPage(),
  );

  static CustomTransitionPage<void> _fade(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  static CustomTransitionPage<void> _slide(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondary, child) {
        // Slides in from the end edge (mirrors in RTL) with a slight parallax
        // on the page underneath.
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final begin = Offset(isRtl ? -1 : 1, 0);
        final offset = Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final under = Tween<Offset>(
          begin: Offset.zero,
          end: Offset(isRtl ? 0.25 : -0.25, 0),
        ).animate(
          CurvedAnimation(parent: secondary, curve: Curves.easeOutCubic),
        );
        return SlideTransition(
          position: under,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }
}

/// Clears any visible snackbar when the user navigates, so a message raised on
/// one screen (e.g. "Added to cart") never lingers over the next one.
class _SnackbarDismissObserver extends NavigatorObserver {
  void _dismiss() {
    final context = navigator?.context;
    if (context == null) return;
    void hide() => ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    // Pages are pushed while the Navigator builds, and hiding a snackbar
    // rebuilds the ScaffoldMessenger: not allowed mid-build, so wait a frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => hide());
    } else {
      hide();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();
}
