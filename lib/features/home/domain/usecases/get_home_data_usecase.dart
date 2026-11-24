import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/home_data_entity.dart';
import '../repositories/home_repository.dart';

@injectable
class GetHomeDataUseCase implements UseCase<HomeDataEntity, NoParams> {
  GetHomeDataUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, HomeDataEntity>> call(
    NoParams params, {
    String? languageCode,
  }) => _repository.getHomeData(languageCode: languageCode);

  Future<HomeDataEntity?> cached(String languageCode) =>
      _repository.getCachedHomeData(languageCode);
}
