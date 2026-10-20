import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/media/profile_photo.dart';
import '../../../auth/domain/usecases/update_profile_usecase.dart';
import '../../../../core/utils/safe_emit.dart';

part 'edit_profile_state.dart';

/// Handles saving edits to the signed-in user's profile.
@injectable
class EditProfileCubit extends Cubit<EditProfileState> with SafeEmit<EditProfileState> {
  EditProfileCubit(this._updateProfile, this._updateAvatar)
      : super(const EditProfileState());

  final UpdateProfileUseCase _updateProfile;
  final UpdateAvatarUseCase _updateAvatar;

  /// Where profile pictures are sent. Replaceable in tests.
  ProfilePhotoUploader uploader = ProfilePhotoUploader();

  /// Uploads [bytes] and makes it the profile picture. The picture on the
  /// account is only changed once the upload worked, so a failure leaves the
  /// old one in place. `failureKey` is null on success; `url` is the saved
  /// address (null after a removal).
  Future<({String? failureKey, String? url})> changeAvatar(
    Uint8List bytes, {
    String filename = 'avatar.jpg',
  }) async {
    final String address;
    try {
      address = await uploader.upload(bytes, filename: filename);
    } catch (_) {
      return (failureKey: 'photoUploadFailed', url: null);
    }
    return _saveAvatar(address);
  }

  Future<({String? failureKey, String? url})> removeAvatar() => _saveAvatar(null);

  Future<({String? failureKey, String? url})> _saveAvatar(String? url) async {
    final result = await _updateAvatar(url);
    return result.match(
      (failure) => (failureKey: failure.l10nKey, url: null),
      (user) => (failureKey: null, url: user.avatarUrl),
    );
  }

  Future<void> save({required String name, String? phone}) async {
    emit(state.copyWith(status: EditProfileStatus.saving));
    final result = await _updateProfile(
      UpdateProfileParams(name: name, phone: phone),
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
