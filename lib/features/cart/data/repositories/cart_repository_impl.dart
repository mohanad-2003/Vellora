import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/promo_code_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_datasource.dart';
import '../datasources/cart_remote_datasource.dart';
import '../datasources/promo_datasource.dart';
import '../models/cart_item_model.dart';

/// The bag lives on the device (so guests can shop and it works offline);
/// for a signed-in user every change is mirrored to the account's cart, and
/// [sync] merges the two when they may have diverged.
@LazySingleton(as: CartRepository)
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._local, this._promo, this._remote, this._auth);

  final CartLocalDataSource _local;
  final PromoDataSource _promo;
  final CartRemoteDataSource _remote;
  final AuthLocalDataSource _auth;

  /// Pushes run one after another, each sending the bag as it is when it runs,
  /// so a quick burst of changes cannot land out of order.
  Future<void>? _pushQueue;

  Future<bool> _signedIn() async {
    try {
      final user = await _auth.getCachedUser();
      return user?.token != null;
    } catch (_) {
      return false;
    }
  }

  /// Best effort: if it fails the device keeps the bag and the next sync pushes it.
  Future<void> _mirror() async {
    if (!await _signedIn()) return;
    _pushQueue = (_pushQueue ?? Future<void>.value()).then((_) async {
      try {
        await _remote.replaceItems(await _local.readAll());
      } catch (_) {}
    });
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> getItems() async {
    try {
      final items = await _local.getItems();
      return Right(items.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> addItem(CartItemEntity item) async {
    try {
      await _local.addItem(CartItemModel.fromEntity(item));
      unawaited(_mirror());
      return const Right(unit);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateQuantity(
    String itemId,
    int quantity,
  ) async {
    try {
      await _local.updateQuantity(itemId, quantity);
      unawaited(_mirror());
      return const Right(unit);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeItem(String itemId) async {
    try {
      await _local.removeItem(itemId);
      unawaited(_mirror());
      return const Right(unit);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, PromoCodeEntity>> applyPromo(String code) async {
    try {
      return Right(await _promo.validate(code));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<void> sync() async {
    if (!await _signedIn()) return;
    try {
      await _pushQueue;
      final remote = await _remote.getItems();
      final local = await _local.readAll();

      // A guest's bag joins the account's. The same product + variant keeps the
      // larger quantity rather than adding up, so syncing twice changes nothing.
      String key(CartItemModel i) => '${i.productId}|${i.color}|${i.size}';
      final merged = <String, CartItemModel>{
        for (final i in remote) key(i): i,
      };
      for (final i in local) {
        final existing = merged[key(i)];
        merged[key(i)] = existing == null
            ? i
            : existing.copyWith(
                quantity: existing.quantity > i.quantity
                    ? existing.quantity
                    : i.quantity,
              );
      }

      // The server's answer is the truth (current prices, products that no
      // longer exist dropped).
      final saved = await _remote.replaceItems(merged.values.toList());
      // Nothing to rewrite when the device already holds exactly this.
      final same =
          saved.length == local.length &&
          saved.every((i) => local.contains(i));
      if (!same) await _local.replaceAll(saved);
    } catch (_) {
      // Offline or the token expired: try again next time.
    }
  }

  @override
  Future<void> clearLocal() async {
    try {
      await _pushQueue;
      await _local.clear();
    } catch (_) {}
  }
}
