import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';

/// Frosted deep-emerald glass: a blurred, tinted pill with a hairline edge and
/// a faint light from the top, and a soft shadow outside it. Whatever scrolls
/// behind shows through, blurred. Used by the bottom tab bar and the purchase
/// bar so the two read as one family.
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.radius = 32});

  final Widget child;
  final double radius;

  /// Deep emerald, a little lighter than the brand's darkest green so the glass
  /// still reads as green over a light page.
  static const Color glass = Color(0xFF0B3A30);

  /// The darker glass of dark mode; also the ring around badges and dots.
  static const Color glassDark = Color(0xFF071F1A);

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
            color: Colors.black.withValues(alpha: dark ? 0.55 : 0.28),
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
              color: (dark ? glassDark : glass).withValues(
                alpha: dark ? 0.78 : 0.74,
              ),
              borderRadius: shape,
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            // The light is the foreground: a gradient in `decoration` would
            // replace the tint instead of sitting on it.
            foregroundDecoration: BoxDecoration(
              borderRadius: shape,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
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
