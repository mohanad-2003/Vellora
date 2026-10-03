import 'package:injectable/injectable.dart';

import '../../../core/constants/asset_paths.dart';
import '../domain/order_entity.dart';

/// **Mock data.** In-memory order history standing in for an orders API.
///
/// Seeded with a few sample orders so the Orders screens have content, and
/// extended with every order placed during the session. Nothing is persisted:
/// the history resets when the app restarts. Replace this class (not the UI)
/// with a repository backed by the real API.
@lazySingleton
class MockOrdersStore {
  MockOrdersStore() : _orders = _seed();

  final List<OrderEntity> _orders;

  Future<List<OrderEntity>> getOrders() async {
    // Brief latency so loading states are exercised, like a real request.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return List.unmodifiable(_orders);
  }

  Future<OrderEntity?> getOrder(String id) async {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Newest first.
  void add(OrderEntity order) => _orders.insert(0, order);

  static List<OrderEntity> _seed() {
    final now = DateTime.now();
    return [
      OrderEntity(
        id: 'o-20418',
        number: '#SH-20418',
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        status: OrderStatus.shipped,
        items: const [
          OrderItemEntity(
            name: 'Dunk Low Retro',
            imagePath: AssetPaths.sneakersStreetOrange,
            quantity: 1,
            price: 99,
            color: 'White',
            size: '42',
          ),
          OrderItemEntity(
            name: 'Graphic Pullover Hoodie',
            imagePath: AssetPaths.hoodieBlack,
            quantity: 1,
            price: 59,
            color: 'Black',
            size: 'L',
          ),
        ],
        subtotal: 158,
        discount: 0,
        shipping: 0,
        total: 158,
        recipient: 'Alex Johnson',
        addressLine: '24 Maple Avenue, Apt 5B',
        city: 'San Francisco, CA 94103',
        paymentKind: OrderPaymentKind.card,
        paymentDetail: 'Visa •••• 4242',
      ),
      OrderEntity(
        id: 'o-20377',
        number: '#SH-20377',
        createdAt: now.subtract(const Duration(days: 9)),
        status: OrderStatus.delivered,
        items: const [
          OrderItemEntity(
            name: 'Matte Red Lipstick',
            imagePath: AssetPaths.lipstickRed,
            quantity: 2,
            price: 18,
          ),
        ],
        subtotal: 36,
        discount: 0,
        shipping: 9.99,
        total: 45.99,
        recipient: 'Alex Johnson',
        addressLine: '900 Market Street, Floor 7',
        city: 'San Francisco, CA 94102',
        paymentKind: OrderPaymentKind.paypal,
        paymentDetail: 'PayPal',
      ),
      OrderEntity(
        id: 'o-20211',
        number: '#SH-20211',
        createdAt: now.subtract(const Duration(days: 21)),
        status: OrderStatus.cancelled,
        items: const [
          OrderItemEntity(
            name: 'Steel Grey Analog Watch',
            imagePath: AssetPaths.watchSteelGrey,
            quantity: 1,
            price: 129,
          ),
        ],
        subtotal: 129,
        discount: 0,
        shipping: 0,
        total: 129,
        recipient: 'Alex Johnson',
        addressLine: '24 Maple Avenue, Apt 5B',
        city: 'San Francisco, CA 94103',
        paymentKind: OrderPaymentKind.cashOnDelivery,
        paymentDetail: '',
      ),
    ];
  }
}
