import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/localization/l10n/app_localizations.dart';
import 'core/localization/locale_cubit.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_names.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/presentation/bloc/user_session_cubit.dart';
import 'features/cart/presentation/bloc/cart_badge_cubit.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';

class VelloraApp extends StatelessWidget {
  const VelloraApp({super.key});

  /// Largest text scale the layouts are designed and tested for. System text
  /// settings are honoured up to this value.
  static const double maxTextScale = 1.6;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<ThemeCubit>()),
        BlocProvider.value(value: sl<LocaleCubit>()),
        BlocProvider.value(value: sl<CartBadgeCubit>()),
        BlocProvider.value(value: sl<UserSessionCubit>()),
        BlocProvider.value(value: sl<UnreadNotificationsCubit>()..refresh()),
      ],
      // A different user (or a log out) means a different notification feed.
      child: BlocListener<UserSessionCubit, SessionUser?>(
        listener: (context, session) {
          context.read<UnreadNotificationsCubit>().refresh();
          // The session ended without the user asking (expired token): the
          // auth interceptor cleared it, so send them to sign in again.
          if (session == null) AppRouter.router.go(RouteNames.login);
        },
        listenWhen: (prev, curr) => prev != curr,
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return BlocBuilder<LocaleCubit, Locale>(
              builder: (context, locale) {
                return MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  title: AppConstants.appName,
                  theme: AppTheme.forLocale(Brightness.light, locale),
                  darkTheme: AppTheme.forLocale(Brightness.dark, locale),
                  themeMode: themeMode,
                  locale: locale,
                  supportedLocales: LocaleCubit.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  builder: (context, child) {
                    final mq = MediaQuery.of(context);
                    return MediaQuery(
                      data: mq.copyWith(
                        textScaler: mq.textScaler.clamp(
                          minScaleFactor: 1,
                          maxScaleFactor: maxTextScale,
                        ),
                      ),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                  routerConfig: AppRouter.router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
