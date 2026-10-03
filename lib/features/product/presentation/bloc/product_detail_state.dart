part of 'product_detail_bloc.dart';

enum ProductDetailStatus { initial, loading, loaded, error }

class ProductDetailState extends Equatable {
  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.detail,
    this.related = const [],
    this.selectedColor,
    this.selectedSize,
    this.quantity = 1,
    this.failureKey,
    this.addedToCartTick = 0,
    this.buyNowTick = 0,
  });

  final ProductDetailStatus status;
  final ProductDetailEntity? detail;
  final List<ProductEntity> related;
  final String? selectedColor;
  final String? selectedSize;
  final int quantity;
  final String? failureKey;

  /// Increments each time an add-to-cart succeeds so the page can fire a
  /// one-off snackbar without a separate stream.
  final int addedToCartTick;

  /// Increments when a Buy Now add succeeds; the page then opens checkout.
  final int buyNowTick;

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    ProductDetailEntity? detail,
    List<ProductEntity>? related,
    String? selectedColor,
    String? selectedSize,
    int? quantity,
    String? failureKey,
    int? addedToCartTick,
    int? buyNowTick,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      related: related ?? this.related,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      quantity: quantity ?? this.quantity,
      failureKey: failureKey,
      addedToCartTick: addedToCartTick ?? this.addedToCartTick,
      buyNowTick: buyNowTick ?? this.buyNowTick,
    );
  }

  @override
  List<Object?> get props => [
    status,
    detail,
    related,
    selectedColor,
    selectedSize,
    quantity,
    failureKey,
    addedToCartTick,
    buyNowTick,
  ];
}
