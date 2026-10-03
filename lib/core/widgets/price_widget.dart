import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../extensions/num_extensions.dart';
import '../theme/app_radius.dart';

/// Current price with an optional struck-through original price.
class PriceWidget extends StatelessWidget {
  const PriceWidget({
    super.key,
    required this.price,
    this.originalPrice,
    this.large = false,
    this.color,
  });

  final double price;
  final double? originalPrice;

  /// Larger typography for product details and totals.
  final bool large;
  final Color? color;

  bool get _hasDiscount => originalPrice != null && originalPrice! > price;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final priceStyle = (large ? text.headlineMedium : text.titleMedium)
        ?.copyWith(color: color ?? context.colors.onSurface);

    return Semantics(
      label: _hasDiscount
          ? '${price.toPrice()}, ${context.l10n.wasPrice(originalPrice!.toPrice())}'
          : price.toPrice(),
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 6,
        children: [
          Text(price.toPrice(), style: priceStyle, maxLines: 1),
          if (_hasDiscount)
            Text(
              originalPrice!.toPrice(),
              maxLines: 1,
              style: (large ? text.bodyLarge : text.labelMedium)?.copyWith(
                decoration: TextDecoration.lineThrough,
                decorationColor: context.colors.outline,
                color: context.colors.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

/// "-25%" pill shown over product photos and next to prices.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent, this.large = false});

  /// Derives the percentage from the two prices.
  factory DiscountBadge.fromPrices({
    Key? key,
    required double price,
    required double originalPrice,
    bool large = false,
  }) =>
      DiscountBadge(
        key: key,
        percent: (((originalPrice - price) / originalPrice) * 100).round(),
        large: large,
      );

  final int percent;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.percentOff(percent),
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 7,
          vertical: large ? 5 : 3,
        ),
        decoration: BoxDecoration(
          color: context.colors.tertiary,
          borderRadius: large ? AppRadius.rSm : AppRadius.rSm,
        ),
        child: Text(
          '-$percent%',
          style: (large ? context.textTheme.labelMedium : context.textTheme.labelSmall)
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
