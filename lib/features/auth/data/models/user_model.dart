import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? avatarUrl,

    /// In memory only: never written to JSON (so never to Hive). The access
    /// token lives in secure storage and is attached when the user is read.
    @JsonKey(includeFromJson: false, includeToJson: false) String? token,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromEntity(UserEntity entity) => UserModel(
    id: entity.id,
    name: entity.name,
    email: entity.email,
    phone: entity.phone,
    avatarUrl: entity.avatarUrl,
    token: entity.token,
  );

  UserEntity toEntity() => UserEntity(
    id: id,
    name: name,
    email: email,
    phone: phone,
    avatarUrl: avatarUrl,
    token: token,
  );
}
