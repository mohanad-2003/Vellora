import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../models/checkout_models.dart';
import 'selectable_tile.dart';

String addressLabel(BuildContext context, ShippingAddress a) {
  final l10n = context.l10n;
  return switch (a.id) {
    'addr_home' => l10n.addressHome,
    'addr_work' => l10n.addressWork,
    _ => a.label,
  };
}

/// Shipping address as a (selectable) tile.
class AddressTile extends StatelessWidget {
  const AddressTile({
    super.key,
    required this.address,
    required this.selected,
    this.onTap,
    this.showRadio = false,
  });

  final ShippingAddress address;
  final bool selected;
  final VoidCallback? onTap;
  final bool showRadio;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rLg,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TileIcon(icon: Icons.location_on_outlined),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(address.recipient, style: text.titleSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: AppRadius.rSm,
                          ),
                          child: Text(
                            addressLabel(context, address),
                            style: text.labelSmall?.copyWith(
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${address.line}\n${address.city}', style: text.bodySmall),
                    const SizedBox(height: 2),
                    // Phone numbers read left-to-right in every locale.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(address.phone, style: text.bodySmall),
                      ),
                    ),
                  ],
                ),
              ),
              if (showRadio)
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? colors.primary : colors.outline,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delivery speed option.
class DeliveryTile extends StatelessWidget {
  const DeliveryTile({
    super.key,
    required this.option,
    required this.selected,
    required this.shippingFee,
    required this.onTap,
  });

  final DeliveryOption option;
  final bool selected;

  /// What this option costs for the current cart.
  final double shippingFee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final express = option.kind == DeliveryKind.express;
    return SelectableTile(
      selected: selected,
      onTap: onTap,
      leading: TileIcon(
        icon: express ? Icons.bolt_rounded : Icons.local_shipping_outlined,
      ),
      title: express ? l10n.deliveryExpress : l10n.deliveryStandard,
      subtitle: l10n.deliveryEta(option.minDays, option.maxDays),
      trailing: Text(
        shippingFee == 0 ? l10n.free : shippingFee.toPrice(),
        style: context.textTheme.titleSmall?.copyWith(
          color: shippingFee == 0 ? context.vellora.success : null,
        ),
      ),
    );
  }
}

/// Payment method option with brand logo (or fallback icon).
class PaymentTile extends StatelessWidget {
  const PaymentTile({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethodOption method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = method.kind == PaymentKind.cashOnDelivery
        ? l10n.cashOnDelivery
        : method.title;
    final subtitle = method.kind == PaymentKind.cashOnDelivery
        ? l10n.payOnArrival
        : method.subtitle;

    final fallback = switch (method.kind) {
      PaymentKind.cashOnDelivery => Icons.payments_outlined,
      PaymentKind.paypal => Icons.account_balance_wallet_outlined,
      PaymentKind.card => Icons.credit_card_rounded,
    };

    return SelectableTile(
      selected: selected,
      onTap: onTap,
      title: title,
      subtitle: subtitle,
      leading: TileIcon(
        icon: fallback,
        child: method.assetPath == null
            ? null
            : Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  method.assetPath!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      Icon(fallback, color: context.colors.primary),
                ),
              ),
      ),
    );
  }
}

/// Compact, read-only cart line for the order review.
class OrderItemRow extends StatelessWidget {
  const OrderItemRow({super.key, required this.item});

  final CartItemEntity item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final variant = [
      if (item.color != null && item.color!.isNotEmpty)
        colorLabel(context, item.color!),
      if (item.size != null && item.size!.isNotEmpty) item.size!,
    ].join(' · ');

    return Row(
      children: [
        ClipRRect(
          borderRadius: AppRadius.rMd,
          child: SizedBox.square(
            dimension: 56,
            child: ProductImage(path: item.imagePath),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall,
              ),
              if (variant.isNotEmpty) Text(variant, style: text.bodySmall),
              Text(
                '${item.quantity} × ${item.price.toPrice()}',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          item.lineTotal.toPrice(),
          style: text.titleSmall?.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }
}
