import '../../features/home/domain/entities/product_entity.dart';

/// Tiny product fixture for the test-suite's `mock` DI environment.
///
/// The app itself never uses it: real products and photos come from the Vellora
/// API. Photos are intentionally empty so no image assets are needed (the UI
/// shows its placeholder).
class MockCatalog {
  MockCatalog._();

  static ProductEntity _p(
    String id,
    String name,
    String brand,
    String category,
    double price, {
    double? originalPrice,
    double rating = 4.5,
    int reviewCount = 100,
  }) =>
      ProductEntity(
        id: id,
        name: name,
        brand: brand,
        imagePath: '',
        price: price,
        originalPrice: originalPrice,
        rating: rating,
        reviewCount: reviewCount,
        category: category,
      );

  static final List<ProductEntity> products = [
    _p('p1', 'Graphic Pullover Hoodie', 'Urbanist', 'men', 59,
        originalPrice: 79, rating: 4.6, reviewCount: 214),
    _p('p2', 'Star Print Casual Shirt', 'Cotton & Co', 'men', 34.5,
        rating: 4.3, reviewCount: 98),
    _p('p3', 'Satin Slip Dress', 'Maison Lune', 'women', 74.5,
        originalPrice: 99, rating: 4.8, reviewCount: 342),
    _p('p4', 'Tiered Maxi Dress', 'Maison Lune', 'women', 89,
        rating: 4.5, reviewCount: 121),
    _p('p6', 'Satin Top & Denim Shorts Set', 'Bloom', 'women', 54,
        rating: 4.2, reviewCount: 63),
    _p('p7', 'Court Air Sneakers', 'Stride', 'shoes', 119,
        originalPrice: 149, rating: 4.7, reviewCount: 289),
    _p('sh1', 'Dunk Low Retro', 'Nike', 'shoes', 99,
        originalPrice: 120, rating: 4.7, reviewCount: 341),
    _p('nike1', 'Air Jordan 1 High', 'Nike', 'shoes', 134.99,
        originalPrice: 160, rating: 4.9, reviewCount: 508),
    _p('m4', 'Steel Grey Analog Watch', 'Titan Edge', 'accessories', 129,
        rating: 4.6, reviewCount: 89),
    _p('m7', 'Matte Red Lipstick', 'Glow Lab', 'beauty', 18,
        originalPrice: 24, rating: 4.6, reviewCount: 455),
    _p('p8', 'Smartphone', 'realme', 'electronics', 279,
        originalPrice: 329, rating: 4.6, reviewCount: 431),
    _p('p14', 'Instant Hot Chocolate', 'Cocoa House', 'grocery', 9.5,
        rating: 4.6, reviewCount: 118),
  ];

  static final Map<String, ProductEntity> byId = {
    for (final p in products) p.id: p,
  };

  static List<ProductEntity> byCategory(String category) =>
      products.where((p) => p.category == category).toList();
}
