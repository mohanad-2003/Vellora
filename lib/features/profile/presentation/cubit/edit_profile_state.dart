part of 'edit_profile_cubit.dart';

enum EditProfileStatus { editing, saving, success, error }

class EditProfileState extends Equatable {
  const EditProfileState({
    this.status = EditProfileStatus.editing,
    this.failureKey,
  });

  final EditProfileStatus status;
  final String? failureKey;

  bool get isSaving => status == EditProfileStatus.saving;

  EditProfileState copyWith({EditProfileStatus? status, String? failureKey}) {
    return EditProfileState(
      status: status ?? this.status,
      failureKey: failureKey,
    );
  }

  @override
  List<Object?> get props => [status, failureKey];
}
