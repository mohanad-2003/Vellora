import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../domain/entities/product_detail_entity.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote, this._favorites);

  final ProductRemoteDataSource _remote;
  final FavoritesRepository _favorites;

  @override
  Future<Either<Failure, ProductDetailEntity>> getProductDetails(
    String id,
  ) async {
    try {
      final detail = await _remote.getProductDetails(id);
      final isFav = _favorites.isFavorite(id).getOrElse((_) => false);
      return Right(
        detail.copyWith(product: detail.product.copyWith(isFavorite: isFav)),
      );
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> addReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _remote.addReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );
      return const Right(unit);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getRelatedProducts(
    String id,
  ) async {
    try {
      final related = await _remote.getRelatedProducts(id);
      final favIds = _favorites.getFavoriteIds().getOrElse((_) => <String>{});
      return Right(
        related
            .map((p) => p.copyWith(isFavorite: favIds.contains(p.id)))
            .toList(),
      );
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
