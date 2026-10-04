import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@injectable
class UpdateProfileUseCase implements UseCase<UserEntity, UpdateProfileParams> {
  UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) =>
      _repository.updateProfile(
        name: params.name,
        phone: params.phone,
      );
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({required this.name, this.phone});

  final String name;
  final String? phone;

  @override
  List<Object?> get props => [name, phone];
}
