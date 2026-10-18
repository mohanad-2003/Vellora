import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/product/presentation/widgets/product_actions_bar.dart';

/// The purchase bar on glass: the total, Add to Cart, Buy Now, and the sold-out
/// version, on narrow phones and with large text.
void main() {
  var added = 0;
  var bought = 0;
  var asked = 0;

  setUp(() {
    added = 0;
    bought = 0;
    asked = 0;
  });

  Future<void> show(
    WidgetTester tester, {
    bool inStock = true,
    double? price = 129.9,
    double? original,
    VoidCallback? onStockAlert,
    bool stockAlert = false,
    Size size = const Size(390, 800),
    double textScale = 1,
    bool dark = false,
    Locale locale = const Locale('en'),
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
                const Positioned.fill(child: ColoredBox(color: Colors.white)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ProductActionsBar(
                    inStock: inStock,
                    price: price,
                    originalPrice: original,
                    onAddToCart: () => added++,
                    onBuyNow: () => bought++,
                    stockAlert: stockAlert,
                    onStockAlert: onStockAlert,
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

  testWidgets('shows the total and both actions', (tester) async {
    await show(tester, original: 159.9);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('\$129.90'), findsOneWidget);
    expect(find.text('\$159.90'), findsOneWidget, reason: 'the struck price');
    expect(find.text('Buy Now'), findsOneWidget);
    expect(find.bySemanticsLabel('Add to Cart'), findsOneWidget);
  });

  testWidgets('Buy Now and Add to Cart call back', (tester) async {
    await show(tester);
    await tester.tap(find.text('Buy Now'));
    await tester.tap(find.byIcon(Icons.add_shopping_cart_rounded));
    expect([bought, added], [1, 1]);
  });

  testWidgets('without a price the block is left out', (tester) async {
    await show(tester, price: null);
    expect(find.text('Total'), findsNothing);
    expect(find.text('Buy Now'), findsOneWidget);
  });

  testWidgets('sold out offers to notify, then to cancel', (tester) async {
    await show(tester, inStock: false, onStockAlert: () => asked++);
    expect(find.text('Notify me when available'), findsOneWidget);
    expect(find.text('Buy Now'), findsNothing);
    await tester.tap(find.text('Notify me when available'));
    expect(asked, 1);
    await show(
      tester,
      inStock: false,
      stockAlert: true,
      onStockAlert: () => asked++,
    );
    expect(find.text('Cancel notification'), findsOneWidget);
  });

  testWidgets('sold out with no alert wired disables the purchase', (
    tester,
  ) async {
    await show(tester, inStock: false);
    await tester.tap(find.text('Buy Now'));
    await tester.tap(find.byIcon(Icons.add_shopping_cart_rounded));
    expect([bought, added], [0, 0]);
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
                size: size,
                textScale: scale,
                dark: dark,
                locale: locale,
                original: 1999.99,
                price: 1299.99,
              );
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
