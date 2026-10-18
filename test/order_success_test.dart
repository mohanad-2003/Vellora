import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/checkout/presentation/pages/order_success_page.dart';
import 'package:vellora/features/orders/domain/order_entity.dart';

/// The order confirmation: champagne mark, the order facts on the page, and
/// both actions, on narrow phones with large text, in both modes and languages.
void main() {
  final order = OrderEntity(
    id: 'o1',
    number: 'VL-100245',
    createdAt: DateTime(2026, 10, 18),
    status: OrderStatus.processing,
    items: const [],
    subtotal: 499,
    discount: 0,
    shipping: 0,
    total: 499,
    recipient: 'Omar',
    addressLine: 'street 30',
    city: 'Paris',
    paymentKind: OrderPaymentKind.cashOnDelivery,
    paymentDetail: '',
  );

  for (final size in const [Size(320, 568), Size(360, 740), Size(412, 900)]) {
    for (final dark in const [false, true]) {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        testWidgets(
          'order success ${size.width.toInt()}px x1.4 '
          '${dark ? 'dark' : 'light'} ${locale.languageCode}',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(1.4),
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
                  home: OrderSuccessPage(order: order),
                ),
              ),
            );
            await tester.pump(const Duration(seconds: 1));
            expect(find.text('VL-100245'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
