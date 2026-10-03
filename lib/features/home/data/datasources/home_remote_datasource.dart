import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/environments.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_mappers.dart';
import '../../../../core/mock/mock_catalog.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/home_data_entity.dart';
import '../../domain/entities/product_entity.dart';

/// Mocked home backend. Builds the home payload from the shared [MockCatalog]
/// with a simulated delay. A real datasource would deserialize JSON models.
abstract class HomeRemoteDataSource {
  Future<HomeDataEntity> getHomeData();
}

@mockOnly
@LazySingleton(as: HomeRemoteDataSource)
class MockHomeRemoteDataSource implements HomeRemoteDataSource {
  @override
  Future<HomeDataEntity> getHomeData() async {
    await Future<void>.delayed(AppConstants.mockDelay);

    final products = MockCatalog.products;

    double discount(ProductEntity p) =>
        p.hasDiscount ? (p.originalPrice! - p.price) / p.originalPrice! : 0;

    final flashSale = products.where((p) => p.hasDiscount).toList()
      ..sort((a, b) => discount(b).compareTo(discount(a)));
    final bestSellers = [...products]
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    final featured = products.where((p) => p.rating >= 4.7).toList();
    final newArrivals = products.reversed.toList();
    // Deterministic "for you" slice — every third item, so it differs from the
    // other rails without needing randomness (keeps tests stable).
    final recommended = [
      for (var i = 0; i < products.length; i += 2) products[i],
    ];

    return HomeDataEntity(
      banners: _banners,
      categories: _categories(products),
      featured: featured.take(8).toList(),
      flashSale: flashSale.take(8).toList(),
      newArrivals: newArrivals.take(8).toList(),
      bestSellers: bestSellers.take(8).toList(),
      recommended: recommended.take(10).toList(),
    );
  }

  static List<CategoryEntity> _categories(List<ProductEntity> products) {
    int count(String id) => products.where((p) => p.category == id).length;
    return [
      CategoryEntity(
        id: 'men',
        name: 'Men',
        imagePath: '',
        productCount: count('men'),
      ),
      CategoryEntity(
        id: 'women',
        name: 'Women',
        imagePath: '',
        productCount: count('women'),
      ),
      CategoryEntity(
        id: 'shoes',
        name: 'Shoes',
        imagePath: '',
        productCount: count('shoes'),
      ),
      CategoryEntity(
        id: 'accessories',
        name: 'Accessories',
        imagePath: '',
        productCount: count('accessories'),
      ),
      CategoryEntity(
        id: 'beauty',
        name: 'Beauty',
        imagePath: '',
        productCount: count('beauty'),
      ),
      CategoryEntity(
        id: 'electronics',
        name: 'Electronics',
        imagePath: '',
        productCount: count('electronics'),
      ),
      CategoryEntity(
        id: 'grocery',
        name: 'Grocery',
        imagePath: '',
        productCount: count('grocery'),
      ),
    ];
  }

  static const List<BannerEntity> _banners = [
    BannerEntity(
      id: 'summer',
      title: 'Summer Collection',
      subtitle: 'Up to 50% off selected styles',
      imagePath: '',
    ),
    BannerEntity(
      id: 'flash',
      title: 'Flash Sale',
      subtitle: 'Ends soon — grab it fast',
      imagePath: '',
    ),
    BannerEntity(
      id: 'new',
      title: 'New Arrivals',
      subtitle: 'Fresh drops every week',
      imagePath: '',
    ),
  ];
}

@apiOnly
@LazySingleton(as: HomeRemoteDataSource)
class ApiHomeRemoteDataSource implements HomeRemoteDataSource {
  ApiHomeRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<HomeDataEntity> getHomeData() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.home);
    final j = res.data!;
    return HomeDataEntity(
      banners: [
        for (final b in j['banners'] as List)
          ApiMappers.banner(b as Map<String, dynamic>),
      ],
      categories: [
        for (final c in j['categories'] as List)
          ApiMappers.category(c as Map<String, dynamic>),
      ],
      featured: ApiMappers.products(j['featured']),
      flashSale: ApiMappers.products(j['flashSale']),
      newArrivals: ApiMappers.products(j['newArrivals']),
      bestSellers: ApiMappers.products(j['bestSellers']),
      recommended: ApiMappers.products(j['recommended']),
    );
  }
}
