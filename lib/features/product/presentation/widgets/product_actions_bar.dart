import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

/// Sticky purchase bar: Add to Cart + Buy Now, always within reach.
class ProductActionsBar extends StatelessWidget {
  const ProductActionsBar({
    super.key,
    required this.inStock,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final bool inStock;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.md,
            AppSpacing.screenH,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.addToCart,
                  icon: Icons.shopping_bag_outlined,
                  variant: AppButtonVariant.outline,
                  haptic: true,
                  onPressed: inStock ? onAddToCart : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: l10n.buyNow,
                  haptic: true,
                  onPressed: inStock ? onBuyNow : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
