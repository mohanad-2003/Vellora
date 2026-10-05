import 'package:equatable/equatable.dart';

import 'banner_entity.dart';
import 'brand_entity.dart';
import 'category_entity.dart';
import 'home_offer_entity.dart';
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
    this.topRated = const [],
    this.budgetPicks = const [],
    this.budgetLimit = defaultBudgetLimit,
    this.brands = const [],
    this.offers = const [],
    this.stats = const HomeStatsEntity(),
  });

  /// Price ceiling of [budgetPicks] when the server does not send one.
  static const double defaultBudgetLimit = 25;

  final List<BannerEntity> banners;
  final List<CategoryEntity> categories;
  final List<ProductEntity> featured;
  final List<ProductEntity> flashSale;
  final List<ProductEntity> newArrivals;
  final List<ProductEntity> bestSellers;
  final List<ProductEntity> recommended;
  final List<ProductEntity> topRated;
  final List<ProductEntity> budgetPicks;
  final double budgetLimit;
  final List<BrandEntity> brands;
  final List<HomeOfferEntity> offers;
  final HomeStatsEntity stats;

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
      topRated: mark(topRated),
      budgetPicks: mark(budgetPicks),
      budgetLimit: budgetLimit,
      brands: brands,
      offers: offers,
      stats: stats,
    );
  }

  @override
  List<Object?> get props => [
    banners,
    categories,
    featured,
    flashSale,
    newArrivals,
    bestSellers,
    recommended,
    topRated,
    budgetPicks,
    budgetLimit,
    brands,
    offers,
    stats,
  ];
}
