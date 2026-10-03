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

  /// Marks the order cancelled and returns it, or null when it is unknown or
  /// already past processing.
  OrderEntity? cancel(String id) {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i < 0 || _orders[i].status != OrderStatus.processing) return null;
    return _orders[i] = _orders[i].copyWith(status: OrderStatus.cancelled);
  }

  /// Newest first.
  void add(OrderEntity order) => _orders.insert(0, order);

  static List<OrderEntity> _seed() => [];
}
