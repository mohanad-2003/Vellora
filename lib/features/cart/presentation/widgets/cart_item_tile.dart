import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../../core/widgets/quantity_selector.dart';
import '../../domain/entities/cart_item_entity.dart';

/// One cart line: photo, name, variant, line total and quantity stepper.
/// Swipe to remove, or use the explicit remove button (swipe-only would be
/// unreachable for assistive technology).
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemoved,
    this.onTap,
  });

  final CartItemEntity item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemoved;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final l10n = context.l10n;

    final variantParts = [
      if (item.color != null && item.color!.isNotEmpty)
        colorLabel(context, item.color!),
      if (item.size != null && item.size!.isNotEmpty) item.size!,
    ];

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemoved(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: AppRadius.rLg,
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.rLg,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: AppRadius.rMd,
                child: SizedBox.square(
                  dimension: 92,
                  child: ProductImage(
                    path: item.imagePath,
                    semanticLabel: item.name,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall,
                          ),
                        ),
                      ),
                      AppIconButton(
                        icon: Icons.delete_outline_rounded,
                        iconSize: 20,
                        size: 36,
                        filled: false,
                        color: colors.onSurfaceVariant,
                        semanticLabel: '${l10n.removeItem}: ${item.name}',
                        onPressed: onRemoved,
                      ),
                    ],
                  ),
                  if (variantParts.isNotEmpty)
                    Text(
                      variantParts.join(' · '),
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: AppSpacing.sm,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.lineTotal.toPrice(),
                            style: text.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.quantity > 1)
                            Text(
                              '${item.price.toPrice()} ${l10n.each}',
                              style: text.labelSmall,
                            ),
                        ],
                      ),
                      QuantitySelector(
                        compact: true,
                        max: AppConstants.maxLineQuantity,
                        quantity: item.quantity,
                        onChanged: onQuantityChanged,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
