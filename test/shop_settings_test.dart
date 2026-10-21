import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/shipping/shipping_rules.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vellora/features/cart/domain/entities/cart_summary_entity.dart';
import 'package:vellora/features/checkout/data/delivery_remote_datasource.dart';
import 'package:vellora/features/profile/presentation/widgets/help_sheet.dart';

class _FakeDelivery extends Fake implements DeliveryRemoteDataSource {
  _FakeDelivery(this.info);

  final StoreInfo? info;

  @override
  Future<StoreInfo?> getStoreInfo() async => info;
}

CartItemEntity _item(double price) => CartItemEntity(
  id: 'a',
  productId: 'a',
  name: 'Shirt',
  imagePath: '',
  price: price,
  quantity: 1,
);

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  tearDown(() async {
    ShippingRules.update(freeThreshold: 100, standardFee: 9.99);
    await sl.reset();
  });

  test(
    'the bag follows the shop\'s shipping rules, and free starts at the threshold',
    () {
      expect(CartSummaryEntity.from([_item(100)], null).shipping, 0);
      expect(CartSummaryEntity.from([_item(99)], null).shipping, 9.99);

      ShippingRules.update(freeThreshold: 50, standardFee: 4);
      expect(CartSummaryEntity.from([_item(49)], null).shipping, 4);
      expect(CartSummaryEntity.from([_item(50)], null).shipping, 0);
      expect(CartSummaryEntity.from(const [], null).shipping, 0);
    },
  );

  testWidgets('help shows the contacts the owner set', (tester) async {
    await sl.reset();
    sl.registerSingleton<DeliveryRemoteDataSource>(
      _FakeDelivery(
        const StoreInfo(
          name: 'Vellora',
          supportEmail: 'help@shop.test',
          supportPhone: '+962 7 0000 0000',
        ),
      ),
    );
    await tester.pumpWidget(_app(const HelpSheet()));
    await tester.pumpAndSettle();
    expect(find.text('help@shop.test'), findsOneWidget);
    expect(find.text('+962 7 0000 0000'), findsOneWidget);
  });

  testWidgets(
    'help falls back to the built-in address when the server cannot say',
    (tester) async {
      await sl.reset();
      sl.registerSingleton<DeliveryRemoteDataSource>(_FakeDelivery(null));
      await tester.pumpWidget(_app(const HelpSheet()));
      await tester.pumpAndSettle();
      expect(find.text('support@vellora.com'), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsNothing);
    },
  );
}
