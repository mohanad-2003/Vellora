import 'package:google_sign_in/google_sign_in.dart';

/// Why Google sign-in could not give an ID token (not the person backing out: that is just `null`).
class GoogleSignInUnavailable implements Exception {
  const GoogleSignInUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'GoogleSignInUnavailable($reason)';
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
    throw GoogleSignInUnavailable('${e.code.name}: ${e.description ?? ''}');
  }
}
