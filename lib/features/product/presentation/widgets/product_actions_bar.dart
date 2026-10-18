import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/extensions/num_extensions.dart';
import 'package:vellora/core/theme/app_colors.dart';
import 'package:vellora/core/utils/haptics.dart';
import 'package:vellora/core/widgets/glass_panel.dart';

/// Sticky purchase bar, floating on frosted glass over the page: the total on
/// the start side, Add to Cart as a round button and Buy Now as the champagne
/// call to action. Sold out, it offers "notify me" instead.
///
/// The page scrolls under it, so the page leaves [clearance] at its end.
class ProductActionsBar extends StatelessWidget {
  const ProductActionsBar({
    super.key,
    required this.inStock,
    required this.onAddToCart,
    required this.onBuyNow,
    this.price,
    this.originalPrice,
    this.stockAlert = false,
    this.onStockAlert,
    this.addKey,
  });

  final bool inStock;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  /// What the shopper pays for the chosen quantity; the price block is left
  /// out when null.
  final double? price;

  /// The struck-through price for the same quantity, when it is on sale.
  final double? originalPrice;

  /// The shopper already asked to be told when this sold-out product returns.
  final bool stockAlert;

  /// Asks (or cancels the ask) to be told when it returns; shown instead of the
  /// purchase buttons while the product is sold out.
  final VoidCallback? onStockAlert;

  /// Marks the Add to Cart button so the product's picture can fly to it.
  final GlobalKey? addKey;

  /// Height the page keeps free at its end for the bar and its margins.
  static const double clearance = 104;

  static const double _height = 68;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final soldOutAsk = !inStock && onStockAlert != null;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: GlassPanel(
              radius: _height / 2,
              child: SizedBox(
                height: _height,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: soldOutAsk
                      ? _GoldButton(
                          label: stockAlert
                              ? l10n.cancelNotify
                              : l10n.notifyWhenAvailable,
                          icon: stockAlert
                              ? Icons.notifications_off_outlined
                              : Icons.notifications_active_outlined,
                          outlined: stockAlert,
                          onTap: onStockAlert,
                        )
                      : Row(
                          children: [
                            if (price != null) ...[
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 12,
                                  end: 8,
                                ),
                                child: _TotalBlock(
                                  price: price!,
                                  originalPrice: originalPrice,
                                ),
                              ),
                            ],
                            _RoundAction(
                              key: addKey,
                              icon: Icons.add_shopping_cart_rounded,
                              label: l10n.addToCart,
                              onTap: inStock ? onAddToCart : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _GoldButton(
                                label: l10n.buyNow,
                                onTap: inStock ? onBuyNow : null,
                              ),
                            ),
                          ],
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

/// "Total" over the price, in white on the glass; the sale price struck out.
class _TotalBlock extends StatelessWidget {
  const _TotalBlock({required this.price, this.originalPrice});

  final double price;
  final double? originalPrice;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 108),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.total,
              style: text.labelSmall?.copyWith(
                color: GlassPanel.inkMuted(context),
              ),
            ),
            Text(
              price.toPrice(),
              maxLines: 1,
              style: text.titleMedium?.copyWith(
                color: GlassPanel.ink(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (originalPrice != null && originalPrice! > price)
              Text(
                originalPrice!.toPrice(),
                maxLines: 1,
                style: text.labelSmall?.copyWith(
                  color: GlassPanel.inkMuted(context),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: GlassPanel.inkMuted(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A round glass button with an icon (Add to Cart).
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: GlassPanel.ink(context).withValues(alpha: 0.08),
          shape: CircleBorder(
            side: BorderSide(
              color: GlassPanel.ink(context).withValues(alpha: 0.24),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    Haptics.light();
                    onTap!();
                  },
            child: SizedBox.square(
              dimension: 52,
              child: Icon(icon, color: GlassPanel.ink(context), size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

/// The champagne capsule: the main action. [outlined] is the quieter version
/// (cancel a request) with a champagne edge instead of a fill.
class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final edge = context.isDark ? kBrandGold : kBrandNavy;
    final fg = outlined ? edge : kBrandNavy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: outlined ? Colors.transparent : kBrandGold,
          shape: StadiumBorder(
            side: outlined
                ? BorderSide(color: edge, width: 1.4)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    Haptics.light();
                    onTap!();
                  },
            child: SizedBox(
              height: 52,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: fg),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          style: context.textTheme.labelLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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
