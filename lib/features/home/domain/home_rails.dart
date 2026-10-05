import 'entities/brand_entity.dart';
import 'entities/product_entity.dart';

/// Builds the extra Home rails (top rated, budget picks, brands) from a product
/// list. The mock backend uses it on the whole catalogue; the API datasource
/// falls back to it when an older server does not send these rails yet.
class HomeRails {
  HomeRails._();

  static int _byRating(ProductEntity a, ProductEntity b) {
    final r = b.rating.compareTo(a.rating);
    return r != 0 ? r : b.reviewCount.compareTo(a.reviewCount);
  }

  /// Highly rated products, best first.
  static List<ProductEntity> topRated(List<ProductEntity> products) =>
      products.where((p) => p.rating >= 4.5).toList()..sort(_byRating);

  /// Products at or under [limit], best rated first.
  static List<ProductEntity> budgetPicks(
    List<ProductEntity> products,
    double limit,
  ) => products.where((p) => p.price <= limit).toList()..sort(_byRating);

  /// Brands ranked by how many products they have; each shows its best-rated
  /// product's photo.
  static List<BrandEntity> brands(List<ProductEntity> products) {
    final counts = <String, int>{};
    final top = <String, ProductEntity>{};
    for (final p in products) {
      if (p.brand.trim().isEmpty) continue;
      counts[p.brand] = (counts[p.brand] ?? 0) + 1;
      final best = top[p.brand];
      if (best == null || _byRating(p, best) < 0) top[p.brand] = p;
    }
    final names = counts.keys.toList()
      ..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        return c != 0 ? c : a.compareTo(b);
      });
    return [
      for (final n in names)
        BrandEntity(
          name: n,
          imagePath: top[n]!.imagePath,
          productCount: counts[n]!,
        ),
    ];
  }

  /// Every distinct product across [lists], first occurrence wins.
  static List<ProductEntity> union(Iterable<List<ProductEntity>> lists) {
    final seen = <String>{};
    return [
      for (final list in lists)
        for (final p in list)
          if (seen.add(p.id)) p,
    ];
  }
}
