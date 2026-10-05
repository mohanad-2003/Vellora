import 'package:equatable/equatable.dart';

/// What an authenticator app needs to start generating codes for the account.
class TwoFactorSetup extends Equatable {
  const TwoFactorSetup({required this.secret, required this.otpauthUrl});

  /// Base32 key to type into the app by hand.
  final String secret;

  /// `otpauth://` link that opens the key in an installed authenticator app.
  final String otpauthUrl;

  @override
  List<Object?> get props => [secret, otpauthUrl];
}
