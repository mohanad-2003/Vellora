import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/home_data_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, HomeDataEntity>> getHomeData({String? languageCode});
  Future<HomeDataEntity?> getCachedHomeData(String languageCode);
}
