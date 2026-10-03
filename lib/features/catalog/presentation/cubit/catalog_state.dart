part of 'catalog_cubit.dart';

enum CatalogStatus { initial, loading, loaded, empty, error }

class CatalogState extends Equatable {
  const CatalogState({
    this.status = CatalogStatus.initial,
    this.products = const [],
    this.baseProducts = const [],
    this.query = '',
    this.failureKey,
    this.filter = CatalogFilter.empty,
    this.sort = CatalogSort.relevance,
  });

  final CatalogStatus status;

  /// What is shown: [baseProducts] after filter and sort.
  final List<ProductEntity> products;

  /// The unfiltered result of the last query — the source of filter options
  /// (brands, price range).
  final List<ProductEntity> baseProducts;
  final String query;
  final String? failureKey;
  final CatalogFilter filter;
  final CatalogSort sort;

  /// Full price range of [baseProducts], rounded outward, for the slider.
  (double, double) get priceBounds {
    if (baseProducts.isEmpty) return (0, 100);
    var lo = baseProducts.first.price;
    var hi = lo;
    for (final p in baseProducts) {
      if (p.price < lo) lo = p.price;
      if (p.price > hi) hi = p.price;
    }
    return (lo.floorToDouble(), hi.ceilToDouble());
  }

  List<String> get brands =>
      ({for (final p in baseProducts) p.brand}.toList()..sort());

  CatalogState copyWith({
    CatalogStatus? status,
    List<ProductEntity>? products,
    List<ProductEntity>? baseProducts,
    String? query,
    String? failureKey,
    CatalogFilter? filter,
    CatalogSort? sort,
  }) {
    return CatalogState(
      status: status ?? this.status,
      products: products ?? this.products,
      baseProducts: baseProducts ?? this.baseProducts,
      query: query ?? this.query,
      failureKey: failureKey,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props =>
      [status, products, baseProducts, query, failureKey, filter, sort];
}
