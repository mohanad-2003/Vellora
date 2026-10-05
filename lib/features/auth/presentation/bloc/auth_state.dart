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

  /// Password accepted; waiting for the authenticator code.
  twoFactorRequired,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.failureKey,
    this.pendingEmail,
    this.resetToken,
    this.twoFactorToken,
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

  /// Short-lived challenge from the server, sent back with the 2FA code.
  final String? twoFactorToken;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? failureKey,
    String? pendingEmail,
    String? resetToken,
    String? twoFactorToken,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      failureKey: failureKey,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      resetToken: resetToken ?? this.resetToken,
      twoFactorToken: twoFactorToken ?? this.twoFactorToken,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    failureKey,
    pendingEmail,
    resetToken,
    twoFactorToken,
  ];
}
