import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/cart_item_entity.dart';
import '../entities/promo_code_entity.dart';

abstract class CartRepository {
  Future<Either<Failure, List<CartItemEntity>>> getItems();
  Future<Either<Failure, Unit>> addItem(CartItemEntity item);
  Future<Either<Failure, Unit>> updateQuantity(String itemId, int quantity);
  Future<Either<Failure, Unit>> removeItem(String itemId);
  Future<Either<Failure, PromoCodeEntity>> applyPromo(String code);

  /// Merges the device's bag with the signed-in account's (after signing in or
  /// at app start). No-op for guests; failures keep the local bag.
  Future<void> sync();

  /// Empties the bag on this device (signing out).
  Future<void> clearLocal();
}
