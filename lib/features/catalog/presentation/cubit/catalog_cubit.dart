import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:vellora/core/utils/safe_emit.dart';
import 'package:vellora/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vellora/features/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:vellora/features/catalog/domain/catalog_filter.dart';
import 'package:vellora/features/catalog/domain/usecases/get_catalog_products_usecase.dart';
import 'package:vellora/features/home/domain/entities/product_entity.dart';
import 'package:vellora/features/product/domain/usecases/get_favorite_ids_usecase.dart';
import 'package:vellora/features/product/domain/usecases/toggle_favorite_usecase.dart';

part 'catalog_state.dart';

/// Powers the category / "See all" list, the Explore tab and Search. Merges the
/// favourites set so hearts stay in sync with the rest of the app, and applies
/// the user's filter and sort on top of the fetched list.
@injectable
class CatalogCubit extends Cubit<CatalogState> with SafeEmit<CatalogState> {
  CatalogCubit(
    this._getProducts,
    this._getFavoriteIds,
    this._toggleFavorite,
    this._addToCart,
  ) : super(const CatalogState());

  final GetCatalogProductsUseCase _getProducts;
  final GetFavoriteIdsUseCase _getFavoriteIds;
  final ToggleFavoriteUseCase _toggleFavorite;
  final AddToCartUseCase _addToCart;

  String? _categoryId;
  CatalogCollection? _collection;

  /// Filter to start from once the first results arrive (e.g. a brand picked
  /// on Home). The user can clear it like any other filter.
  CatalogFilter? _initialFilter;

  /// Number of the latest load. A slower, older request that finishes after a
  /// newer one (or after [reset]) is ignored instead of overwriting it.
  int _loads = 0;

  Future<void> addToCart(ProductEntity p) => _addToCart(
    CartItemEntity(
      id: '${p.id}__',
      productId: p.id,
      name: p.name,
      imagePath: p.imagePath,
      price: p.price,
      quantity: 1,
    ),
  );

  Future<void> load({
    String? categoryId,
    String? query,
    CatalogCollection? collection,
    CatalogFilter? initialFilter,
  }) async {
    _initialFilter = initialFilter ?? _initialFilter;
    _categoryId = categoryId;
    _collection = collection ?? _collection;
    final load = ++_loads;
    emit(state.copyWith(status: CatalogStatus.loading, query: query ?? ''));
    final result = await _getProducts(
      CatalogQuery(categoryId: categoryId, query: query),
    );
    // The user may have left the screen, or searched again, while the request
    // was in flight.
    if (isClosed || load != _loads) return;
    final favIds = _getFavoriteIds().getOrElse((_) => <String>{});
    result.match(
      (failure) => emit(
        state.copyWith(
          status: CatalogStatus.error,
          failureKey: failure.l10nKey,
        ),
      ),
      (products) {
        var base = products
            .map((p) => p.copyWith(isFavorite: favIds.contains(p.id)))
            .toList(growable: false);
        if (_collection != null) base = _collection!.apply(base);
        final initial = _initialFilter;
        _initialFilter = null;
        _emitResults(base, filter: initial);
      },
    );
  }

  /// Re-runs the search within the current category scope.
  Future<void> search(String query) =>
      load(categoryId: _categoryId, query: query);

  /// Clears results back to the initial (suggestions) state, keeping nothing.
  void reset() {
    _loads++; // whatever is still loading no longer matters
    _collection = null;
    emit(const CatalogState());
  }

  void applyFilter(CatalogFilter filter) =>
      _emitResults(state.baseProducts, filter: filter);

  void clearFilter() => applyFilter(CatalogFilter.empty);

  void setSort(CatalogSort sort) =>
      _emitResults(state.baseProducts, sort: sort);

  void _emitResults(
    List<ProductEntity> base, {
    CatalogFilter? filter,
    CatalogSort? sort,
  }) {
    final f = filter ?? state.filter;
    final s = sort ?? state.sort;
    final shown = s.apply(f.apply(base));
    emit(
      state.copyWith(
        status: shown.isEmpty ? CatalogStatus.empty : CatalogStatus.loaded,
        baseProducts: base,
        products: shown,
        filter: f,
        sort: s,
      ),
    );
  }

  /// Re-marks hearts after another screen changed the favourites.
  void syncFavorites() {
    final ids = _getFavoriteIds().getOrElse((_) => <String>{});
    ProductEntity mark(ProductEntity p) =>
        p.copyWith(isFavorite: ids.contains(p.id));
    emit(
      state.copyWith(
        products: state.products.map(mark).toList(growable: false),
        baseProducts: state.baseProducts.map(mark).toList(growable: false),
      ),
    );
  }

  Future<void> toggleFavorite(String productId) async {
    final result = await _toggleFavorite(productId);
    if (isClosed) return;
    result.match((_) {}, (isNowFavorite) {
      ProductEntity mark(ProductEntity p) =>
          p.id == productId ? p.copyWith(isFavorite: isNowFavorite) : p;
      emit(
        state.copyWith(
          products: state.products.map(mark).toList(growable: false),
          baseProducts: state.baseProducts.map(mark).toList(growable: false),
        ),
      );
    });
  }
}
