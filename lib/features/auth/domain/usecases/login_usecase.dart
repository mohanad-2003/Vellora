import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@injectable
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) {
    final challenge = params.challengeToken;
    // Second step of a two-factor sign-in: no password, just the code.
    if (challenge != null) {
      return _repository.loginTwoFactor(
        challengeToken: challenge,
        code: params.code ?? '',
      );
    }
    return _repository.login(email: params.email, password: params.password);
  }
}

class LoginParams extends Equatable {
  const LoginParams({
    required this.email,
    required this.password,
    this.challengeToken,
    this.code,
  });

  final String email;
  final String password;

  /// Set (with [code]) for the second step of a two-factor sign-in.
  final String? challengeToken;
  final String? code;

  @override
  List<Object?> get props => [email, password, challengeToken, code];
}
