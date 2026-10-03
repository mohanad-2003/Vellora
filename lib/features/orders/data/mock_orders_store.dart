import 'package:injectable/injectable.dart';

import '../domain/order_entity.dart';

/// In-memory order history for the test-suite's `mock` DI environment. The
/// app itself uses the Vellora API (see `OrdersRemoteDataSource`).
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

  static List<OrderEntity> _seed() => [];
}
