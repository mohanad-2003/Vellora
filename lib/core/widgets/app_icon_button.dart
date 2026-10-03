import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Circular, tonal icon button with a guaranteed 48dp touch target. Used for
/// back buttons, header actions and card overlays.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 40,
    this.iconSize = 20,
    this.filled = true,
    this.color,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// Announced by screen readers. Required — an icon alone carries no meaning.
  final String semanticLabel;
  final double size;
  final double iconSize;
  final bool filled;
  final Color? color;

  /// Optional badge (e.g. a count) anchored to the top-end corner.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.onSurface;
    final target = size < 48 ? 48.0 : size;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox.square(
        dimension: target,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: filled
                    ? context.colors.surfaceContainerHighest
                    : Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  customBorder: const CircleBorder(),
                  child: SizedBox.square(
                    dimension: size,
                    child: Icon(icon, size: iconSize, color: fg),
                  ),
                ),
              ),
              if (badge != null)
                PositionedDirectional(top: -4, end: -4, child: badge!),
            ],
          ),
        ),
      ),
    );
  }
}
