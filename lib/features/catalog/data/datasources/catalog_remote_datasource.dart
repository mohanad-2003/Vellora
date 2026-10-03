import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:vellora/core/constants/app_constants.dart';
import 'package:vellora/core/di/environments.dart';
import 'package:vellora/core/network/api_endpoints.dart';
import 'package:vellora/core/network/api_mappers.dart';
import 'package:vellora/core/mock/mock_catalog.dart';
import 'package:vellora/features/home/domain/entities/product_entity.dart';


/// Mocked catalog backend backed by the shared [MockCatalog]. A real
/// datasource would translate these into API calls with query params.
abstract class CatalogRemoteDataSource {
  Future<List<ProductEntity>> getProducts({String? categoryId, String? query});

  /// Products for the given ids (unknown ids are skipped), in catalogue order.
  Future<List<ProductEntity>> getProductsByIds(List<String> ids);
}

@mockOnly
@LazySingleton(as: CatalogRemoteDataSource)
class MockCatalogRemoteDataSource implements CatalogRemoteDataSource {
  @override
  Future<List<ProductEntity>> getProducts({
    String? categoryId,
    String? query,
  }) async {
    await Future<void>.delayed(AppConstants.mockShortDelay);

    var products = MockCatalog.products;

    if (categoryId != null && categoryId.isNotEmpty) {
      products =
          products.where((p) => p.category == categoryId).toList(growable: false);
    }

    final q = query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList(growable: false);
    }

    return products;
  }

  @override
  Future<List<ProductEntity>> getProductsByIds(List<String> ids) async {
    await Future<void>.delayed(AppConstants.mockShortDelay);
    return [
      for (final p in MockCatalog.products)
        if (ids.contains(p.id)) p,
    ];
  }
}

@apiOnly
@LazySingleton(as: CatalogRemoteDataSource)
class ApiCatalogRemoteDataSource implements CatalogRemoteDataSource {
  ApiCatalogRemoteDataSource(this._dio);

  final Dio _dio;

  /// The app filters and sorts locally, so it needs the whole result set; the
  /// API pages at 100 items.
  Future<List<ProductEntity>> _fetchAll(Map<String, dynamic> query) async {
    final all = <ProductEntity>[];
    var page = 1;
    while (true) {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.products,
        queryParameters: {...query, 'limit': 100, 'page': page},
      );
      all.addAll(ApiMappers.products(res.data!['items']));
      final totalPages = (res.data!['totalPages'] as num).toInt();
      if (page >= totalPages) return all;
      page++;
    }
  }

  @override
  Future<List<ProductEntity>> getProducts({
    String? categoryId,
    String? query,
  }) {
    return _fetchAll({
      if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    });
  }

  @override
  Future<List<ProductEntity>> getProductsByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(const []);
    return _fetchAll({'ids': ids.join(',')});
  }
}
