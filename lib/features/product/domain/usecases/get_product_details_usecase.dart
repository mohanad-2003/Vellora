import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_detail_entity.dart';
import '../repositories/product_repository.dart';

@injectable
class GetProductDetailsUseCase implements UseCase<ProductDetailEntity, String> {
  GetProductDetailsUseCase(this._repository);

  final ProductRepository _repository;

  @override
  Future<Either<Failure, ProductDetailEntity>> call(String id) =>
      _repository.getProductDetails(id);
}
