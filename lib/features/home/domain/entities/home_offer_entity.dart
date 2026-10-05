import 'package:equatable/equatable.dart';

/// A promo code advertised on Home ("Coupons for you").
class HomeOfferEntity extends Equatable {
  const HomeOfferEntity({required this.code, required this.discountPercent});

  final String code;
  final double discountPercent;

  @override
  List<Object?> get props => [code, discountPercent];
}

/// Catalogue totals shown in Home's highlights strip.
class HomeStatsEntity extends Equatable {
  const HomeStatsEntity({
    this.productCount = 0,
    this.brandCount = 0,
    this.categoryCount = 0,
  });

  final int productCount;
  final int brandCount;
  final int categoryCount;

  bool get isEmpty => productCount == 0;

  @override
  List<Object?> get props => [productCount, brandCount, categoryCount];
}
