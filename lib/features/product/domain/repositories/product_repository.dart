import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../entities/product_detail_entity.dart';

abstract class ProductRepository {
  Future<Either<Failure, ProductDetailEntity>> getProductDetails(String id);
  Future<Either<Failure, List<ProductEntity>>> getRelatedProducts(String id);

  Future<Either<Failure, Unit>> addReview({
    required String productId,
    required int rating,
    required String comment,
  });
}
