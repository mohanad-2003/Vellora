import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/core/widgets/cart_flight.dart';
import 'package:vellora/features/product/presentation/widgets/product_actions_bar.dart';

/// On the product page the picture flies into the Add to Cart button of the
/// purchase bar.
void main() {
  final addKey = GlobalKey();
  BuildContext? pageContext;

  Future<void> show(WidgetTester tester, {bool reduceMotion = false}) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 800),
          disableAnimations: reduceMotion,
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                pageContext = context;
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ProductActionsBar(
                        inStock: true,
                        price: 99,
                        addKey: addKey,
                        onAddToCart: () {},
                        onBuyNow: () {},
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the bar marks its Add to Cart button as the landing spot', (
    tester,
  ) async {
    await show(tester);
    final rect = CartFlight.rectOf(addKey);
    expect(rect, isNotNull);
    expect(rect!.width, 52);
    expect(rect.bottom, lessThan(800));
  });

  testWidgets('the flight lands, then its picture is gone', (tester) async {
    await show(tester);
    var landed = false;
    CartFlight.fly(
      pageContext!,
      from: const Rect.fromLTWH(150, 200, 56, 56),
      to: CartFlight.rectOf(addKey)!,
      imagePath: '',
    ).then((_) => landed = true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(landed, isFalse);
    expect(find.byType(ClipOval), findsWidgets);
    await tester.pumpAndSettle();
    expect(landed, isTrue);
  });

  testWidgets('with reduced motion there is no flight', (tester) async {
    await show(tester, reduceMotion: true);
    var landed = false;
    CartFlight.fly(
      pageContext!,
      from: const Rect.fromLTWH(150, 200, 56, 56),
      to: CartFlight.rectOf(addKey)!,
      imagePath: '',
    ).then((_) => landed = true);
    await tester.pump();
    expect(landed, isTrue);
  });
}
