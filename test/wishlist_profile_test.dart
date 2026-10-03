import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vellora/core/di/environments.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/localization/locale_cubit.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/core/theme/theme_cubit.dart';
import 'package:vellora/features/product/domain/repositories/favorites_repository.dart';
import 'package:vellora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:vellora/features/profile/presentation/pages/profile_page.dart';
import 'package:vellora/features/wishlist/presentation/pages/wishlist_page.dart';

/// Renders the new Wishlist and Profile screens at multiple viewport aspect
/// ratios (portrait phone, short-wide desktop, landscape phone) in both light
/// and dark themes, and asserts none overflow — targeting the RenderFlex bug
/// class that broke prior phases. Also exercises Wishlist removal and the
/// ProfileCubit logout flow against the real DI graph.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStore = <String, String>{};
  late Directory hiveDir;

  setUpAll(() async {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'write':
          secureStore[key!] = args['value'] as String;
          return null;
        case 'read':
          return secureStore[key];
        case 'readAll':
          return Map<String, String>.from(secureStore);
        case 'delete':
          secureStore.remove(key);
          return null;
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'containsKey':
          return secureStore.containsKey(key);
        default:
          return null;
      }
    });

    hiveDir = await Directory.systemTemp.createTemp('hive_wishlist_test');
    Hive.init(hiveDir.path);
    SharedPreferences.setMockInitialValues({});
    await configureDependencies(environment: mockEnv);
  });

  tearDownAll(() async {
    // Box watchers created inside the fake-async test zone can never finish
    // closing, so don't wait on them forever.
    await Hive.deleteFromDisk().timeout(
      const Duration(seconds: 2),
      onTimeout: () => <void>[],
    );
    try {
      await hiveDir.delete(recursive: true);
    } catch (_) {}
    await sl.reset();
  });

  Widget harness(Widget page, {ThemeMode themeMode = ThemeMode.light}) {
    return Builder(
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: sl<LocaleCubit>()),
          BlocProvider.value(value: sl<ThemeCubit>()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: const Locale('en'),
          supportedLocales: LocaleCubit.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: page,
        ),
      ),
    );
  }

  final sizes = <(String, Size)>[
    ('phone-portrait', const Size(375, 812)),
    ('desktop-short-wide', const Size(1280, 560)),
    ('landscape-phone', const Size(740, 360)),
  ];

  Future<void> clearFavorites() async {
    final ids = sl<FavoritesRepository>().getFavoriteIds().getOrElse((_) => {});
    for (final id in ids) {
      await sl<FavoritesRepository>().toggle(id);
    }
  }

  Future<void> seedFavorites() async {
    await clearFavorites();
    for (final id in ['p1', 'p3', 'p6', 'nike1', 'sh1']) {
      await sl<FavoritesRepository>().toggle(id);
    }
  }

  for (final (sizeName, size) in sizes) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final themeName = mode == ThemeMode.dark ? 'dark' : 'light';

      testWidgets('Wishlist (seeded) no overflow @ $sizeName/$themeName',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // Unmount so listeners (e.g. Hive box watchers) are released.
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

        await tester.runAsync(seedFavorites);
        await tester.pumpWidget(
          harness(const WishlistPage(), themeMode: mode),
        );
        // Products load through the (mock) catalogue, which has latency.
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull,
            reason: 'Wishlist grid overflowed at $sizeName/$themeName');
      });

      testWidgets('Wishlist (empty) no overflow @ $sizeName/$themeName',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // Unmount so listeners (e.g. Hive box watchers) are released.
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

        await tester.runAsync(clearFavorites);
        await tester.pumpWidget(
          harness(const WishlistPage(), themeMode: mode),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull,
            reason: 'Wishlist empty state overflowed at $sizeName/$themeName');
      });

      testWidgets('Profile no overflow @ $sizeName/$themeName',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // Unmount so listeners (e.g. Hive box watchers) are released.
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

        await tester.pumpWidget(
          harness(const ProfilePage(), themeMode: mode),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull,
            reason: 'Profile overflowed at $sizeName/$themeName');
      });
    }
  }

  testWidgets('Wishlist removal empties the list', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
        // Unmount so listeners (e.g. Hive box watchers) are released.
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

    await tester.runAsync(() async {
      await clearFavorites();
      await sl<FavoritesRepository>().toggle('p1');
    });

    await tester.pumpWidget(harness(const WishlistPage()));
    // Products load through the (mock) catalogue, which has latency.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));

    // The seeded product renders.
    expect(find.text('Graphic Pullover Hoodie'), findsOneWidget);

    // Tap its favorite (heart) toggle to remove it.
    await tester.tap(find.byIcon(Icons.favorite_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Empty state now shows.
    expect(find.text('Your wishlist is empty'), findsOneWidget);
  });

  testWidgets('ProfileCubit logout emits loggedOut', (tester) async {
    final cubit = sl<ProfileCubit>();
    await cubit.loadUser();
    expect(cubit.state.status, ProfileStatus.loaded);

    // Signing out clears Hive boxes, which is real disk IO.
    await tester.runAsync(cubit.logout);
    expect(cubit.state.status, ProfileStatus.loggedOut);
    await cubit.close();
  });
}
