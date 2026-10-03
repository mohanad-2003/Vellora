import 'package:equatable/equatable.dart';

import 'banner_entity.dart';
import 'category_entity.dart';
import 'product_entity.dart';

/// Aggregate of everything the Home screen renders in one shot.
class HomeDataEntity extends Equatable {
  const HomeDataEntity({
    required this.banners,
    required this.categories,
    required this.featured,
    required this.flashSale,
    required this.newArrivals,
    required this.bestSellers,
    this.recommended = const [],
  });

  final List<BannerEntity> banners;
  final List<CategoryEntity> categories;
  final List<ProductEntity> featured;
  final List<ProductEntity> flashSale;
  final List<ProductEntity> newArrivals;
  final List<ProductEntity> bestSellers;
  final List<ProductEntity> recommended;

  HomeDataEntity withFavorites(Set<String> favoriteIds) {
    List<ProductEntity> mark(List<ProductEntity> list) => list
        .map((p) => p.copyWith(isFavorite: favoriteIds.contains(p.id)))
        .toList();
    return HomeDataEntity(
      banners: banners,
      categories: categories,
      featured: mark(featured),
      flashSale: mark(flashSale),
      newArrivals: mark(newArrivals),
      bestSellers: mark(bestSellers),
      recommended: mark(recommended),
    );
  }

  @override
  List<Object?> get props =>
      [
        banners,
        categories,
        featured,
        flashSale,
        newArrivals,
        bestSellers,
        recommended,
      ];
}
