import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vellora/features/cart/domain/entities/cart_summary_entity.dart';
import 'package:vellora/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:vellora/features/cart/presentation/widgets/free_shipping_progress.dart';
import 'package:vellora/features/cart/presentation/widgets/glass_total_bar.dart';
import 'package:vellora/features/cart/presentation/widgets/price_summary_card.dart';

/// The cart in the glass identity: item cards, the free-shipping card, the
/// summary card and the floating total bar, on narrow phones, large text, dark
/// mode and Arabic.
void main() {
  const item = CartItemEntity(
    id: 'p1-Black-M',
    productId: 'p1',
    name: 'Cashmere overcoat with a very long product name that wraps',
    imagePath: '',
    price: 249.5,
    quantity: 2,
    color: 'Black',
    size: 'M',
  );
  const summary = CartSummaryEntity(
    subtotal: 499,
    discount: 49.9,
    shipping: 0,
    total: 449.1,
    itemCount: 2,
  );

  var tapped = 0;

  setUp(() => tapped = 0);

  Future<void> show(
    WidgetTester tester, {
    Size size = const Size(390, 800),
    double textScale = 1,
    bool dark = false,
    Locale locale = const Locale('en'),
    double subtotal = 60,
    VoidCallback? onPressed,
    bool loading = false,
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
            body: Stack(
              children: [
                Positioned.fill(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      FreeShippingProgress(subtotal: subtotal),
                      const SizedBox(height: 16),
                      CartItemTile(
                        item: item,
                        onQuantityChanged: (_) {},
                        onRemoved: () {},
                      ),
                      const SizedBox(height: 16),
                      const PriceSummaryCard(summary: summary),
                      const SizedBox(height: GlassTotalBar.clearance),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GlassTotalBar(
                    total: 449.1,
                    savings: 49.9,
                    label: 'Checkout',
                    icon: Icons.arrow_forward_rounded,
                    loading: loading,
                    onPressed: onPressed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the bar shows the total and Checkout fires', (tester) async {
    await show(tester, onPressed: () => tapped++);
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Total'), findsWidgets);
    await tester.tap(find.text('Checkout'));
    expect(tapped, 1);
  });

  testWidgets('the bar is inert while loading or without an action', (
    tester,
  ) async {
    await show(tester, onPressed: () => tapped++, loading: true);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(GlassTotalBar));
    expect(tapped, 0);

    await show(tester);
    await tester.tap(find.text('Checkout'));
    expect(tapped, 0);
  });

  testWidgets('free shipping unlocks past the threshold', (tester) async {
    await show(tester, subtotal: 150);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  for (final size in const [Size(320, 640), Size(360, 740), Size(412, 900)]) {
    for (final scale in const [1.0, 1.4]) {
      for (final dark in const [false, true]) {
        for (final locale in const [Locale('en'), Locale('ar')]) {
          testWidgets(
            'no overflow ${size.width.toInt()}px x$scale '
            '${dark ? 'dark' : 'light'} ${locale.languageCode}',
            (tester) async {
              await show(
                tester,
                size: size,
                textScale: scale,
                dark: dark,
                locale: locale,
                onPressed: () {},
              );
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
