import 'package:flutter/services.dart';

/// Thin wrapper over Flutter's built-in haptics so call sites stay intention
/// revealing and the set of haptic moments stays small and consistent.
class Haptics {
  Haptics._();

  /// Selecting / toggling something lightweight (favorite, chip, tab).
  static void selection() => HapticFeedback.selectionClick();

  /// Confirming an action (add to cart, apply promo).
  static void light() => HapticFeedback.lightImpact();

  /// A significant completion (order placed).
  static void success() => HapticFeedback.mediumImpact();
}
