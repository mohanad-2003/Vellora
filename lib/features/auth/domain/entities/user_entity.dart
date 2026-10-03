import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.token,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? token;

  UserEntity copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) => UserEntity(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    token: token,
  );

  @override
  List<Object?> get props => [id, name, email, phone, avatarUrl, token];
}
