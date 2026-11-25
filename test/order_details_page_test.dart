import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/orders/data/orders_remote_datasource.dart';
import 'package:vellora/features/orders/domain/order_entity.dart';
import 'package:vellora/features/orders/domain/return_entity.dart';
import 'package:vellora/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:vellora/features/orders/presentation/pages/order_details_page.dart';

class _Orders extends Fake implements OrdersRemoteDataSource {
  _Orders(this.order);

  final OrderEntity order;

  @override
  Future<OrderEntity> getOrder(String id) async => order;

  @override
  Future<List<ReturnEntity>> getReturns() async => [];
}

OrderEntity _order(OrderStatus status) => OrderEntity(
  id: 'order-1',
  number: '#VL-20418',
  createdAt: DateTime(2026, 10, 20, 12),
  status: status,
  items: const [
    OrderItemEntity(
      name: 'قميص كتان بأكمام طويلة / Long sleeve linen shirt',
      imagePath: '',
      quantity: 2,
      price: 50,
      color: 'black',
      size: 'XL',
    ),
  ],
  subtotal: 100,
  discount: 10,
  shipping: 0,
  total: 90,
  recipient: 'سارة أحمد / Sara Ahmad',
  addressLine: 'شارع طويل، مبنى ١٢، الطابق الثالث / Building 12, third floor',
  city: 'الخليل / Hebron',
  paymentKind: OrderPaymentKind.cashOnDelivery,
  paymentDetail: '',
);

void main() {
  tearDown(() => sl.reset());

  for (final locale in ['ar', 'en']) {
    for (final status in OrderStatus.values) {
      testWidgets('$locale $status fits a narrow screen with large text', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final remote = _Orders(_order(status));
        sl.registerSingleton<OrdersRemoteDataSource>(remote);
        sl.registerFactory<OrderDetailCubit>(() => OrderDetailCubit(remote));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.forLocale(Brightness.light, Locale(locale)),
            darkTheme: AppTheme.forLocale(Brightness.dark, Locale(locale)),
            themeMode: locale == 'ar' ? ThemeMode.dark : ThemeMode.light,
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: const OrderDetailsPage(orderId: 'order-1'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('#VL-20418'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Walk the whole page so lazy sections also get layout validation.
        for (var i = 0; i < 12; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -350));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        final l10n = AppLocalizations.of(
          tester.element(find.byType(OrderDetailsPage)),
        );
        expect(
          find.text(l10n.cancelOrder),
          status == OrderStatus.processing ? findsOneWidget : findsNothing,
        );
      });
    }
  }
}
