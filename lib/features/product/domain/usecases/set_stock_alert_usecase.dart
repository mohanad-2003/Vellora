import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/product_repository.dart';

class SetStockAlertParams {
  const SetStockAlertParams(this.productId, {required this.enabled});

  final String productId;
  final bool enabled;
}

/// "Tell me when it is back" for a sold-out product, or take the request back.
@injectable
class SetStockAlertUseCase implements UseCase<Unit, SetStockAlertParams> {
  SetStockAlertUseCase(this._repository);

  final ProductRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SetStockAlertParams params) =>
      _repository.setStockAlert(params.productId, enabled: params.enabled);
}
