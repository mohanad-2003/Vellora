import 'package:flutter/material.dart';

import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/category_card.dart';
import '../../../../core/widgets/staggered_reveal.dart';
import '../../domain/entities/category_entity.dart';

/// Horizontally scrolling categories. Height follows the text scale so labels
/// never clip.
class CategoryList extends StatelessWidget {
  const CategoryList({super.key, required this.categories, this.onTap});

  final List<CategoryEntity> categories;
  final void Function(CategoryEntity)? onTap;

  static const double _tile = 72;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final height = _tile + 8 + scaler.scale(13 * 1.3) + 6;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final c = categories[i];
          return StaggeredReveal(
            delay: Duration(milliseconds: i * 50),
            offset: const Offset(0.15, 0),
            child: CategoryCard(
              size: _tile,
              label: categoryLabel(context, c.id, fallback: c.name),
              imagePath: c.imagePath,
              onTap: () => onTap?.call(c),
            ),
          );
        },
      ),
    );
  }
}
