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

  String _paymentLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (order.paymentKind) {
      OrderPaymentKind.cashOnDelivery => l10n.cashOnDelivery,
      _ => order.paymentDetail,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final colors = context.colors;

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: text.titleLarge)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );

    return ResponsiveCenter(
      maxWidth: 720,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.pageGutter,
          AppSpacing.sm,
          context.pageGutter,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.number, style: text.headlineSmall),
                    Text(
                      formatOrderDateTime(context, order.createdAt),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              OrderStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          section(l10n.orderTracking, OrderTimeline(order: order)),
          section(
            l10n.orderItems,
            Column(
              children: [
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ItemRow(item: item),
                  ),
              ],
            ),
          ),
          section(
            l10n.shippingAddress,
            _InfoBlock(
              icon: Icons.location_on_outlined,
              title: order.recipient,
              lines: [order.addressLine, order.city],
            ),
          ),
          section(
            l10n.paymentMethod,
            _InfoBlock(
              icon: Icons.credit_card_rounded,
              title: _paymentLabel(context),
            ),
          ),
          section(
            l10n.orderSummary,
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: AppRadius.rLg,
              ),
              child: Column(
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
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Divider(),
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(l10n.total, style: text.titleLarge)),
                      Text(
                        order.total.toPrice(),
                        style: text.headlineMedium?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

  Widget _line(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
          Text(
            value,
            style: context.textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
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
      children: [
        ClipRRect(
          borderRadius: AppRadius.rMd,
          child: SizedBox.square(
            dimension: 64,
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
                style: text.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
        Text(item.lineTotal.toPrice(), style: text.titleSmall),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.title,
    this.lines = const [],
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: AppRadius.rMd,
          ),
          child: Icon(icon, size: 20, color: context.colors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleSmall),
              for (final l in lines) Text(l, style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
