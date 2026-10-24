import 'package:flutter/material.dart';

import '../../../../core/shipping/shipping_rules.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// "Add $X more for free shipping" banner with an animated progress bar.
/// Mirrors the cart summary rule: shipping is free once the subtotal passes
/// [threshold].
class FreeShippingProgress extends StatelessWidget {
  const FreeShippingProgress({
    super.key,
    required this.subtotal,
    this.threshold,
  });

  final double subtotal;

  /// The free-shipping line; the shop's current rule when not given.
  final double? threshold;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ShippingRulesData>(
      valueListenable: ShippingRules.current,
      builder: (context, rules, _) =>
          _content(context, threshold ?? rules.freeThreshold),
    );
  }

  Widget _content(BuildContext context, double threshold) {
    final unlocked = subtotal >= threshold;
    final remaining = (threshold - subtotal).clamp(0, threshold).toDouble();
    final progress = (subtotal / threshold).clamp(0.0, 1.0);
    const accent = kBrandAccent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF0F4A3D), Color(0xFF0A2E26)],
        ),
        borderRadius: AppRadius.rXl,
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
                    color: Colors.white,
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
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                valueColor: const AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
