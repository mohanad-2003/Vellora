part of 'product_detail_bloc.dart';

sealed class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object?> get props => [];
}

class ProductDetailRequested extends ProductDetailEvent {
  const ProductDetailRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class ProductColorSelected extends ProductDetailEvent {
  const ProductColorSelected(this.color);

  final String color;

  @override
  List<Object?> get props => [color];
}

class ProductSizeSelected extends ProductDetailEvent {
  const ProductSizeSelected(this.size);

  final String size;

  @override
  List<Object?> get props => [size];
}

class ProductQuantityChanged extends ProductDetailEvent {
  const ProductQuantityChanged(this.quantity);

  final int quantity;

  @override
  List<Object?> get props => [quantity];
}

class ProductFavoriteToggled extends ProductDetailEvent {
  const ProductFavoriteToggled();
}

class ProductAddToCartRequested extends ProductDetailEvent {
  const ProductAddToCartRequested();
}

/// Adds the current selection to the cart, then signals the page to continue
/// to checkout.
class ProductBuyNowRequested extends ProductDetailEvent {
  const ProductBuyNowRequested();
}
