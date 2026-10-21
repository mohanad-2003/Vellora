import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../data/orders_remote_datasource.dart';
import '../../domain/order_entity.dart';
import '../../domain/return_entity.dart';
import 'order_widgets.dart';

String returnStatusLabel(BuildContext context, ReturnStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    ReturnStatus.requested => l10n.returnStatusRequested,
    ReturnStatus.approved => l10n.returnStatusApproved,
    ReturnStatus.rejected => l10n.returnStatusRejected,
    ReturnStatus.received => l10n.returnStatusReceived,
    ReturnStatus.completed => l10n.returnStatusCompleted,
  };
}

Color returnStatusColor(BuildContext context, ReturnStatus status) {
  final vellora = context.vellora;
  return switch (status) {
    ReturnStatus.requested => vellora.warning,
    ReturnStatus.approved || ReturnStatus.received => context.colors.primary,
    ReturnStatus.completed => vellora.success,
    ReturnStatus.rejected => context.colors.error,
  };
}

String _reasonLabel(BuildContext context, ReturnReason reason) {
  final l10n = context.l10n;
  return switch (reason) {
    ReturnReason.wrongSize => l10n.returnReasonWrongSize,
    ReturnReason.damaged => l10n.returnReasonDamaged,
    ReturnReason.notAsDescribed => l10n.returnReasonNotAsDescribed,
    ReturnReason.changedMind => l10n.returnReasonChangedMind,
    ReturnReason.other => l10n.returnReasonOther,
  };
}

/// On a delivered order: the returns already asked for, and the button to ask for one.
class OrderReturnsSection extends StatefulWidget {
  const OrderReturnsSection({super.key, required this.order});

  final OrderEntity order;

  @override
  State<OrderReturnsSection> createState() => _OrderReturnsSectionState();
}

class _OrderReturnsSectionState extends State<OrderReturnsSection> {
  List<ReturnEntity>? _returns;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await sl<OrdersRemoteDataSource>().getReturns();
      if (!mounted) return;
      setState(
        () => _returns = all
            .where((r) => r.orderId == widget.order.id)
            .toList(growable: false),
      );
    } catch (_) {
      // The section simply stays hidden when the list cannot be read.
      if (mounted) setState(() => _returns ??= const []);
    }
  }

  /// Units of each order line that no open return holds.
  Map<String, int> get _left {
    final left = {for (final i in widget.order.items) i.id: i.quantity};
    for (final r in _returns ?? const <ReturnEntity>[]) {
      if (!r.holdsItems) continue;
      for (final i in r.items) {
        left[i.orderItemId] = (left[i.orderItemId] ?? 0) - i.quantity;
      }
    }
    return left;
  }

  Future<void> _ask() async {
    final done = await AppBottomSheet.show<bool>(
      context,
      child: _ReturnSheet(order: widget.order, left: _left),
    );
    if (done == true) {
      sl<UnreadNotificationsCubit>().refresh();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final returns = _returns;
    if (returns == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final canAsk =
        widget.order.status == OrderStatus.delivered &&
        widget.order.items.any((i) => i.id.isNotEmpty) &&
        _left.values.any((n) => n > 0);
    if (returns.isEmpty && !canAsk) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.returnsTitle, style: context.textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final r in returns) _ReturnCard(ret: r),
          if (canAsk)
            AppButton(
              label: l10n.returnItems,
              icon: Icons.assignment_return_outlined,
              variant: AppButtonVariant.outline,
              onPressed: _ask,
            ),
        ],
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({required this.ret});

  final ReturnEntity ret;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final color = returnStatusColor(context, ret.status);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: AppRadius.rLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatOrderDate(context, ret.createdAt),
                  style: text.bodySmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: AppRadius.rPill,
                ),
                child: Text(
                  returnStatusLabel(context, ret.status),
                  style: text.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final i in ret.items)
            Text('${i.quantity} × ${i.name}', style: text.titleSmall),
          if (ret.adminNote != null && ret.adminNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              ret.adminNote!,
              style: text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReturnSheet extends StatefulWidget {
  const _ReturnSheet({required this.order, required this.left});

  final OrderEntity order;
  final Map<String, int> left;

  @override
  State<_ReturnSheet> createState() => _ReturnSheetState();
}

class _ReturnSheetState extends State<_ReturnSheet> {
  final Map<String, int> _picked = {};
  ReturnReason _reason = ReturnReason.wrongSize;
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _step(String id, int delta, int max) {
    final next = ((_picked[id] ?? 0) + delta).clamp(0, max);
    setState(() => next == 0 ? _picked.remove(id) : _picked[id] = next);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await sl<OrdersRemoteDataSource>().requestReturn(
        widget.order.id,
        _picked,
        reason: _reasonLabel(context, _reason),
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppSnackbar.success(context, l10n.returnRequested);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is ValidationException
            ? l10n.returnNotAllowed
            : tr(context, mapExceptionToFailure(e).l10nKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final items = [
      for (final i in widget.order.items)
        if ((widget.left[i.id] ?? 0) > 0) i,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.returnItems,
          style: text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.returnItemsBody,
          style: text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final i in items)
          _PickRow(
            name: i.name,
            picked: _picked[i.id] ?? 0,
            max: widget.left[i.id]!,
            onStep: (d) => _step(i.id, d, widget.left[i.id]!),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.returnReason, style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final r in ReturnReason.values)
              ChoiceChip(
                label: Text(_reasonLabel(context, r)),
                selected: _reason == r,
                onSelected: _busy ? null : (_) => setState(() => _reason = r),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _note,
          maxLength: 500,
          maxLines: 3,
          minLines: 2,
          enabled: !_busy,
          decoration: InputDecoration(labelText: l10n.returnNote),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: text.bodySmall?.copyWith(color: context.colors.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.returnSend,
          icon: Icons.assignment_return_outlined,
          isLoading: _busy,
          onPressed: _picked.isEmpty ? null : _submit,
        ),
      ],
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.name,
    required this.picked,
    required this.max,
    required this.onStep,
  });

  final String name;
  final int picked;
  final int max;
  final void Function(int delta) onStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: context.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: context.l10n.decrease,
            onPressed: picked > 0 ? () => onStep(-1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$picked',
              textAlign: TextAlign.center,
              style: context.textTheme.titleSmall,
            ),
          ),
          IconButton(
            tooltip: context.l10n.increase,
            onPressed: picked < max ? () => onStep(1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
