import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/theme/app_colors.dart';

/// Frosted deep-emerald glass: a blurred, tinted pill with a hairline edge and
/// a faint light from the top, and a soft shadow outside it. Whatever scrolls
/// behind shows through, blurred. Used by the bottom tab bar and the purchase
/// bar so the two read as one family.
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.radius = 32});

  final Widget child;
  final double radius;

  /// Light mode glass: warm white, the page's own family (F8F6F1), so the bar
  /// melts into it; the champagne button is the accent.
  static const Color glassLight = Color(0xFFFFFFFF);

  /// Kept for the gallery's dot chip, which floats over photos.
  static const Color glass = Color(0xFF0B3A30);

  /// The glass of dark mode: a neutral charcoal in the page's own family (the
  /// dark background is 0B0F0E), so the bar melts into it instead of reading as
  /// a green slab. Also the ring around badges and dots.
  static const Color glassDark = Color(0xFF161C1B);

  /// Text and icons on the glass: white on the dark one, deep emerald on the
  /// light one.
  static Color ink(BuildContext context) =>
      context.isDark ? Colors.white : kBrandNavy;

  /// The quieter version of [ink] (labels, struck-out prices, idle icons).
  static Color inkMuted(BuildContext context) =>
      ink(context).withValues(alpha: context.isDark ? 0.7 : 0.62);

  /// The glass colour itself: the ring that cuts badges out of the bar.
  static Color surface(BuildContext context) =>
      context.isDark ? glassDark : glassLight;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      // The shadow sits outside the clip so it is not cut off.
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.55 : 0.14),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: (dark ? glassDark : glassLight).withValues(
                alpha: dark ? 0.78 : 0.80,
              ),
              borderRadius: shape,
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.14)
                    : kBrandNavy.withValues(alpha: 0.10),
              ),
            ),
            // The light is the foreground: a gradient in `decoration` would
            // replace the tint instead of sitting on it.
            foregroundDecoration: BoxDecoration(
              borderRadius: shape,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: dark ? 0.10 : 0.55),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
