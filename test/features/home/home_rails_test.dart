import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/features/catalog/domain/catalog_filter.dart';
import 'package:vellora/features/home/domain/entities/product_entity.dart';
import 'package:vellora/features/home/domain/home_rails.dart';

ProductEntity _p(String id, String brand, double price, double rating,
        [int reviews = 0]) =>
    ProductEntity(
      id: id,
      name: id,
      brand: brand,
      imagePath: 'img_$id',
      price: price,
      rating: rating,
      reviewCount: reviews,
    );

void main() {
  final products = [
    _p('a', 'Nike', 120, 4.9, 10),
    _p('b', 'Nike', 20, 4.2),
    _p('c', 'Apple', 15, 4.6, 3),
    _p('d', 'Nike', 24, 4.6, 8),
    _p('e', 'Zara', 300, 3.9),
  ];

  test('top rated keeps 4.5+ ordered by rating then reviews', () {
    expect(HomeRails.topRated(products).map((p) => p.id), ['a', 'd', 'c']);
  });

  test('budget picks stay under the limit, best rated first', () {
    expect(
      HomeRails.budgetPicks(products, 25).map((p) => p.id),
      ['d', 'c', 'b'],
    );
  });

  test('brands are ranked by size and use their best product photo', () {
    final brands = HomeRails.brands(products);
    expect(brands.map((b) => b.name), ['Nike', 'Apple', 'Zara']);
    expect(brands.first.productCount, 3);
    expect(brands.first.imagePath, 'img_a');
  });

  test('union drops duplicates across rails', () {
    expect(
      HomeRails.union([
        [products[0], products[1]],
        [products[1], products[2]],
      ]).map((p) => p.id),
      ['a', 'b', 'c'],
    );
  });

  test('catalog collections match the Home rails', () {
    expect(
      CatalogCollection.topRated.apply(products).map((p) => p.id),
      ['a', 'd', 'c'],
    );
    expect(
      CatalogCollection.budgetPicks.apply(products).map((p) => p.id),
      ['d', 'c', 'b'],
    );
  });

  test('a brand filter narrows the catalog', () {
    const f = CatalogFilter(brands: {'Apple'});
    expect(f.apply(products).map((p) => p.id), ['c']);
  });
}
