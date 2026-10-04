import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/cart_summary_entity.dart';
import '../../domain/entities/promo_code_entity.dart';
import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/apply_promo_usecase.dart';
import '../../domain/usecases/get_cart_usecase.dart';
import '../../domain/usecases/remove_from_cart_usecase.dart';
import '../../domain/usecases/update_quantity_usecase.dart';

part 'cart_event.dart';
part 'cart_state.dart';

@injectable
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(
    this._getCart,
    this._updateQuantity,
    this._removeItem,
    this._applyPromo,
    this._addToCart,
  ) : super(const CartState()) {
    on<CartStarted>(_onStarted);
    on<CartQuantityChanged>(_onQuantityChanged);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartPromoApplied>(_onPromoApplied);
    on<CartPromoRemoved>(_onPromoRemoved);
    on<CartItemRestored>(_onItemRestored);
    on<CartSynced>(_onSynced);
  }

  final GetCartUseCase _getCart;
  final UpdateQuantityUseCase _updateQuantity;
  final RemoveFromCartUseCase _removeItem;
  final ApplyPromoUseCase _applyPromo;
  final AddToCartUseCase _addToCart;

  /// Changes are written one after another, in the order the user made them,
  /// so quick taps cannot overtake each other on the way to storage.
  Future<void> _writes = Future<void>.value();

  Future<void> _persist(Future<void> Function() write) {
    final done = _writes.then((_) => write());
    _writes = done.catchError((Object _) {});
    return done;
  }

  /// A reload that started before a newer one must not overwrite its result.
  int _reloads = 0;

  Future<void> _refresh(
    Emitter<CartState> emit, {
    bool showLoader = false,
    PromoCodeEntity? promo,
    bool clearPromo = false,
  }) async {
    if (showLoader) emit(state.copyWith(status: CartStatus.loading));
    final reload = ++_reloads;
    final result = await _getCart(const NoParams());
    if (reload != _reloads) return;
    result.match(
      (failure) => emit(state.copyWith(
        status: CartStatus.error,
        failureKey: failure.l10nKey,
      )),
      (items) {
        final effectivePromo = clearPromo ? null : (promo ?? state.promo);
        emit(state.copyWith(
          status: items.isEmpty ? CartStatus.empty : CartStatus.loaded,
          items: items,
          promo: effectivePromo,
          clearPromo: clearPromo || items.isEmpty,
          summary: CartSummaryEntity.from(
            items,
            items.isEmpty ? null : effectivePromo,
          ),
        ));
      },
    );
  }

  Future<void> _onStarted(CartStarted event, Emitter<CartState> emit) =>
      _refresh(emit, showLoader: true);

  Future<void> _onQuantityChanged(
    CartQuantityChanged event,
    Emitter<CartState> emit,
  ) async {
    // Optimistic: reflect the change immediately, then persist and reconcile.
    final updated = [
      for (final item in state.items)
        if (item.id == event.itemId)
          item.copyWith(quantity: event.quantity)
        else
          item,
    ];
    if (state.status == CartStatus.loaded) {
      emit(state.copyWith(
        items: updated,
        summary: CartSummaryEntity.from(updated, state.promo),
      ));
    }
    await _persist(
      () => _updateQuantity(
        UpdateQuantityParams(itemId: event.itemId, quantity: event.quantity),
      ),
    );
    await _refresh(emit);
  }

  Future<void> _onItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    await _persist(() => _removeItem(event.itemId));
    await _refresh(emit);
  }

  Future<void> _onPromoApplied(
    CartPromoApplied event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(applyingPromo: true));
    final result = await _applyPromo(event.code);
    await result.match(
      (_) async => emit(state.copyWith(promoError: true)),
      (promo) async => _refresh(emit, promo: promo),
    );
  }

  Future<void> _onPromoRemoved(
    CartPromoRemoved event,
    Emitter<CartState> emit,
  ) =>
      _refresh(emit, clearPromo: true);

  /// Puts back an item the user just removed (the "Undo" action).
  Future<void> _onItemRestored(
    CartItemRestored event,
    Emitter<CartState> emit,
  ) async {
    await _persist(() => _addToCart(event.item));
    await _refresh(emit);
  }

  /// The cart box changed elsewhere (Home quick-add, product page…). Reload
  /// silently — only when the count really differs from what is displayed.
  Future<void> _onSynced(CartSynced event, Emitter<CartState> emit) async {
    if (state.status == CartStatus.loading) return;
    final shown = state.summary?.itemCount ?? 0;
    if (shown == event.itemCount) return;
    await _refresh(emit);
  }
}
