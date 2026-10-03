part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  failure,
  passwordResetSent,
  otpVerified,
  passwordResetSuccess,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.failureKey,
    this.pendingEmail,
    this.resetToken,
  });

  final AuthStatus status;
  final UserEntity? user;

  /// Stable l10n key for the current failure (resolved in the UI).
  final String? failureKey;

  /// Email captured at the forgot-password step, carried through the OTP /
  /// reset chain so pages don't prop-drill it through routes.
  final String? pendingEmail;

  /// Opaque token issued once the OTP verifies, authorising the reset.
  final String? resetToken;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? failureKey,
    String? pendingEmail,
    String? resetToken,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      failureKey: failureKey,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      resetToken: resetToken ?? this.resetToken,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    failureKey,
    pendingEmail,
    resetToken,
  ];
}
