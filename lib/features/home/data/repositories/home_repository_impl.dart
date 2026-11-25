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
  Future<Either<Failure, HomeDataEntity>> getHomeData({
    String? languageCode,
  }) async {
    try {
      final data = await _remote.getHomeData(languageCode: languageCode);
      return Right(_withFavorites(data));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<HomeDataEntity?> getCachedHomeData(String languageCode) async {
    final data = await _remote.getCachedHomeData(languageCode);
    return data == null ? null : _withFavorites(data);
  }

  HomeDataEntity _withFavorites(HomeDataEntity data) => data.withFavorites(
    _favorites.getFavoriteIds().getOrElse((_) => <String>{}),
  );
}
