import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/product_entity.dart';

/// Reads the user's favorite product ids and hydrates them into full
/// [ProductEntity] objects from the catalogue, plus removal.
abstract class WishlistRepository {
  Future<Either<Failure, List<ProductEntity>>> getWishlistProducts();
  Future<Either<Failure, bool>> removeFromWishlist(String productId);
}
