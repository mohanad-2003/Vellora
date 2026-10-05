import 'package:equatable/equatable.dart';

/// A brand shown in Home's "Top brands" strip.
class BrandEntity extends Equatable {
  const BrandEntity({
    required this.name,
    required this.imagePath,
    this.productCount = 0,
  });

  final String name;

  /// Photo of the brand's best-rated product.
  final String imagePath;
  final int productCount;

  @override
  List<Object?> get props => [name, imagePath, productCount];
}
