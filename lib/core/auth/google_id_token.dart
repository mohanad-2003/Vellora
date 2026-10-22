import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// What went wrong, so the person is told something useful instead of "check your connection".
enum GoogleSignInProblem {
  /// This device has no Google account yet: add one in the phone's settings.
  noAccount,

  /// This build of the app has no Google client id (the `google-services.json` it was built with is old).
  notConfigured,

  /// Anything else; the reason is printed in the debug console.
  other,
}

/// Why Google sign-in could not give an ID token (not the person backing out: that is just `null`).
class GoogleSignInUnavailable implements Exception {
  const GoogleSignInUnavailable(
    this.reason, {
    this.problem = GoogleSignInProblem.other,
  });

  final String reason;
  final GoogleSignInProblem problem;

  @override
  String toString() => 'GoogleSignInUnavailable($problem: $reason)';
}

/// Asks Google who the person is and returns the signed ID token the server verifies, or `null` when
/// they close the account chooser. The server trusts nothing else about them.
///
/// On Android the Web client id is read from `google-services.json` (`default_web_client_id`), so it needs
/// no setting here; pass `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` to use another one (and on iOS).
typedef GoogleIdTokenSource = Future<String?> Function();

/// The real source. Replaceable in tests.
GoogleIdTokenSource googleIdTokenSource = _askGoogle;

const _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

Future<void>? _initialized;

Future<String?> _askGoogle() async {
  final signIn = GoogleSignIn.instance;
  if (!signIn.supportsAuthenticate()) {
    throw const GoogleSignInUnavailable('not supported on this platform');
  }
  try {
    _initialized ??= signIn.initialize(
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
    await _initialized;
    // Forget the earlier choice, so a shared phone shows the account chooser every time.
    await signIn.signOut();
    final account = await signIn.authenticate();
    return account.authentication.idToken;
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) return null;
    // A failed start is not remembered, so the next tap tries again.
    _initialized = null;
    final reason = '${e.code.name}: ${e.description ?? ''}';
    if (kDebugMode) debugPrint('Google sign-in failed: $reason');
    throw GoogleSignInUnavailable(reason, problem: _problemOf(e));
  }
}

GoogleSignInProblem _problemOf(GoogleSignInException e) {
  // No Google account on the phone: the Android sign-in says so in the description.
  if (e.code == GoogleSignInExceptionCode.unknownError &&
      (e.description ?? '').toLowerCase().contains('no credential')) {
    return GoogleSignInProblem.noAccount;
  }
  if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
    return GoogleSignInProblem.notConfigured;
  }
  return GoogleSignInProblem.other;
}
