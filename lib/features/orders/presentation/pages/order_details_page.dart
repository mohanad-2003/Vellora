import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../domain/order_entity.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/order_returns.dart';
import '../widgets/order_timeline.dart';
import '../widgets/order_widgets.dart';
import '../../../../core/widgets/failure_state_view.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderDetailCubit>()..load(orderId),
      child: _OrderDetailsView(orderId: orderId),
    );
  }
}

class _OrderDetailsView extends StatelessWidget {
  const _OrderDetailsView({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBarWidget(title: l10n.orderDetails),
      body: SafeArea(
        top: false,
        child: BlocBuilder<OrderDetailCubit, OrderDetailState>(
          builder: (context, state) => switch (state.status) {
            OrderDetailStatus.loading => const ListSkeleton(),
            OrderDetailStatus.notFound => EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              illustration: EmptyArt.notFound,
              title: l10n.orderNotFoundTitle,
              message: l10n.orderNotFoundBody,
            ),
            OrderDetailStatus.error => FailureStateView(
              failureKey: state.failureKey,
              onRetry: () => context.read<OrderDetailCubit>().load(orderId),
            ),
            OrderDetailStatus.loaded => _Details(
              order: state.order!,
              onCancel: () => _confirmCancel(context),
            ),
          },
        ),
      ),
    );
  }
}

/// Asks for confirmation, then cancels the order through the cubit.
void _confirmCancel(BuildContext context) {
  final cubit = context.read<OrderDetailCubit>();
  final l10n = context.l10n;
  AppBottomSheet.show(
    context,
    child: _CancelSheet(
      title: l10n.cancelOrderTitle,
      body: l10n.cancelOrderBody,
      onConfirm: cubit.cancel,
      onDone: () {
        Navigator.of(context).pop();
        AppSnackbar.success(context, l10n.orderCancelled);
        // Cancelling adds a notification: show its dot right away.
        sl<UnreadNotificationsCubit>().refresh();
      },
    ),
  );
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet({
    required this.title,
    required this.body,
    required this.onConfirm,
    required this.onDone,
  });

  final String title;
  final String body;

  /// Returns a failure key, or null once the order is cancelled.
  final Future<String?> Function() onConfirm;
  final VoidCallback onDone;

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await widget.onConfirm();
    if (!mounted) return;
    if (failure == null) {
      widget.onDone();
    } else {
      setState(() {
        _busy = false;
        _error = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cancel_outlined, color: context.colors.error, size: 48),
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.title,
          style: context.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.body,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            tr(context, _error!),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: l10n.cancelOrder,
          icon: Icons.cancel_outlined,
          isLoading: _busy,
          onPressed: _confirm,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l10n.keepOrder,
          variant: AppButtonVariant.outline,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.order, required this.onCancel});

  final OrderEntity order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final address = _DetailSection(
      title: l10n.shippingAddress,
      icon: Icons.location_on_outlined,
      child: _InfoBlock(
        title: order.recipient,
        lines: [order.addressLine, order.city],
      ),
    );
    final payment = _DetailSection(
      title: l10n.paymentMethod,
      icon: order.paymentKind == OrderPaymentKind.cashOnDelivery
          ? Icons.payments_outlined
          : Icons.credit_card_rounded,
      child: _InfoBlock(
        title: order.paymentKind == OrderPaymentKind.cashOnDelivery
            ? l10n.cashOnDelivery
            : order.paymentDetail,
        lines: [
          if (order.paymentKind == OrderPaymentKind.cashOnDelivery)
            l10n.payOnArrival,
        ],
      ),
    );

    return ResponsiveCenter(
      maxWidth: 800,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.pageGutter,
          AppSpacing.md,
          context.pageGutter,
          AppSpacing.xxxl,
        ),
        children: [
          _OrderOverview(order: order),
          const SizedBox(height: AppSpacing.xxl),
          _DetailSection(
            title: l10n.orderTracking,
            icon: Icons.route_outlined,
            child: OrderTimeline(order: order),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailSection(
            title: l10n.orderItems,
            icon: Icons.shopping_bag_outlined,
            subtitle: l10n.cartItemsCount(order.itemCount),
            child: Column(
              children: [
                for (var i = 0; i < order.items.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Divider(),
                    ),
                  _ItemRow(item: order.items[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600 || context.textScale > 1.3) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    address,
                    const SizedBox(height: AppSpacing.lg),
                    payment,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: address),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: payment),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailSection(
            title: l10n.orderSummary,
            icon: Icons.receipt_long_outlined,
            child: _OrderReceipt(order: order),
          ),
          const SizedBox(height: AppSpacing.xxl),
          OrderReturnsSection(order: order),
          if (order.status == OrderStatus.processing)
            AppButton(
              label: l10n.cancelOrder,
              icon: Icons.cancel_outlined,
              variant: AppButtonVariant.outline,
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }
}

class _OrderOverview extends StatelessWidget {
  const _OrderOverview({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final statusColor = orderStatusColor(context, order.status);
    final icon = switch (order.status) {
      OrderStatus.processing => Icons.inventory_2_outlined,
      OrderStatus.shipped => Icons.local_shipping_outlined,
      OrderStatus.delivered => Icons.task_alt_rounded,
      OrderStatus.cancelled => Icons.cancel_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.rXxl,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [colors.primaryContainer, colors.surface],
        ),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.rLg,
                ),
                child: Icon(icon, color: statusColor, size: 28),
              ),
              OrderStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(context.l10n.orderNumber, style: text.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            order.number,
            textDirection: TextDirection.ltr,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatOrderDateTime(context, order.createdAt),
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Divider(),
          ),
          Wrap(
            spacing: AppSpacing.xxl,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                order.total.toPrice(),
                style: text.headlineSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                context.l10n.cartItemsCount(order.itemCount),
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.rXl,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.07),
                  borderRadius: AppRadius.rMd,
                ),
                child: Icon(icon, size: 20, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: context.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

class _OrderReceipt extends StatelessWidget {
  const _OrderReceipt({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _line(context, l10n.subtotal, order.subtotal.toPrice()),
        if (order.discount > 0)
          _line(
            context,
            l10n.discount,
            '-${order.discount.toPrice()}',
            color: context.vellora.success,
          ),
        _line(
          context,
          l10n.shipping,
          order.shipping == 0 ? l10n.free : order.shipping.toPrice(),
          color: order.shipping == 0 ? context.vellora.success : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.07),
            borderRadius: AppRadius.rMd,
          ),
          child: _line(context, l10n.total, order.total.toPrice(), total: true),
        ),
      ],
    );
  }

  Widget _line(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool total = false,
  }) {
    final labelWidget = Text(
      label,
      style: total
          ? context.textTheme.titleMedium
          : context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
    );
    final valueWidget = Text(
      value,
      style:
          (total ? context.textTheme.titleLarge : context.textTheme.titleSmall)
              ?.copyWith(
                color: total ? context.colors.primary : color,
                fontWeight: total ? FontWeight.w800 : FontWeight.w600,
              ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 250 || context.textScale > 1.3) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: AppSpacing.xs),
                valueWidget,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: labelWidget),
              const SizedBox(width: AppSpacing.md),
              Flexible(child: valueWidget),
            ],
          );
        },
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItemEntity item;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final variant = [
      if (item.color != null) colorLabel(context, item.color!),
      if (item.size != null) item.size!,
    ].join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.rMd,
          child: SizedBox.square(
            dimension: 76,
            child: ProductImage(path: item.imagePath, semanticLabel: item.name),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: text.titleSmall),
              if (variant.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(variant, style: text.bodySmall),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${item.quantity} × ${item.price.toPrice()}',
                style: text.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.lineTotal.toPrice(),
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, this.lines = const []});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textTheme.titleSmall),
        for (final line in lines.where((line) => line.trim().isNotEmpty)) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            line,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }
}
