import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../repositories/wishlist_repository.dart';

@injectable
class GetWishlistProductsUseCase {
  GetWishlistProductsUseCase(this._repository);

  final WishlistRepository _repository;

  Future<Either<Failure, List<ProductEntity>>> call() =>
      _repository.getWishlistProducts();
}
