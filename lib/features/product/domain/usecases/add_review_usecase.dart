import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/product_repository.dart';

@injectable
class AddReviewUseCase {
  AddReviewUseCase(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String productId,
    required int rating,
    required String comment,
  }) => _repository.addReview(
    productId: productId,
    rating: rating,
    comment: comment,
  );
}
