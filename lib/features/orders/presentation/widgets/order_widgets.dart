import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/order_entity.dart';

String orderStatusLabel(BuildContext context, OrderStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    OrderStatus.processing => l10n.orderStatusProcessing,
    OrderStatus.shipped => l10n.orderStatusShipped,
    OrderStatus.delivered => l10n.orderStatusDelivered,
    OrderStatus.cancelled => l10n.orderStatusCancelled,
  };
}

Color orderStatusColor(BuildContext context, OrderStatus status) {
  final vellora = context.vellora;
  return switch (status) {
    OrderStatus.processing => vellora.warning,
    OrderStatus.shipped => context.colors.primary,
    OrderStatus.delivered => vellora.success,
    OrderStatus.cancelled => context.colors.error,
  };
}

String formatOrderDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).format(date);
}

String formatOrderDateTime(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).add_jm().format(date);
}

/// Coloured pill showing an order's status.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: AppRadius.rPill,
      ),
      child: Text(
        orderStatusLabel(context, status),
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Order summary row for the Orders list.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final OrderEntity order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    final l10n = context.l10n;
    final shown = order.items.take(3).toList();
    final extra = order.items.length - shown.length;

    return Semantics(
      button: true,
      label: '${order.number}, ${orderStatusLabel(context, order.status)}',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rLg,
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(order.number, style: text.titleSmall),
                    ),
                    OrderStatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  formatOrderDate(context, order.createdAt),
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    for (final item in shown)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ClipRRect(
                          borderRadius: AppRadius.rSm,
                          child: SizedBox.square(
                            dimension: 52,
                            child: ProductImage(path: item.imagePath),
                          ),
                        ),
                      ),
                    if (extra > 0)
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: AppRadius.rSm,
                        ),
                        child: Text('+$extra', style: text.labelLarge),
                      ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.cartItemsCount(order.itemCount),
                          style: text.bodySmall,
                        ),
                        Text(
                          order.total.toPrice(),
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.viewDetails,
                        style: text.labelLarge?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
