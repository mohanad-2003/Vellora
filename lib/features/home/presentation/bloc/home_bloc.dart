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
    on<HomeFavoritesSynced>((_, emit) => _syncFavorites(emit));
  }

  final GetHomeDataUseCase _getHomeData;
  final ToggleFavoriteUseCase _toggleFavorite;
  final AddToCartUseCase _addToCart;
  final GetFavoriteIdsUseCase _getFavoriteIds;
  String? _displayedLanguage;
  int _loadVersion = 0;

  void _syncFavorites(Emitter<HomeState> emit) {
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
    await _addToCart(
      CartItemEntity(
        id: '${p.id}__',
        productId: p.id,
        name: p.name,
        imagePath: p.imagePath,
        price: p.price,
        quantity: 1,
      ),
    );
  }

  Future<void> _load(
    Emitter<HomeState> emit,
    String languageCode, {
    required bool showLoader,
  }) async {
    final version = ++_loadVersion;
    if (showLoader && state.data == null) {
      emit(state.copyWith(status: HomeStatus.loading));
    }

    final remote = _getHomeData(const NoParams(), languageCode: languageCode);
    if (_displayedLanguage != languageCode) {
      final cached = await _getHomeData.cached(languageCode);
      if (cached != null && !emit.isDone && version == _loadVersion) {
        _displayedLanguage = languageCode;
        emit(state.copyWith(status: HomeStatus.loaded, data: cached));
      }
    }

    final result = await remote;
    if (emit.isDone || version != _loadVersion) return;

    final refreshCount = showLoader ? null : state.refreshCount + 1;
    result.match(
      (failure) => emit(
        state.copyWith(
          status: state.data == null ? HomeStatus.error : HomeStatus.loaded,
          failureKey: failure.l10nKey,
          refreshCount: refreshCount,
        ),
      ),
      (data) {
        _displayedLanguage = languageCode;
        emit(
          state.copyWith(
            status: HomeStatus.loaded,
            data: data,
            refreshCount: refreshCount,
          ),
        );
      },
    );
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) =>
      _load(emit, event.languageCode, showLoader: true);

  Future<void> _onRefreshed(HomeRefreshed event, Emitter<HomeState> emit) =>
      _load(emit, event.languageCode, showLoader: false);

  Future<void> _onFavoriteToggled(
    HomeFavoriteToggled event,
    Emitter<HomeState> emit,
  ) async {
    if (state.data == null) return;
    final result = await _toggleFavorite(event.productId);
    if (!emit.isDone && result.isRight()) _syncFavorites(emit);
  }
}
