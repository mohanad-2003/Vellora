import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';

abstract class FavoritesRepository {
  Either<Failure, Set<String>> getFavoriteIds();
  Future<Either<Failure, bool>> toggle(String productId);
  Either<Failure, bool> isFavorite(String productId);

  /// Signed-in users: merges the favourites saved on this device with the ones
  /// on the account (nothing is lost on either side) and keeps both equal.
  /// Does nothing when signed out or offline.
  Future<void> sync();

  /// Forgets this device's favourites (sign-out, account deletion).
  Future<void> clear();
}
