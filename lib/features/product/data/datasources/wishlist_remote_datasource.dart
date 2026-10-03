import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/di/environments.dart';
import '../../../../core/network/api_endpoints.dart';

/// The signed-in user's wishlist on the server. Product ids only: the products
/// themselves come from the catalogue.
abstract class WishlistRemoteDataSource {
  Future<Set<String>> getIds();
  Future<void> add(String productId);
  Future<void> remove(String productId);
}

@mockOnly
@LazySingleton(as: WishlistRemoteDataSource)
class MockWishlistRemoteDataSource implements WishlistRemoteDataSource {
  final Set<String> _ids = {};

  @override
  Future<Set<String>> getIds() async => Set.of(_ids);

  @override
  Future<void> add(String productId) async => _ids.add(productId);

  @override
  Future<void> remove(String productId) async => _ids.remove(productId);
}

@apiOnly
@LazySingleton(as: WishlistRemoteDataSource)
class ApiWishlistRemoteDataSource implements WishlistRemoteDataSource {
  ApiWishlistRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Set<String>> getIds() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.wishlist);
    return {
      for (final p in res.data!) (p as Map<String, dynamic>)['id'] as String,
    };
  }

  @override
  Future<void> add(String productId) async {
    await _dio.put<void>(ApiEndpoints.wishlistItem(productId));
  }

  @override
  Future<void> remove(String productId) async {
    await _dio.delete<void>(ApiEndpoints.wishlistItem(productId));
  }
}
