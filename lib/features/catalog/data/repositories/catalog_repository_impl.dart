import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_datasource.dart';

@LazySingleton(as: CatalogRepository)
class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._remote);

  final CatalogRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? categoryId,
    String? query,
  }) async {
    try {
      final products = await _remote.getProducts(
        categoryId: categoryId,
        query: query,
      );
      return Right(products);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByIds(
    List<String> ids,
  ) async {
    try {
      return Right(await _remote.getProductsByIds(ids));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
