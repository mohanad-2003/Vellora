import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/product_entity.dart';

/// Read access to the product catalog for browsing (by category) and search.
abstract class CatalogRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? categoryId,
    String? query,
  });

  Future<Either<Failure, List<ProductEntity>>> getProductsByIds(
    List<String> ids,
  );
}
