import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../utils/haptics.dart';

/// Heart toggle with a small "pop" animation and a subtle haptic.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 36,
    this.floating = true,
    this.discColor,
  });

  final bool isFavorite;
  final VoidCallback? onToggle;
  final double size;

  /// Draws a translucent surface disc behind the heart (for use over photos).
  final bool floating;

  /// Overrides the disc colour when [floating] (default: a translucent surface).
  final Color? discColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final target = size < 48 ? 48.0 : size;

    return Semantics(
      button: true,
      toggled: isFavorite,
      label: isFavorite ? l10n.removeFromWishlist : l10n.addToWishlist,
      excludeSemantics: true,
      onTap: onToggle,
      child: SizedBox.square(
        dimension: target,
        child: Center(
          child: Material(
            color: floating
                ? (discColor ?? colors.surface.withValues(alpha: 0.92))
                : Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggle == null
                  ? null
                  : () {
                      Haptics.selection();
                      onToggle!();
                    },
              child: SizedBox.square(
                dimension: size,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(
                      parent: anim,
                      curve: Curves.elasticOut,
                    ),
                    child: child,
                  ),
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(isFavorite),
                    size: size * 0.5,
                    color: isFavorite
                        ? context.vellora.accent
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
