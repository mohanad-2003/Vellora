import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../../product/domain/repositories/favorites_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';

/// Favorite ids live on the device (so guests can save items); the products
/// themselves are fetched from the catalogue.
@LazySingleton(as: WishlistRepository)
class WishlistRepositoryImpl implements WishlistRepository {
  WishlistRepositoryImpl(this._favorites, this._catalog);

  final FavoritesRepository _favorites;
  final CatalogRepository _catalog;

  @override
  Future<Either<Failure, List<ProductEntity>>> getWishlistProducts() async {
    final ids = _favorites.getFavoriteIds();
    return ids.fold(
      (failure) async => Left<Failure, List<ProductEntity>>(failure),
      (set) async {
        if (set.isEmpty) return const Right(<ProductEntity>[]);
        final result = await _catalog.getProductsByIds(set.toList());
        return result.map(
          (products) =>
              [for (final p in products) p.copyWith(isFavorite: true)],
        );
      },
    );
  }

  @override
  Future<Either<Failure, bool>> removeFromWishlist(String productId) =>
      _favorites.toggle(productId);
}
