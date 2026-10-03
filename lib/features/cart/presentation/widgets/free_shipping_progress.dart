import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// "Add $X more for free shipping" banner with an animated progress bar.
/// Mirrors the cart summary rule: shipping is free once the subtotal passes
/// [threshold].
class FreeShippingProgress extends StatelessWidget {
  const FreeShippingProgress({
    super.key,
    required this.subtotal,
    this.threshold = 100,
  });

  final double subtotal;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final unlocked = subtotal >= threshold;
    final remaining = (threshold - subtotal).clamp(0, threshold).toDouble();
    final progress = (subtotal / threshold).clamp(0.0, 1.0);
    final accent = unlocked ? context.vellora.success : context.colors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: AppRadius.rMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                unlocked
                    ? Icons.local_shipping_rounded
                    : Icons.local_shipping_outlined,
                color: accent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  unlocked
                      ? context.l10n.freeShippingUnlocked
                      : context.l10n.addForFreeShipping(remaining.toPrice()),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.rPill,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: accent.withValues(alpha: 0.16),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
