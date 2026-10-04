import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/environments.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/cart_item_model.dart';

/// The signed-in user's cart on the server. The app keeps the bag locally and
/// mirrors it here, so it follows the account across devices.
abstract class CartRemoteDataSource {
  Future<List<CartItemModel>> getItems();

  /// Replaces the server cart with [items] and returns it as the server holds it
  /// (current prices, unknown products dropped).
  Future<List<CartItemModel>> replaceItems(List<CartItemModel> items);
}

/// Cart id for a product + variant, the same format the product page uses.
String cartItemId(String productId, String? color, String? size) =>
    '${productId}_${color ?? ''}_${size ?? ''}';

@mockOnly
@LazySingleton(as: CartRemoteDataSource)
class MockCartRemoteDataSource implements CartRemoteDataSource {
  List<CartItemModel> _items = const [];

  @override
  Future<List<CartItemModel>> getItems() async => _items;

  @override
  Future<List<CartItemModel>> replaceItems(List<CartItemModel> items) async =>
      _items = List.of(items);
}

@apiOnly
@LazySingleton(as: CartRemoteDataSource)
class ApiCartRemoteDataSource implements CartRemoteDataSource {
  ApiCartRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<CartItemModel>> getItems() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.cart);
    return _parse(res.data!);
  }

  @override
  Future<List<CartItemModel>> replaceItems(List<CartItemModel> items) async {
    final res = await _dio.put<Map<String, dynamic>>(
      ApiEndpoints.cart,
      data: {
        'items': [
          for (final i in items)
            {
              'productId': i.productId,
              'quantity': i.quantity.clamp(1, AppConstants.maxLineQuantity),
              if (i.color != null) 'color': i.color,
              if (i.size != null) 'size': i.size,
            },
        ],
      },
    );
    return _parse(res.data!);
  }

  List<CartItemModel> _parse(Map<String, dynamic> json) {
    return [
      for (final raw in json['items'] as List) _item(raw as Map<String, dynamic>),
    ];
  }

  CartItemModel _item(Map<String, dynamic> j) {
    final color = j['color'] as String?;
    final size = j['size'] as String?;
    return CartItemModel(
      id: cartItemId(j['productId'] as String, color, size),
      productId: j['productId'] as String,
      name: j['name'] as String,
      imagePath: j['imageUrl'] as String,
      price: (j['price'] as num).toDouble(),
      quantity: (j['quantity'] as num).toInt(),
      color: color,
      size: size,
    );
  }
}
