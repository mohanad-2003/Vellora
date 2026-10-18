import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/core/widgets/cart_added_chip.dart';
import 'package:vellora/core/widgets/cart_flight.dart';
import 'package:vellora/core/widgets/vellora_nav_bar.dart';
import 'package:vellora/features/cart/presentation/bloc/cart_badge_cubit.dart';

/// Adding from a card: the picture flies to the cart icon, then a chip says what
/// the cart holds and offers "View cart"; it goes away by itself.
void main() {
  late Box box;
  late CartBadgeCubit cubit;

  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('chip_test').path);
    box = await Hive.openBox('chip_test_cart');
  });

  setUp(() async {
    await box.clear();
    await box.put('a', jsonEncode({'price': 100.0, 'quantity': 2, 'id': 'a'}));
    await box.put('b', jsonEncode({'price': 50.5, 'quantity': 1, 'id': 'b'}));
    cubit = CartBadgeCubit(box);
    CartFlight.added.value = null;
    CartFlight.pending = null;
  });

  tearDown(() => cubit.close());

  test('the cart total is price times quantity over every line', () {
    expect(cubit.total, closeTo(250.5, 0.001));
    expect(cubit.state, 3);
  });

  var opened = 0;
  BuildContext? appContext;

  Future<void> show(
    WidgetTester tester, {
    bool withBar = true,
    bool keyed = false,
    bool hidden = false,
    Size size = const Size(390, 800),
    double textScale = 1,
    Locale locale = const Locale('en'),
    bool dark = false,
  }) async {
    opened = 0;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(
              extendBody: true,
              body: Builder(
                builder: (context) {
                  appContext = context;
                  return Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 90,
                        child: CartAddedChip(
                          hidden: hidden,
                          onViewCart: () => opened++,
                        ),
                      ),
                    ],
                  );
                },
              ),
              bottomNavigationBar: withBar
                  ? VelloraNavBar(
                      currentIndex: 0,
                      onSelected: (_) {},
                      items: [
                        const NavDestinationItem(
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home_rounded,
                          label: 'Home',
                        ),
                        NavDestinationItem(
                          icon: Icons.shopping_bag_outlined,
                          selectedIcon: Icons.shopping_bag_rounded,
                          label: 'Cart',
                          badgeCount: 3,
                          iconKey: keyed ? CartFlight.navCartKey : null,
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('no bar on screen: nothing is done, the caller shows its own', (
    tester,
  ) async {
    await show(tester, withBar: false);
    expect(
      CartFlight.announce(appContext!, name: 'Watch', imagePath: ''),
      isFalse,
    );
    await tester.pump();
    expect(find.text('View cart'), findsNothing);
  });

  testWidgets('a picture flies to the cart icon, then the chip rises', (
    tester,
  ) async {
    await show(tester, keyed: true);
    CartFlight.pending = const FlightSource(
      rect: Rect.fromLTWH(40, 120, 44, 44),
      imagePath: '',
    );
    expect(
      CartFlight.announce(appContext!, name: 'Watch', imagePath: ''),
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('View cart'), findsNothing, reason: 'still flying');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('View cart'), findsOneWidget);
    expect(CartFlight.pending, isNull);
  });

  testWidgets('the chip shows what the cart holds and opens it', (
    tester,
  ) async {
    await show(tester);
    // Stands in for the bar's cart icon.
    CartFlight.added.value = const CartAdded(name: 'Watch', imagePath: '');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Added to your cart'), findsOneWidget);
    expect(find.textContaining('3 items'), findsOneWidget);
    await tester.tap(find.text('View cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, 1);
    expect(find.text('View cart'), findsNothing, reason: 'it goes away');
  });

  testWidgets('it leaves by itself, and not while the cart is open', (
    tester,
  ) async {
    await show(tester);
    CartFlight.added.value = const CartAdded(name: 'Watch', imagePath: '');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('View cart'), findsOneWidget);
    await tester.pump(CartAddedChip.stays + const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('View cart'), findsNothing);

    await show(tester, hidden: true);
    CartFlight.added.value = const CartAdded(name: 'Watch', imagePath: '');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('View cart'), findsNothing);
  });

  for (final size in const [Size(320, 640), Size(360, 740)]) {
    for (final dark in const [false, true]) {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        testWidgets('chip fits ${size.width.toInt()}px x1.4 '
            '${dark ? 'dark' : 'light'} ${locale.languageCode}', (
          tester,
        ) async {
          await show(
            tester,
            size: size,
            textScale: 1.4,
            dark: dark,
            locale: locale,
          );
          CartFlight.added.value = const CartAdded(
            name: 'A watch with a very long name indeed',
            imagePath: '',
          );
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
