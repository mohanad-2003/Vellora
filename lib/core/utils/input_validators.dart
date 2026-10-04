import '../constants/app_constants.dart';

/// Pure validation helpers returning a stable l10n key on failure, or null on
/// success. The presentation layer resolves keys to localized copy.
class InputValidators {
  InputValidators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'fieldRequired';
    if (!_emailRegex.hasMatch(v)) return 'invalidEmail';
    return null;
  }

  /// A new password (sign-up, reset, change). [AppConstants.minPasswordLength]
  /// matches the API.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'fieldRequired';
    if (v.length < AppConstants.minPasswordLength) return 'passwordTooShort';
    return null;
  }

  /// The password typed to sign in. Only required: accounts created under an
  /// older, shorter rule must still be able to get in.
  static String? loginPassword(String? value) =>
      (value ?? '').isEmpty ? 'fieldRequired' : null;

  static String? confirmPassword(String? value, String original) {
    final v = value ?? '';
    if (v.isEmpty) return 'fieldRequired';
    if (v != original) return 'passwordsDoNotMatch';
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'fieldRequired';
    if (v.length < 2) return 'nameTooShort';
    return null;
  }

  static String? required(String? value) {
    if ((value?.trim() ?? '').isEmpty) return 'fieldRequired';
    return null;
  }
}
