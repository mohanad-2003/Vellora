import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../../cart/domain/usecases/add_to_cart_usecase.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../domain/entities/product_detail_entity.dart';
import '../../domain/usecases/get_product_details_usecase.dart';
import '../../domain/usecases/get_related_products_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';

part 'product_detail_event.dart';
part 'product_detail_state.dart';

@injectable
class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc(
    this._getDetails,
    this._getRelated,
    this._toggleFavorite,
    this._addToCart,
  ) : super(const ProductDetailState()) {
    on<ProductDetailRequested>(_onRequested);
    on<ProductColorSelected>(_onColorSelected);
    on<ProductSizeSelected>(_onSizeSelected);
    on<ProductQuantityChanged>(_onQuantityChanged);
    on<ProductFavoriteToggled>(_onFavoriteToggled);
    on<ProductAddToCartRequested>(_onAddToCart);
    on<ProductBuyNowRequested>(_onBuyNow);
  }

  final GetProductDetailsUseCase _getDetails;
  final GetRelatedProductsUseCase _getRelated;
  final ToggleFavoriteUseCase _toggleFavorite;
  final AddToCartUseCase _addToCart;

  Future<void> _onRequested(
    ProductDetailRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(state.copyWith(status: ProductDetailStatus.loading));
    final result = await _getDetails(event.id);
    await result.match(
      (failure) async => emit(state.copyWith(
        status: ProductDetailStatus.error,
        failureKey: failure.l10nKey,
      )),
      (detail) async {
        final related = await _getRelated(event.id);
        emit(state.copyWith(
          status: ProductDetailStatus.loaded,
          detail: detail,
          related: related.getOrElse((_) => const []),
          selectedColor: detail.variant.colors.isNotEmpty
              ? detail.variant.colors.first
              : null,
          selectedSize: detail.variant.sizes.isNotEmpty
              ? detail.variant.sizes.first
              : null,
          quantity: 1,
        ));
      },
    );
  }

  void _onColorSelected(
    ProductColorSelected event,
    Emitter<ProductDetailState> emit,
  ) =>
      emit(state.copyWith(selectedColor: event.color));

  void _onSizeSelected(
    ProductSizeSelected event,
    Emitter<ProductDetailState> emit,
  ) =>
      emit(state.copyWith(selectedSize: event.size));

  void _onQuantityChanged(
    ProductQuantityChanged event,
    Emitter<ProductDetailState> emit,
  ) =>
      emit(state.copyWith(quantity: event.quantity));

  Future<void> _onFavoriteToggled(
    ProductFavoriteToggled event,
    Emitter<ProductDetailState> emit,
  ) async {
    final detail = state.detail;
    if (detail == null) return;
    final result = await _toggleFavorite(detail.product.id);
    result.match(
      (_) {},
      (isNowFavorite) => emit(state.copyWith(
        detail: detail.copyWith(
          product: detail.product.copyWith(isFavorite: isNowFavorite),
        ),
      )),
    );
  }

  Future<bool> _persistToCart() async {
    final detail = state.detail;
    if (detail == null) return false;
    final p = detail.product;
    final item = CartItemEntity(
      id: '${p.id}_${state.selectedColor ?? ''}_${state.selectedSize ?? ''}',
      productId: p.id,
      name: p.name,
      imagePath: p.imagePath,
      price: p.price,
      quantity: state.quantity,
      color: state.selectedColor,
      size: state.selectedSize,
    );
    final result = await _addToCart(item);
    return result.isRight();
  }

  Future<void> _onAddToCart(
    ProductAddToCartRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    if (await _persistToCart()) {
      emit(state.copyWith(addedToCartTick: state.addedToCartTick + 1));
    }
  }

  Future<void> _onBuyNow(
    ProductBuyNowRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    if (await _persistToCart()) {
      emit(state.copyWith(buyNowTick: state.buyNowTick + 1));
    }
  }
}
