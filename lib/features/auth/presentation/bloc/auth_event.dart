part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckStatusRequested extends AuthEvent {
  const AuthCheckStatusRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// The authenticator code for an account that asked for two-factor sign-in.
class AuthTwoFactorSubmitted extends AuthEvent {
  const AuthTwoFactorSubmitted({required this.code});

  final String code;

  @override
  List<Object?> get props => [code];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

class AuthForgotPasswordRequested extends AuthEvent {
  const AuthForgotPasswordRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthOtpVerifyRequested extends AuthEvent {
  const AuthOtpVerifyRequested({required this.code});

  final String code;

  @override
  List<Object?> get props => [code];
}

class AuthResetPasswordRequested extends AuthEvent {
  const AuthResetPasswordRequested({required this.newPassword});

  final String newPassword;

  @override
  List<Object?> get props => [newPassword];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
