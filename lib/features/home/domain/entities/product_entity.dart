import 'package:equatable/equatable.dart';

/// Core product shape established by Home and reused by Product & Cart.
class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.brand,
    required this.imagePath,
    required this.price,
    this.originalPrice,
    this.rating = 0,
    this.reviewCount = 0,
    this.category = '',
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String brand;
  final String imagePath;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final String category;
  final bool isFavorite;

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  ProductEntity copyWith({bool? isFavorite}) => ProductEntity(
        id: id,
        name: name,
        brand: brand,
        imagePath: imagePath,
        price: price,
        originalPrice: originalPrice,
        rating: rating,
        reviewCount: reviewCount,
        category: category,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        brand,
        imagePath,
        price,
        originalPrice,
        rating,
        reviewCount,
        category,
        isFavorite,
      ];
}
