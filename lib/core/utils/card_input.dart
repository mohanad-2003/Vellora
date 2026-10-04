import 'package:flutter/services.dart';

/// Checks and formatting for the "add card" form. Nothing here stores or sends a
/// card number; it only helps the user catch typing mistakes before saving the
/// brand, last four digits and expiry.
class CardInput {
  CardInput._();

  /// Longest card number accepted (digits only).
  static const maxDigits = 19;

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  /// Luhn checksum: catches a mistyped digit or two adjacent digits swapped.
  static bool passesLuhn(String digits) {
    var sum = 0;
    var double = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = digits.codeUnitAt(i) - 0x30;
      if (d < 0 || d > 9) return false;
      if (double) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      double = !double;
    }
    return sum % 10 == 0;
  }

  static bool isPlausibleNumber(String value) {
    final digits = digitsOnly(value);
    return digits.length >= 12 &&
        digits.length <= maxDigits &&
        passesLuhn(digits);
  }

  /// `MM/YY` with a real month.
  static bool isValidExpiryFormat(String value) =>
      RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(value.trim());

  /// A card is good through the last day of its expiry month, so it is expired
  /// only once that month is over. [value] must already be a valid `MM/YY`.
  static bool isExpired(String value, {DateTime? now}) {
    final parts = value.trim().split('/');
    final month = int.parse(parts[0]);
    final year = 2000 + int.parse(parts[1]);
    final today = now ?? DateTime.now();
    return year < today.year || (year == today.year && month < today.month);
  }
}

/// Digits only, grouped in fours ("4242 4242 4242 4242"), at most
/// [CardInput.maxDigits] digits.
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = CardInput.digitsOnly(newValue.text);
    final capped = digits.length > CardInput.maxDigits
        ? digits.substring(0, CardInput.maxDigits)
        : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(capped[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Digits only, with the slash added after the month ("1228" → "12/28").
class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = CardInput.digitsOnly(newValue.text);
    if (digits.length > 4) digits = digits.substring(0, 4);
    // Deleting the slash should delete the month digit before it too.
    final deleting = newValue.text.length < oldValue.text.length;
    final text = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : (digits.length == 2 && !deleting ? '$digits/' : digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
