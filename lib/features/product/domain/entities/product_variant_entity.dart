import 'package:equatable/equatable.dart';

/// Available variant options for a product (colours + sizes).
class ProductVariantEntity extends Equatable {
  const ProductVariantEntity({required this.colors, required this.sizes});

  /// Colour labels (e.g. "Black", "Sand"). Hex is derived in the UI layer.
  final List<String> colors;
  final List<String> sizes;

  @override
  List<Object?> get props => [colors, sizes];
}
