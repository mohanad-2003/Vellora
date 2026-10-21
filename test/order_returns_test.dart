import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/network/api_mappers.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/notifications/data/notifications_remote_datasource.dart';
import 'package:vellora/features/notifications/domain/notification_entity.dart';
import 'package:vellora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:vellora/features/orders/data/orders_remote_datasource.dart';
import 'package:vellora/features/orders/domain/order_entity.dart';
import 'package:vellora/features/orders/domain/return_entity.dart';
import 'package:vellora/features/orders/presentation/widgets/order_returns.dart';

class _FakeOrders extends Fake implements OrdersRemoteDataSource {
  final List<ReturnEntity> returns = [];
  Map<String, int>? asked;
  String? askedReason;

  @override
  Future<List<ReturnEntity>> getReturns() async => List.of(returns);

  @override
  Future<ReturnEntity> requestReturn(
    String orderId,
    Map<String, int> quantities, {
    required String reason,
    String? note,
  }) async {
    asked = quantities;
    askedReason = reason;
    final made = ReturnEntity(
      id: '1',
      orderId: orderId,
      status: ReturnStatus.requested,
      reason: reason,
      createdAt: DateTime(2026, 10, 20),
      items: [
        for (final e in quantities.entries)
          ReturnItemEntity(orderItemId: e.key, name: 'Linen shirt', quantity: e.value),
      ],
    );
    returns.add(made);
    return made;
  }
}

class _FakeNotifications extends Fake implements NotificationsRemoteDataSource {
  @override
  Future<List<NotificationEntity>> getNotifications() async => const [];
}

OrderEntity _order(OrderStatus status) => OrderEntity(
  id: 'o1',
  number: '#VL-1',
  createdAt: DateTime(2026, 10, 18),
  status: status,
  items: const [
    OrderItemEntity(id: '7', name: 'Linen shirt', imagePath: '', quantity: 2, price: 50),
  ],
  subtotal: 100,
  discount: 0,
  shipping: 0,
  total: 100,
  recipient: 'Omar',
  addressLine: 'street 30',
  city: 'Paris',
  paymentKind: OrderPaymentKind.cashOnDelivery,
  paymentDetail: '',
);

Widget _app(Widget child, Locale locale) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  late _FakeOrders orders;

  setUp(() async {
    await sl.reset();
    orders = _FakeOrders();
    sl.registerSingleton<OrdersRemoteDataSource>(orders);
    sl.registerSingleton<UnreadNotificationsCubit>(
      UnreadNotificationsCubit(_FakeNotifications()),
    );
  });
  tearDown(() => sl.reset());

  test('the API payload becomes a return, and an order line keeps its id', () {
    final ret = ApiMappers.orderReturn({
      'id': '5',
      'orderId': 'o1',
      'status': 'approved',
      'reason': 'Wrong size',
      'adminNote': 'Use the prepaid label',
      'createdAt': '2026-10-20T10:00:00.000Z',
      'items': [
        {'orderItemId': '7', 'name': 'Linen shirt', 'quantity': 1},
      ],
    });
    expect(ret.status, ReturnStatus.approved);
    expect(ret.adminNote, 'Use the prepaid label');
    expect(ret.items.single.quantity, 1);
    expect(ret.holdsItems, isTrue);
  });

  testWidgets('a delivered order can be returned, and the request is shown', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(OrderReturnsSection(order: _order(OrderStatus.delivered)), const Locale('en')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Return items'));
    await tester.pumpAndSettle();
    // Nothing chosen yet: the send button is off.
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Send return request')).onPressed, isNull);
    await tester.tap(find.byTooltip('Increase'));
    await tester.pump();
    await tester.ensureVisible(find.text('Damaged or faulty'));
    await tester.tap(find.text('Damaged or faulty'));
    await tester.pump();
    await tester.ensureVisible(find.text('Send return request'));
    await tester.pump();
    await tester.tap(find.text('Send return request'));
    await tester.pumpAndSettle();

    expect(orders.asked, {'7': 1});
    expect(orders.askedReason, 'Damaged or faulty');
    expect(find.text('Waiting for review'), findsOneWidget);
    expect(find.text('1 × Linen shirt'), findsOneWidget);
    // One of the two units is left to return.
    expect(find.text('Return items'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nothing shows for an order that is not delivered', (tester) async {
    await tester.pumpWidget(_app(OrderReturnsSection(order: _order(OrderStatus.shipped)), const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('إرجاع منتجات'), findsNothing);
  });
}
