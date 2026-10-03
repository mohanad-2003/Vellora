import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/di/environments.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_mappers.dart';
import '../domain/order_entity.dart';
import '../domain/place_order_request.dart';
import 'mock_orders_store.dart';

/// Order history and checkout. Needs a signed-in user when talking to the API.
abstract class OrdersRemoteDataSource {
  Future<List<OrderEntity>> getOrders();

  /// Throws [NotFoundException] when the order does not exist.
  Future<OrderEntity> getOrder(String id);

  Future<OrderEntity> placeOrder(PlaceOrderRequest request);
}

@mockOnly
@LazySingleton(as: OrdersRemoteDataSource)
class MockOrdersRemoteDataSource implements OrdersRemoteDataSource {
  MockOrdersRemoteDataSource(this._store);

  final MockOrdersStore _store;

  @override
  Future<List<OrderEntity>> getOrders() => _store.getOrders();

  @override
  Future<OrderEntity> getOrder(String id) async {
    final order = await _store.getOrder(id);
    if (order == null) throw const NotFoundException('Order not found');
    return order;
  }

  @override
  Future<OrderEntity> placeOrder(PlaceOrderRequest request) async {
    // Simulate payment authorization / order creation latency.
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    _store.add(request.preview);
    return request.preview;
  }
}

@apiOnly
@LazySingleton(as: OrdersRemoteDataSource)
class ApiOrdersRemoteDataSource implements OrdersRemoteDataSource {
  ApiOrdersRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<OrderEntity>> getOrders() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.orders);
    return [
      for (final o in res.data!) ApiMappers.order(o as Map<String, dynamic>),
    ];
  }

  @override
  Future<OrderEntity> getOrder(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.order(id));
    return ApiMappers.order(res.data!);
  }

  @override
  Future<OrderEntity> placeOrder(PlaceOrderRequest r) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.orders,
      data: {
        'items': [
          for (final i in r.items)
            {
              'productId': i.productId,
              'quantity': i.quantity,
              if (i.color != null) 'color': i.color,
              if (i.size != null) 'size': i.size,
            },
        ],
        if (r.promoCode != null) 'promoCode': r.promoCode,
        'delivery': r.express ? 'express' : 'standard',
        'address': {
          'recipient': r.recipient,
          if (r.phone != null) 'phone': r.phone,
          'line': r.addressLine,
          'city': r.city,
        },
        'payment': {
          'kind': switch (r.paymentKind) {
            OrderPaymentKind.card => 'card',
            OrderPaymentKind.paypal => 'paypal',
            OrderPaymentKind.cashOnDelivery => 'cashOnDelivery',
          },
          'detail': r.paymentDetail,
        },
      },
    );
    return ApiMappers.order(res.data!);
  }
}
