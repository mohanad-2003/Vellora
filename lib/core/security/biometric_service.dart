import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fingerprint / face unlock for the app.
///
/// "Biometric login" here is an app lock: once it is on for the signed-in
/// account, opening the app (or coming back after a while) asks for the
/// fingerprint or face before showing anything. The account stays signed in; no
/// password is stored. The setting remembers *which* account turned it on, so a
/// different account signing in on the same phone is not locked out by it.
@lazySingleton
class BiometricService {
  BiometricService(this._prefs);

  final SharedPreferences _prefs;
  final LocalAuthentication _auth = LocalAuthentication();

  static const _key = 'pref_biometric_lock_email';

  /// The phone has biometric hardware with something enrolled.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system prompt. False when cancelled, failed or unavailable.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  bool isEnabledFor(String? email) =>
      email != null && _prefs.getString(_key) == email.toLowerCase();

  Future<void> setEnabled(String email, {required bool enabled}) async {
    if (enabled) {
      await _prefs.setString(_key, email.toLowerCase());
    } else if (isEnabledFor(email)) {
      await _prefs.remove(_key);
    }
  }
}
