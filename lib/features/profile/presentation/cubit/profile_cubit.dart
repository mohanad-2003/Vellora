import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/get_cached_user_usecase.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import '../../../../core/utils/safe_emit.dart';

part 'profile_state.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> with SafeEmit<ProfileState> {
  ProfileCubit(this._getCachedUser, this._logout) : super(const ProfileState());

  final GetCachedUserUseCase _getCachedUser;
  final LogoutUseCase _logout;

  Future<void> loadUser() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final result = await _getCachedUser(const NoParams());
    result.match(
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          failureKey: failure.l10nKey,
        ),
      ),
      (user) => emit(ProfileState(status: ProfileStatus.loaded, user: user)),
    );
  }

  Future<void> logout() async {
    final result = await _logout(const NoParams());
    result.match(
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          failureKey: failure.l10nKey,
        ),
      ),
      (_) => emit(state.copyWith(status: ProfileStatus.loggedOut)),
    );
  }
}
