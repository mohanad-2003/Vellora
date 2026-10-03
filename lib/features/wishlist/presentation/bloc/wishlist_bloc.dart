import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../home/domain/entities/product_entity.dart';
import '../../domain/usecases/get_wishlist_products_usecase.dart';
import '../../domain/usecases/remove_from_wishlist_usecase.dart';

part 'wishlist_event.dart';
part 'wishlist_state.dart';

@injectable
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  WishlistBloc(this._getProducts, this._removeItem)
      : super(const WishlistState()) {
    on<WishlistStarted>(_onStarted);
    on<WishlistItemRemoved>(_onItemRemoved);
    on<WishlistRefreshed>((event, emit) => _load(emit));
  }

  final GetWishlistProductsUseCase _getProducts;
  final RemoveFromWishlistUseCase _removeItem;

  Future<void> _load(Emitter<WishlistState> emit) async {
    final result = await _getProducts();
    result.match(
      (failure) => emit(state.copyWith(
        status: WishlistStatus.error,
        failureKey: failure.l10nKey,
      )),
      (products) => emit(state.copyWith(
        status: products.isEmpty
            ? WishlistStatus.empty
            : WishlistStatus.loaded,
        products: products,
      )),
    );
  }

  Future<void> _onStarted(
    WishlistStarted event,
    Emitter<WishlistState> emit,
  ) async {
    emit(state.copyWith(status: WishlistStatus.loading));
    await _load(emit);
  }

  Future<void> _onItemRemoved(
    WishlistItemRemoved event,
    Emitter<WishlistState> emit,
  ) async {
    await _removeItem(event.productId);
    await _load(emit);
  }
}
