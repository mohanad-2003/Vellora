import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../utils/haptics.dart';

/// Compact "− n +" stepper used in product details and the cart. Buttons keep
/// a 44dp touch target and announce their action to screen readers.
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.compact = false,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// Smaller variant for list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final box = compact ? 36.0 : 44.0;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: AppRadius.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            semanticLabel: l10n.decreaseQuantity,
            size: box,
            onTap: quantity > min
                ? () {
                    Haptics.selection();
                    onChanged(quantity - 1);
                  }
                : null,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: compact ? 24 : 32),
            child: Semantics(
              label: '${l10n.quantity}: $quantity',
              excludeSemantics: true,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            semanticLabel: l10n.increaseQuantity,
            size: box,
            onTap: quantity < max
                ? () {
                    Haptics.selection();
                    onChanged(quantity + 1);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: size / 2,
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? context.colors.onSurface
                : context.colors.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
