import 'package:fpdart/fpdart.dart';
import 'package:vellora/core/errors/failures.dart';
import 'package:vellora/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> forgotPassword({required String email});

  /// Verifies the OTP for a password reset. Returns an opaque reset token on
  /// success, used to authorise the subsequent password change.
  Future<Either<Failure, String>> verifyOtp({
    required String email,
    required String code,
  });

  /// Sets a new password using a token obtained from [verifyOtp].
  Future<Either<Failure, Unit>> resetPassword({
    required String resetToken,
    required String newPassword,
  });

  Future<Either<Failure, UserEntity?>> getCachedUser();

  /// Updates the signed-in user's name (saved on the server too) and phone
  /// (kept on this device) and returns the merged user. The email belongs to the
  /// account and cannot be changed here. Fails with `unauthorized` when nobody
  /// is signed in.
  Future<Either<Failure, UserEntity>> updateProfile({
    required String name,
    String? phone,
  });

  Future<Either<Failure, Unit>> logout();

  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Deletes the account on the server, then clears the local session.
  Future<Either<Failure, Unit>> deleteAccount({required String password});
}
