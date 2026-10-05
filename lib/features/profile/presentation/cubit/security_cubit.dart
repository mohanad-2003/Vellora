import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../auth/domain/entities/two_factor_setup.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class SecurityState extends Equatable {
  const SecurityState({
    this.biometrics = false,
    this.twoFactor,
    this.loginAlerts = true,
  });

  /// Fingerprint / face unlock is on for this account on this phone.
  final bool biometrics;

  /// Two-factor sign-in is on for the account. Null until the server answered
  /// (or when it could not be reached), so the switch stays disabled rather
  /// than showing a guess.
  final bool? twoFactor;

  final bool loginAlerts;

  SecurityState copyWith({
    bool? biometrics,
    bool? twoFactor,
    bool? loginAlerts,
  }) => SecurityState(
    biometrics: biometrics ?? this.biometrics,
    twoFactor: twoFactor ?? this.twoFactor,
    loginAlerts: loginAlerts ?? this.loginAlerts,
  );

  @override
  List<Object?> get props => [biometrics, twoFactor, loginAlerts];
}

enum BiometricResult { changed, unavailable, cancelled }

/// Security screen logic. Change password and two-factor go to the server;
/// biometric login is a setting on this phone; the login-alerts switch is a
/// session-only preference with no server behind it yet.
@injectable
class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit(this._auth, this._biometrics) : super(const SecurityState());

  final AuthRepository _auth;
  final BiometricService _biometrics;

  void toggleLoginAlerts(bool v) => emit(state.copyWith(loginAlerts: v));

  /// Reads the saved settings: biometric from this phone, two-factor from the
  /// server.
  Future<void> load(String? email) async {
    emit(state.copyWith(biometrics: _biometrics.isEnabledFor(email)));
    final result = await _auth.twoFactorStatus();
    if (isClosed) return;
    result.match((_) {}, (on) => emit(state.copyWith(twoFactor: on)));
  }

  /// Turns biometric login on (after the user proves it with their fingerprint
  /// or face) or off.
  Future<BiometricResult> setBiometrics({
    required bool enable,
    required String? email,
    required String reason,
  }) async {
    if (email == null) return BiometricResult.cancelled;
    if (enable) {
      if (!await _biometrics.isAvailable()) return BiometricResult.unavailable;
      if (!await _biometrics.authenticate(reason)) {
        return BiometricResult.cancelled;
      }
    }
    await _biometrics.setEnabled(email, enabled: enable);
    emit(state.copyWith(biometrics: enable));
    return BiometricResult.changed;
  }

  /// Returns a failure key, or null when the password was changed.
  Future<String?> changePassword(String current, String next) async {
    final result = await _auth.changePassword(
      currentPassword: current,
      newPassword: next,
    );
    return result.match<String?>((Failure f) => f.l10nKey, (_) => null);
  }

  /// Creates the authenticator key. Not active until [enableTwoFactor].
  Future<({TwoFactorSetup? setup, String? error})> startTwoFactorSetup() async {
    final result = await _auth.startTwoFactorSetup();
    return result.match(
      (Failure f) => (setup: null, error: f.l10nKey),
      (setup) => (setup: setup, error: null),
    );
  }

  /// Returns a failure key, or null once two-factor is on.
  Future<String?> enableTwoFactor(String code) async {
    final result = await _auth.enableTwoFactor(code: code);
    return result.match<String?>((Failure f) => f.l10nKey, (_) {
      emit(state.copyWith(twoFactor: true));
      return null;
    });
  }

  /// Returns a failure key, or null once two-factor is off.
  Future<String?> disableTwoFactor(String password, String code) async {
    final result = await _auth.disableTwoFactor(password: password, code: code);
    return result.match<String?>((Failure f) => f.l10nKey, (_) {
      emit(state.copyWith(twoFactor: false));
      return null;
    });
  }
}
