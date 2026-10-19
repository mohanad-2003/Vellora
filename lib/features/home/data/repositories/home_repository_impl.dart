import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../product/domain/repositories/favorites_repository.dart';
import '../../domain/entities/home_data_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote, this._favorites);

  final HomeRemoteDataSource _remote;
  final FavoritesRepository _favorites;

  @override
  Future<Either<Failure, HomeDataEntity>> getHomeData() async {
    try {
      final data = await _remote.getHomeData();
      final favoriteIds =
          _favorites.getFavoriteIds().getOrElse((_) => <String>{});
      return Right(data.withFavorites(favoriteIds));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
