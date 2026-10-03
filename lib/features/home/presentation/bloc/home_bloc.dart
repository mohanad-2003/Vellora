import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../../cart/domain/usecases/add_to_cart_usecase.dart';
import '../../../product/domain/usecases/get_favorite_ids_usecase.dart';
import '../../../product/domain/usecases/toggle_favorite_usecase.dart';
import '../../domain/entities/home_data_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_home_data_usecase.dart';

part 'home_event.dart';
part 'home_state.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(
    this._getHomeData,
    this._toggleFavorite,
    this._addToCart,
    this._getFavoriteIds,
  ) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshed>(_onRefreshed);
    on<HomeFavoriteToggled>(_onFavoriteToggled);
    on<HomeAddToCartRequested>(_onAddToCart);
    on<HomeFavoritesSynced>(_onFavoritesSynced);
  }

  final GetHomeDataUseCase _getHomeData;
  final ToggleFavoriteUseCase _toggleFavorite;
  final AddToCartUseCase _addToCart;
  final GetFavoriteIdsUseCase _getFavoriteIds;

  void _onFavoritesSynced(
    HomeFavoritesSynced event,
    Emitter<HomeState> emit,
  ) {
    final data = state.data;
    if (data == null) return;
    final ids = _getFavoriteIds().getOrElse((_) => <String>{});
    emit(state.copyWith(data: data.withFavorites(ids)));
  }

  Future<void> _onAddToCart(
    HomeAddToCartRequested event,
    Emitter<HomeState> emit,
  ) async {
    final p = event.product;
    await _addToCart(CartItemEntity(
      id: p.id,
      productId: p.id,
      name: p.name,
      imagePath: p.imagePath,
      price: p.price,
      quantity: 1,
    ));
  }

  Future<void> _load(Emitter<HomeState> emit, {required bool showLoader}) async {
    if (showLoader) emit(state.copyWith(status: HomeStatus.loading));
    final result = await _getHomeData(const NoParams());
    final refreshCount = showLoader ? null : state.refreshCount + 1;
    result.match(
      (failure) => emit(
        state.copyWith(
          // A failed pull-to-refresh keeps the content that is already shown.
          status: showLoader || state.data == null
              ? HomeStatus.error
              : HomeStatus.loaded,
          failureKey: failure.l10nKey,
          refreshCount: refreshCount,
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: HomeStatus.loaded,
          data: data,
          refreshCount: refreshCount,
        ),
      ),
    );
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) =>
      _load(emit, showLoader: true);

  Future<void> _onRefreshed(HomeRefreshed event, Emitter<HomeState> emit) =>
      _load(emit, showLoader: false);

  Future<void> _onFavoriteToggled(
    HomeFavoriteToggled event,
    Emitter<HomeState> emit,
  ) async {
    final data = state.data;
    if (data == null) return;
    final result = await _toggleFavorite(event.productId);
    result.match(
      (_) {},
      (isNowFavorite) {
        final favIds = <String>{
          for (final p in data.featured
              .followedBy(data.flashSale)
              .followedBy(data.newArrivals)
              .followedBy(data.bestSellers)
              .followedBy(data.recommended))
            if (p.isFavorite) p.id,
        };
        if (isNowFavorite) {
          favIds.add(event.productId);
        } else {
          favIds.remove(event.productId);
        }
        emit(state.copyWith(
          status: HomeStatus.loaded,
          data: data.withFavorites(favIds),
        ));
      },
    );
  }
}
