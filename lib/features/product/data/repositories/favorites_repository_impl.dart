import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_datasource.dart';
import '../datasources/wishlist_remote_datasource.dart';

/// Favourites are saved on the device first, so hearts react instantly and
/// guests can use them. For a signed-in user every change is also sent to the
/// account's wishlist, and [sync] merges the two when they may have diverged
/// (after signing in, at app start).
@LazySingleton(as: FavoritesRepository)
class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._local, this._remote, this._auth);

  final FavoritesLocalDataSource _local;
  final WishlistRemoteDataSource _remote;
  final AuthLocalDataSource _auth;

  Future<bool> _signedIn() async {
    try {
      final user = await _auth.getCachedUser();
      return user?.token != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Either<Failure, Set<String>> getFavoriteIds() {
    try {
      return Right(_local.getFavoriteIds());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, bool>> toggle(String productId) async {
    try {
      final nowFavorite = await _local.toggle(productId);
      if (await _signedIn()) {
        // Best effort: if it fails the device keeps the choice and the next
        // sync pushes it.
        unawaited(
          (nowFavorite ? _remote.add(productId) : _remote.remove(productId))
              .catchError((Object _) {}),
        );
      }
      return Right(nowFavorite);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Either<Failure, bool> isFavorite(String productId) {
    try {
      return Right(_local.isFavorite(productId));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<void> sync() async {
    if (!await _signedIn()) return;
    try {
      final remote = await _remote.getIds();
      final local = _local.getFavoriteIds();
      // A guest's favourites join the account's; the account's come to the
      // device. Only what is actually missing is written, on either side.
      final missingHere = remote.difference(local);
      if (missingHere.isNotEmpty) await _local.addAll(missingHere);
      for (final id in local.difference(remote)) {
        await _remote.add(id);
      }
    } catch (_) {
      // Offline or the token expired: try again next time.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _local.clear();
    } catch (_) {}
  }
}
