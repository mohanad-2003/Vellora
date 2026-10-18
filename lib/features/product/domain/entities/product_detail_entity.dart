import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/product_entity.dart';
import 'product_variant_entity.dart';
import 'review_entity.dart';

/// Full product detail: the base [ProductEntity] plus gallery, description,
/// variants and reviews.
class ProductDetailEntity extends Equatable {
  const ProductDetailEntity({
    required this.product,
    required this.gallery,
    required this.description,
    required this.variant,
    required this.reviews,
    this.inStock = true,
    this.stockAlert = false,
  });

  final ProductEntity product;
  final List<String> gallery;
  final String description;
  final ProductVariantEntity variant;
  final List<ReviewEntity> reviews;
  final bool inStock;

  /// The signed-in shopper asked to be told when this sold-out product returns.
  final bool stockAlert;

  ProductDetailEntity copyWith({ProductEntity? product, bool? stockAlert}) =>
      ProductDetailEntity(
    product: product ?? this.product,
    gallery: gallery,
    description: description,
    variant: variant,
    reviews: reviews,
    inStock: inStock,
    stockAlert: stockAlert ?? this.stockAlert,
  );

  @override
  List<Object?> get props => [
    product,
    gallery,
    description,
    variant,
    reviews,
    inStock,
    stockAlert,
  ];
}
