import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/core/widgets/vellora_nav_bar.dart';

/// The floating bottom bar: the chosen destination opens with its name, the
/// others are icons, and it fits every phone width and text size.
void main() {
  List<NavDestinationItem> items({int cart = 0, bool dot = false}) => [
    const NavDestinationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    const NavDestinationItem(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
      label: 'Explore',
    ),
    NavDestinationItem(
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
      label: 'Cart',
      badgeCount: cart,
    ),
    NavDestinationItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
      showDot: dot,
    ),
  ];

  Future<void> show(
    WidgetTester tester, {
    required int index,
    ValueChanged<int>? onSelected,
    Size size = const Size(390, 800),
    double textScale = 1,
    bool dark = false,
    Locale locale = const Locale('en'),
    List<NavDestinationItem>? navItems,
    bool settle = true,
  }) async {
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
          home: Scaffold(
            bottomNavigationBar: VelloraNavBar(
              items: navItems ?? items(),
              currentIndex: index,
              onSelected: onSelected ?? (_) {},
            ),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('only the chosen destination shows its name', (tester) async {
    await show(tester, index: 1);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Cart'), findsNothing);
    expect(find.text('Profile'), findsNothing);
    // The chosen one is the filled icon, the rest are outlines.
    expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
  });

  testWidgets('tapping another destination reports its index', (tester) async {
    final taps = <int>[];
    await show(tester, index: 0, onSelected: taps.add);
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    expect(taps, [2, 3]);
  });

  testWidgets('a count is shown on its icon', (tester) async {
    await show(tester, index: 0, navItems: items(cart: 3, dot: true));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('the cart badge pulses when the count grows', (tester) async {
    await show(tester, index: 0, navItems: items(cart: 1));
    await show(tester, index: 0, navItems: items(cart: 2), settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-animation the badge is scaled up; it settles back.
    final scale = tester.widget<ScaleTransition>(
      find.descendant(
        of: find.byType(PulseOnChange),
        matching: find.byType(ScaleTransition),
      ),
    );
    expect(scale.scale.value, greaterThan(1.0));
    await tester.pumpAndSettle();
    expect(scale.scale.value, closeTo(1.0, 0.001));
  });

  for (final (name, size) in [
    ('320', const Size(320, 640)),
    ('360', const Size(360, 740)),
    ('412', const Size(412, 915)),
    ('600', const Size(600, 900)),
  ]) {
    for (final scale in [1.0, 1.4]) {
      for (final dark in [false, true]) {
        for (final locale in const [Locale('en'), Locale('ar')]) {
          final mode = dark ? 'dark' : 'light';
          testWidgets(
            'fits $name wide, text x$scale, $mode, ${locale.languageCode}',
            (tester) async {
              await show(
                tester,
                index: 3,
                size: size,
                textScale: scale,
                dark: dark,
                locale: locale,
                navItems: items(cart: 120, dot: true),
              );
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
