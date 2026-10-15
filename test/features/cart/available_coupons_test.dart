import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/cart/domain/entities/coupon_offer_entity.dart';
import 'package:vellora/features/cart/presentation/widgets/available_coupons.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

const _offers = [
  CouponOfferEntity(code: 'SAVE20', discountPercent: 20, minSubtotal: 100),
  CouponOfferEntity(code: 'WELCOME', discountPercent: 12.5, firstOrderOnly: true),
];

void main() {
  testWidgets('lists the coupons with what they need, and applies one on a tap', (tester) async {
    final applied = <String>[];
    await tester.pumpWidget(_host(
      AvailableCoupons(onApply: applied.add, load: () async => _offers),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Available coupons'), findsOneWidget);
    expect(find.text('SAVE20'), findsOneWidget);
    expect(find.text('20% off · Spend \$100.00+'), findsOneWidget);
    expect(find.text('12.5% off · First order'), findsOneWidget);

    await tester.tap(find.text('SAVE20'));
    expect(applied, ['SAVE20']);
  });

  testWidgets('leaves out the code that is already applied', (tester) async {
    await tester.pumpWidget(_host(
      AvailableCoupons(onApply: (_) {}, exclude: 'SAVE20', load: () async => _offers),
    ));
    await tester.pumpAndSettle();

    expect(find.text('SAVE20'), findsNothing);
    expect(find.text('WELCOME'), findsOneWidget);
  });

  testWidgets('shows nothing when there are none or they cannot be fetched', (tester) async {
    await tester.pumpWidget(_host(AvailableCoupons(onApply: (_) {}, load: () async => const [])));
    await tester.pumpAndSettle();
    expect(find.text('Available coupons'), findsNothing);

    await tester.pumpWidget(_host(
      AvailableCoupons(onApply: (_) {}, load: () async => throw Exception('offline')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Available coupons'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reads in Arabic', (tester) async {
    await tester.pumpWidget(_host(
      AvailableCoupons(onApply: (_) {}, load: () async => _offers),
      locale: const Locale('ar'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('كوبونات متاحة'), findsOneWidget);
    expect(find.textContaining('خصم 20%'), findsOneWidget);
  });
}
