import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/cart_summary_entity.dart';

/// Subtotal / discount / shipping / total breakdown with a prominent total.
/// Shared by the cart and checkout.
class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({super.key, required this.summary});

  final CartSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final colors = context.colors;

    return Column(
      children: [
        _row(context, l10n.subtotal, summary.subtotal.toPrice()),
        if (summary.discount > 0)
          _row(
            context,
            l10n.discount,
            '-${summary.discount.toPrice()}',
            valueColor: context.vellora.success,
          ),
        _row(
          context,
          l10n.shipping,
          summary.shipping == 0 ? l10n.free : summary.shipping.toPrice(),
          valueColor: summary.shipping == 0 ? context.vellora.success : null,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Divider(),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(l10n.total, style: text.titleLarge)),
            Text(
              summary.total.toPrice(),
              style: text.headlineMedium?.copyWith(color: colors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text(
            value,
            style: text.titleSmall?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
