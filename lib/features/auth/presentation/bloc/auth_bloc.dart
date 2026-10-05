import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_cached_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._login,
    this._register,
    this._forgotPassword,
    this._verifyOtp,
    this._resetPassword,
    this._getCachedUser,
    this._logout,
  ) : super(const AuthState()) {
    on<AuthCheckStatusRequested>(_onCheckStatus);
    on<AuthLoginRequested>(_onLogin);
    on<AuthTwoFactorSubmitted>(_onTwoFactor);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthOtpVerifyRequested>(_onVerifyOtp);
    on<AuthResetPasswordRequested>(_onResetPassword);
    on<AuthLogoutRequested>(_onLogout);
  }

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final ForgotPasswordUseCase _forgotPassword;
  final VerifyOtpUseCase _verifyOtp;
  final ResetPasswordUseCase _resetPassword;
  final GetCachedUserUseCase _getCachedUser;
  final LogoutUseCase _logout;

  Future<void> _onCheckStatus(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _getCachedUser(const NoParams());
    result.match(
      (failure) => emit(state.copyWith(status: AuthStatus.unauthenticated)),
      (user) => emit(
        user == null
            ? state.copyWith(status: AuthStatus.unauthenticated)
            : state.copyWith(status: AuthStatus.authenticated, user: user),
      ),
    );
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _login(
      LoginParams(email: event.email, password: event.password),
    );
    result.match(
      (failure) => emit(
        // The password was right but a code is needed: not an error.
        failure is ValidationFailure && failure.code == twoFactorRequiredCode
            ? state.copyWith(
                status: AuthStatus.twoFactorRequired,
                twoFactorToken: failure.message,
              )
            : state.copyWith(
                status: AuthStatus.failure,
                failureKey: failure.l10nKey,
              ),
      ),
      (user) =>
          emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> _onTwoFactor(
    AuthTwoFactorSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _login(
      LoginParams(
        email: '',
        password: '',
        challengeToken: state.twoFactorToken,
        code: event.code,
      ),
    );
    result.match(
      // The challenge is kept (copyWith carries it) so a mistyped code can be
      // retried; it expires on its own after a few minutes.
      (failure) => emit(
        state.copyWith(status: AuthStatus.failure, failureKey: failure.l10nKey),
      ),
      (user) =>
          emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _register(
      RegisterParams(
        name: event.name,
        email: event.email,
        password: event.password,
      ),
    );
    result.match(
      (failure) => emit(
        state.copyWith(status: AuthStatus.failure, failureKey: failure.l10nKey),
      ),
      (user) =>
          emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _forgotPassword(
      ForgotPasswordParams(email: event.email),
    );
    result.match(
      (failure) => emit(
        state.copyWith(status: AuthStatus.failure, failureKey: failure.l10nKey),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.passwordResetSent,
          pendingEmail: event.email,
        ),
      ),
    );
  }

  Future<void> _onVerifyOtp(
    AuthOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _verifyOtp(
      VerifyOtpParams(email: state.pendingEmail ?? '', code: event.code),
    );
    result.match(
      (failure) => emit(
        state.copyWith(status: AuthStatus.failure, failureKey: failure.l10nKey),
      ),
      (token) => emit(
        state.copyWith(status: AuthStatus.otpVerified, resetToken: token),
      ),
    );
  }

  Future<void> _onResetPassword(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _resetPassword(
      ResetPasswordParams(
        resetToken: state.resetToken ?? '',
        newPassword: event.newPassword,
      ),
    );
    result.match(
      (failure) => emit(
        state.copyWith(status: AuthStatus.failure, failureKey: failure.l10nKey),
      ),
      (_) => emit(state.copyWith(status: AuthStatus.passwordResetSuccess)),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout(const NoParams());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
