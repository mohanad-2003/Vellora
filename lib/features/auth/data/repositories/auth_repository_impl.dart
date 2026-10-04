import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:vellora/core/errors/exception_mapper.dart';
import 'package:vellora/core/errors/failures.dart';
import 'package:vellora/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:vellora/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:vellora/features/auth/data/models/user_model.dart';
import 'package:vellora/features/auth/domain/entities/user_entity.dart';
import 'package:vellora/features/auth/domain/repositories/auth_repository.dart';
import 'package:vellora/features/cart/domain/repositories/cart_repository.dart';
import 'package:vellora/features/product/domain/repositories/favorites_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remote,
    this._local,
    this._favorites,
    this._cart,
  );

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final FavoritesRepository _favorites;
  final CartRepository _cart;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.login(email: email, password: password);
      await _local.cacheUser(user);
      await _favorites.sync();
      await _cart.sync();
      return Right(user.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.register(
        name: name,
        email: email,
        password: password,
      );
      await _local.cacheUser(user);
      await _favorites.sync();
      await _cart.sync();
      return Right(user.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> forgotPassword({required String email}) async {
    try {
      await _remote.forgotPassword(email: email);
      return const Right(unit);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final token = await _remote.verifyOtp(email: email, code: code);
      return Right(token);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      await _remote.resetPassword(
        resetToken: resetToken,
        newPassword: newPassword,
      );
      return const Right(unit);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCachedUser() async {
    try {
      final UserModel? user = await _local.getCachedUser();
      return Right(user?.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      final existing = await _local.getCachedUser();
      // No session, no profile to edit: a signed-out visitor must not end up
      // with a made-up local user that the app would treat as signed in.
      if (existing == null) {
        return const Left(
          Failure.unauthorized(message: 'Sign in to edit your profile'),
        );
      }
      final updated = existing.copyWith(
        name: name,
        email: email,
        phone: phone,
      );
      await _local.cacheUser(updated);
      // Email and phone are device-only for now; the name is saved on the
      // server too. An offline user keeps the local edit.
      try {
        await _remote.updateName(name: name);
      } catch (_) {}
      return Right(updated.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final freshToken = await _remote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      // The server signed every session out, this device included; keep this
      // one going with the token it issued for it.
      if (freshToken != null) await _local.saveToken(freshToken);
      return const Right(unit);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount({
    required String password,
  }) async {
    try {
      await _remote.deleteAccount(password: password);
      await _local.clear();
      await _favorites.clear();
      await _cart.clearLocal();
      return const Right(unit);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      // End the session on the server too, otherwise a copy of the token would
      // stay valid. The token is read first because clearing removes it; the
      // request is best effort so signing out works offline.
      String? token;
      try {
        token = (await _local.getCachedUser())?.token;
      } catch (_) {}
      await _local.clear();
      await _favorites.clear();
      await _cart.clearLocal();
      if (token != null) {
        unawaited(
          Future<void>.sync(
            () => _remote.logout(token: token!),
          ).catchError((Object _) {}),
        );
      }
      return const Right(unit);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
