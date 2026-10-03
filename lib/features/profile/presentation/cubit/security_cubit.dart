import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class SecurityState extends Equatable {
  const SecurityState({
    this.biometrics = false,
    this.twoFactor = false,
    this.loginAlerts = true,
  });

  final bool biometrics;
  final bool twoFactor;
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

/// Security screen logic: the account actions go to the server (change
/// password, delete account); the three switches are session-only preferences
/// with no server behind them yet.
@injectable
class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit(this._auth) : super(const SecurityState());

  final AuthRepository _auth;

  void toggleBiometrics(bool v) => emit(state.copyWith(biometrics: v));
  void toggleTwoFactor(bool v) => emit(state.copyWith(twoFactor: v));
  void toggleLoginAlerts(bool v) => emit(state.copyWith(loginAlerts: v));

  /// Returns a failure key, or null when the password was changed.
  Future<String?> changePassword(String current, String next) async {
    final result = await _auth.changePassword(
      currentPassword: current,
      newPassword: next,
    );
    return result.match<String?>((Failure f) => f.l10nKey, (_) => null);
  }

  /// Deletes the account and signs out locally. Returns a failure key, or null
  /// on success.
  Future<String?> deleteAccount(String password) async {
    final result = await _auth.deleteAccount(password: password);
    return result.match<String?>((Failure f) => f.l10nKey, (_) => null);
  }
}
