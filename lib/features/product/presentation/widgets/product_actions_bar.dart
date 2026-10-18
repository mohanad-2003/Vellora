import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/widgets/app_button.dart';

/// Sticky purchase bar: Add to Cart + Buy Now, always within reach.
class ProductActionsBar extends StatelessWidget {
  const ProductActionsBar({
    super.key,
    required this.inStock,
    required this.onAddToCart,
    required this.onBuyNow,
    this.stockAlert = false,
    this.onStockAlert,
  });

  final bool inStock;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  /// The shopper already asked to be told when this sold-out product returns.
  final bool stockAlert;

  /// Asks (or cancels the ask) to be told when it returns; shown instead of the
  /// purchase buttons while the product is sold out.
  final VoidCallback? onStockAlert;

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
          child: !inStock && onStockAlert != null
              ? AppButton(
                  label: stockAlert ? l10n.cancelNotify : l10n.notifyWhenAvailable,
                  icon: stockAlert
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_active_outlined,
                  variant: stockAlert
                      ? AppButtonVariant.outline
                      : AppButtonVariant.primary,
                  haptic: true,
                  onPressed: onStockAlert,
                )
              : Row(
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
