import 'package:equatable/equatable.dart';

import '../../home/domain/entities/product_entity.dart';

/// Curated lists reachable from Home ("See all", banners).
enum CatalogCollection { flashSale, featured, newArrivals, bestSellers }

extension CatalogCollectionX on CatalogCollection {
  /// Narrows and orders [all] to this collection. Mirrors how the Home data
  /// source builds its rails so "See all" matches what the user just saw.
  List<ProductEntity> apply(List<ProductEntity> all) {
    double discount(ProductEntity p) =>
        p.hasDiscount ? (p.originalPrice! - p.price) / p.originalPrice! : 0;
    switch (this) {
      case CatalogCollection.flashSale:
        return all.where((p) => p.hasDiscount).toList()
          ..sort((a, b) => discount(b).compareTo(discount(a)));
      case CatalogCollection.featured:
        return all.where((p) => p.rating >= 4.7).toList();
      case CatalogCollection.newArrivals:
        return all.reversed.toList();
      case CatalogCollection.bestSellers:
        return [...all]..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
  }
}

enum CatalogSort { relevance, priceLowHigh, priceHighLow, topRated }

extension CatalogSortX on CatalogSort {
  List<ProductEntity> apply(List<ProductEntity> products) {
    switch (this) {
      case CatalogSort.relevance:
        return products;
      case CatalogSort.priceLowHigh:
        return [...products]..sort((a, b) => a.price.compareTo(b.price));
      case CatalogSort.priceHighLow:
        return [...products]..sort((a, b) => b.price.compareTo(a.price));
      case CatalogSort.topRated:
        return [...products]..sort((a, b) => b.rating.compareTo(a.rating));
    }
  }
}

/// User-selected narrowing of a product list. Immutable; an empty filter
/// matches everything.
///
/// Size, colour and availability filters are intentionally absent: the product
/// list entity carries none of that data (it lives on the details payload), and
/// a filter that cannot be honoured would be fake. They slot in here once the
/// API exposes them.
class CatalogFilter extends Equatable {
  const CatalogFilter({
    this.categories = const {},
    this.brands = const {},
    this.minPrice,
    this.maxPrice,
    this.minRating = 0,
    this.onSaleOnly = false,
  });

  static const CatalogFilter empty = CatalogFilter();

  final Set<String> categories;
  final Set<String> brands;
  final double? minPrice;
  final double? maxPrice;
  final double minRating;
  final bool onSaleOnly;

  bool get hasPrice => minPrice != null || maxPrice != null;

  /// Number of independent constraints applied (for the filter badge).
  int get activeCount =>
      (categories.isNotEmpty ? 1 : 0) +
      (brands.isNotEmpty ? 1 : 0) +
      (hasPrice ? 1 : 0) +
      (minRating > 0 ? 1 : 0) +
      (onSaleOnly ? 1 : 0);

  bool get isActive => activeCount > 0;

  bool matches(ProductEntity p) {
    if (categories.isNotEmpty && !categories.contains(p.category)) return false;
    if (brands.isNotEmpty && !brands.contains(p.brand)) return false;
    if (minPrice != null && p.price < minPrice!) return false;
    if (maxPrice != null && p.price > maxPrice!) return false;
    if (p.rating < minRating) return false;
    if (onSaleOnly && !p.hasDiscount) return false;
    return true;
  }

  List<ProductEntity> apply(List<ProductEntity> products) =>
      isActive ? products.where(matches).toList() : products;

  CatalogFilter copyWith({
    Set<String>? categories,
    Set<String>? brands,
    double? minPrice,
    double? maxPrice,
    bool clearPrice = false,
    double? minRating,
    bool? onSaleOnly,
  }) {
    return CatalogFilter(
      categories: categories ?? this.categories,
      brands: brands ?? this.brands,
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: minRating ?? this.minRating,
      onSaleOnly: onSaleOnly ?? this.onSaleOnly,
    );
  }

  @override
  List<Object?> get props =>
      [categories, brands, minPrice, maxPrice, minRating, onSaleOnly];
}
