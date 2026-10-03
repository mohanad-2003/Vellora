import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/environments.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_mappers.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/mock/mock_catalog.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../domain/entities/product_detail_entity.dart';
import '../../domain/entities/product_variant_entity.dart';
import '../../domain/entities/review_entity.dart';

/// Mocked product backend keyed by id. Throws [NotFoundException] on an unknown
/// id (or the reserved [AppConstants.unknownProductId]) so the error/retry UI
/// is reachable.
abstract class ProductRemoteDataSource {
  Future<ProductDetailEntity> getProductDetails(String id);
  Future<List<ProductEntity>> getRelatedProducts(String id);
}

@mockOnly
@LazySingleton(as: ProductRemoteDataSource)
class MockProductRemoteDataSource implements ProductRemoteDataSource {
  @override
  Future<ProductDetailEntity> getProductDetails(String id) async {
    await Future<void>.delayed(AppConstants.mockDelay);

    final base = MockCatalog.byId[id];
    if (base == null || id == AppConstants.unknownProductId) {
      throw const NotFoundException('Product not found');
    }

    return ProductDetailEntity(
      product: base,
      gallery: _galleryFor(base),
      description:
          '${base.brand} presents the ${base.name} — crafted from premium '
          'materials with meticulous attention to detail. Designed for '
          'everyday comfort and a timeless, versatile look that pairs with '
          'anything in your wardrobe.',
      variant: _variantFor(base),
      reviews: _reviewsFor(base),
      inStock: true,
    );
  }

  @override
  Future<List<ProductEntity>> getRelatedProducts(String id) async {
    await Future<void>.delayed(AppConstants.mockShortDelay);
    final base = MockCatalog.byId[id];
    if (base == null) return const [];
    return MockCatalog.products
        .where((p) => p.category == base.category && p.id != id)
        .take(6)
        .toList();
  }

  List<String> _galleryFor(ProductEntity p) {
    // Base shot + a few complementary shots from the same category. The mock
    // catalog has a single photo per product; a real API returns the gallery.
    final extras = MockCatalog.products
        .where((o) => o.category == p.category && o.id != p.id)
        .map((o) => o.imagePath)
        .take(3);
    return [p.imagePath, ...extras];
  }

  ProductVariantEntity _variantFor(ProductEntity p) {
    switch (p.category) {
      case 'shoes':
        return const ProductVariantEntity(
          colors: ['Black', 'White', 'Red', 'Navy'],
          sizes: ['39', '40', '41', '42', '43', '44', '45'],
        );
      case 'men':
      case 'women':
        return const ProductVariantEntity(
          colors: ['Black', 'Sand', 'Navy', 'Olive'],
          sizes: ['XS', 'S', 'M', 'L', 'XL'],
        );
      case 'accessories':
        return const ProductVariantEntity(
          colors: ['Black', 'Sand', 'Navy'],
          sizes: [],
        );
      default:
        // Electronics, beauty, grocery: no apparel variants.
        return const ProductVariantEntity(colors: [], sizes: []);
    }
  }

  List<ReviewEntity> _reviewsFor(ProductEntity p) {
    return [
      ReviewEntity(
        author: 'Sarah M.',
        rating: 5,
        comment: 'Absolutely love it — exactly as pictured and great quality.',
        timeAgo: '2 days ago',
      ),
      ReviewEntity(
        author: 'James K.',
        rating: 4,
        comment: 'Solid value for the price. Fits true to size.',
        timeAgo: '1 week ago',
      ),
      ReviewEntity(
        author: 'Aisha R.',
        rating: p.rating >= 4.5 ? 5 : 4,
        comment: 'Shipped fast and looks premium. Would buy again.',
        timeAgo: '3 weeks ago',
      ),
    ];
  }
}

@apiOnly
@LazySingleton(as: ProductRemoteDataSource)
class ApiProductRemoteDataSource implements ProductRemoteDataSource {
  ApiProductRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<ProductDetailEntity> getProductDetails(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.productDetails(id),
    );
    final j = res.data!;
    final variant = j['variant'] as Map<String, dynamic>;
    return ProductDetailEntity(
      product: ApiMappers.product(j['product'] as Map<String, dynamic>),
      gallery: [for (final g in j['gallery'] as List) g as String],
      description: j['description'] as String,
      variant: ProductVariantEntity(
        colors: [for (final c in variant['colors'] as List) c as String],
        sizes: [for (final s in variant['sizes'] as List) s as String],
      ),
      reviews: [
        for (final r in j['reviews'] as List)
          ApiMappers.review(r as Map<String, dynamic>),
      ],
      inStock: (j['product'] as Map<String, dynamic>)['inStock'] as bool? ??
          true,
    );
  }

  @override
  Future<List<ProductEntity>> getRelatedProducts(String id) async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.relatedProducts(id));
    return ApiMappers.products(res.data);
  }
}
