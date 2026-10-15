import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/coupon_offer_entity.dart';
import '../repositories/cart_repository.dart';

/// The coupons the shop shows in the app that this shopper can still use.
@injectable
class GetAvailableCouponsUseCase implements UseCase<List<CouponOfferEntity>, NoParams> {
  GetAvailableCouponsUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Either<Failure, List<CouponOfferEntity>>> call(NoParams params) =>
      _repository.availableCoupons();
}
