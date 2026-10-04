import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/usecases/update_profile_usecase.dart';
import '../../../../core/utils/safe_emit.dart';

part 'edit_profile_state.dart';

/// Handles saving edits to the signed-in user's profile.
@injectable
class EditProfileCubit extends Cubit<EditProfileState> with SafeEmit<EditProfileState> {
  EditProfileCubit(this._updateProfile) : super(const EditProfileState());

  final UpdateProfileUseCase _updateProfile;

  Future<void> save({
    required String name,
    required String email,
    String? phone,
  }) async {
    emit(state.copyWith(status: EditProfileStatus.saving));
    final result = await _updateProfile(
      UpdateProfileParams(name: name, email: email, phone: phone),
    );
    result.match(
      (failure) => emit(
        state.copyWith(
          status: EditProfileStatus.error,
          failureKey: failure.l10nKey,
        ),
      ),
      (_) => emit(state.copyWith(status: EditProfileStatus.success)),
    );
  }
}
