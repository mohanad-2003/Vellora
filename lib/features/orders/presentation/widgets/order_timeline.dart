import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/order_entity.dart';
import 'order_widgets.dart';

/// Vertical tracking timeline: Placed → Processing → Shipped → Delivered.
/// Completed steps are filled, the current step is ringed, upcoming steps are
/// muted. A cancelled order shows Placed → Cancelled only.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cancelled = order.status == OrderStatus.cancelled;

    final steps = cancelled
        ? [
            _Step(l10n.trackPlaced, order.createdAt, _State.done),
            _Step(
              l10n.orderStatusCancelled,
              order.createdAt.add(const Duration(hours: 3)),
              _State.failed,
            ),
          ]
        : _regularSteps(context);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }

  List<_Step> _regularSteps(BuildContext context) {
    final l10n = context.l10n;
    // Index of the step the order is currently at.
    final current = switch (order.status) {
      OrderStatus.processing => 1,
      OrderStatus.shipped => 2,
      _ => 3,
    };
    final labels = [
      l10n.trackPlaced,
      l10n.orderStatusProcessing,
      l10n.orderStatusShipped,
      l10n.orderStatusDelivered,
    ];
    // Display-only schedule derived from the order date (mock tracking).
    final offsets = [
      Duration.zero,
      const Duration(hours: 4),
      const Duration(days: 1, hours: 6),
      const Duration(days: 3),
    ];
    return [
      for (var i = 0; i < labels.length; i++)
        _Step(
          labels[i],
          i <= current ? order.createdAt.add(offsets[i]) : null,
          i < current || (i == current && order.status == OrderStatus.delivered)
              ? _State.done
              : i == current
              ? _State.current
              : _State.upcoming,
        ),
    ];
  }
}

enum _State { done, current, upcoming, failed }

class _Step {
  const _Step(this.label, this.time, this.state);

  final String label;
  final DateTime? time;
  final _State state;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final _Step step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final vellora = context.vellora;

    final Color dot = switch (step.state) {
      _State.done => vellora.success,
      _State.current => colors.primary,
      _State.failed => colors.error,
      _State.upcoming => colors.outlineVariant,
    };
    final filled = step.state == _State.done || step.state == _State.failed;
    final lineColor = step.state == _State.done
        ? vellora.success
        : colors.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? dot : colors.surface,
                    border: Border.all(color: dot, width: 2),
                  ),
                  child: filled
                      ? Icon(
                          step.state == _State.failed
                              ? Icons.close_rounded
                              : Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : step.state == _State.current
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dot,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: lineColor)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: text.titleSmall?.copyWith(
                      color: step.state == _State.upcoming
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                    ),
                  ),
                  if (step.time != null)
                    Text(
                      formatOrderDateTime(context, step.time!),
                      style: text.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
