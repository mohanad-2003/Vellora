import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/extensions/num_extensions.dart';
import 'package:vellora/core/responsive/responsive.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/widgets/product_image.dart';
import 'package:vellora/features/orders/domain/order_entity.dart';

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

/// Month heading above a group of orders ("October 2026").
String formatOrderMonth(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMM(locale).format(date);
}

/// Order summary for the Orders list. Drawn straight on the page, with no card
/// around it: the list's dividers separate one order from the next.
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
    final first = order.items.isEmpty ? '' : order.items.first.name;

    return Semantics(
      button: true,
      label: '${order.number}, ${orderStatusLabel(context, order.status)}',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.pageGutter,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.number,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                        borderRadius: AppRadius.rMd,
                        child: SizedBox.square(
                          dimension: 56,
                          child: ProductImage(path: item.imagePath),
                        ),
                      ),
                    ),
                  if (extra > 0)
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: AppRadius.rMd,
                      ),
                      child: Text('+$extra', style: text.labelLarge),
                    ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        order.total.toPrice(),
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        l10n.cartItemsCount(order.itemCount),
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: colors.outline,
                  ),
                ],
              ),
              if (first.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (order.status != OrderStatus.cancelled) ...[
                const SizedBox(height: AppSpacing.md),
                _StatusProgress(status: order.status),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Three segments: placed, shipped, delivered. Filled up to the current step.
class _StatusProgress extends StatelessWidget {
  const _StatusProgress({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(context, status);
    final step = switch (status) {
      OrderStatus.processing => 1,
      OrderStatus.shipped => 2,
      OrderStatus.delivered => 3,
      OrderStatus.cancelled => 0,
    };
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < step ? color : context.colors.outlineVariant,
                borderRadius: AppRadius.rPill,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
