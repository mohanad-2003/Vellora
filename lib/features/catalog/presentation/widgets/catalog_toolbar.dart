import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../domain/catalog_filter.dart';

/// How a result list is laid out.
enum CatalogViewMode { grid, list }

String sortLabel(BuildContext context, CatalogSort sort) {
  final l10n = context.l10n;
  return switch (sort) {
    CatalogSort.relevance => l10n.sortRelevance,
    CatalogSort.priceLowHigh => l10n.sortPriceLowHigh,
    CatalogSort.priceHighLow => l10n.sortPriceHighLow,
    CatalogSort.topRated => l10n.sortTopRated,
  };
}

/// Opens the sort picker and resolves to the choice (or null if dismissed).
Future<CatalogSort?> showSortSheet(
  BuildContext context, {
  required CatalogSort current,
}) {
  return AppBottomSheet.show<CatalogSort>(
    context,
    title: context.l10n.sortBy,
    child: RadioGroup<CatalogSort>(
      groupValue: current,
      onChanged: (v) => Navigator.of(context).pop(v),
      child: Column(
        children: [
          for (final s in CatalogSort.values)
            RadioListTile<CatalogSort>(
              contentPadding: EdgeInsets.zero,
              value: s,
              title: Text(sortLabel(context, s)),
            ),
        ],
      ),
    ),
  );
}

/// Result count, sort, filter and view-mode controls above a product list.
class CatalogToolbar extends StatelessWidget {
  const CatalogToolbar({
    super.key,
    required this.resultCount,
    required this.sort,
    required this.filter,
    required this.viewMode,
    required this.onSort,
    required this.onFilter,
    required this.onViewModeChanged,
    required this.onRemoveCategory,
    required this.onRemoveBrand,
    required this.onClearPrice,
    required this.onClearRating,
    required this.onClearSale,
    required this.onClearAll,
  });

  final int resultCount;
  final CatalogSort sort;
  final CatalogFilter filter;
  final CatalogViewMode viewMode;
  final VoidCallback onSort;
  final VoidCallback onFilter;
  final ValueChanged<CatalogViewMode> onViewModeChanged;
  final ValueChanged<String> onRemoveCategory;
  final ValueChanged<String> onRemoveBrand;
  final VoidCallback onClearPrice;
  final VoidCallback onClearRating;
  final VoidCallback onClearSale;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final colors = context.colors;

    Widget action({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      int badge = 0,
    }) {
      return Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rPill,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: colors.onSurface),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge,
                    ),
                  ),
                  if (badge > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: text.labelSmall?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final chips = <Widget>[
      for (final id in filter.categories)
        _FilterChip(
          label: categoryLabel(context, id),
          onRemove: () => onRemoveCategory(id),
        ),
      for (final b in filter.brands)
        _FilterChip(label: b, onRemove: () => onRemoveBrand(b)),
      if (filter.hasPrice)
        _FilterChip(
          label:
              '\$${(filter.minPrice ?? 0).round()} – \$${(filter.maxPrice ?? 0).round()}',
          onRemove: onClearPrice,
        ),
      if (filter.minRating > 0)
        _FilterChip(
          label: '${filter.minRating}+ ★',
          onRemove: onClearRating,
        ),
      if (filter.onSaleOnly)
        _FilterChip(label: l10n.onSaleOnly, onRemove: onClearSale),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.resultsCount(resultCount),
                  style: text.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                flex: 2,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    action(
                      icon: Icons.swap_vert_rounded,
                      label: l10n.sortBy,
                      onTap: onSort,
                    ),
                    action(
                      icon: Icons.tune_rounded,
                      label: l10n.filters,
                      onTap: onFilter,
                      badge: filter.activeCount,
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: viewMode == CatalogViewMode.grid
                    ? l10n.listView
                    : l10n.gridView,
                excludeSemantics: true,
                child: IconButton(
                  onPressed: () => onViewModeChanged(
                    viewMode == CatalogViewMode.grid
                        ? CatalogViewMode.list
                        : CatalogViewMode.grid,
                  ),
                  icon: Icon(
                    viewMode == CatalogViewMode.grid
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (chips.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              itemCount: chips.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => i < chips.length
                  ? Center(child: chips[i])
                  : Center(
                      child: TextButton(
                        onPressed: onClearAll,
                        child: Text(l10n.clearAll),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onRemove,
      deleteButtonTooltipMessage: context.l10n.removeItem,
      visualDensity: VisualDensity.compact,
      backgroundColor: context.colors.primaryContainer,
      labelStyle: context.textTheme.labelMedium?.copyWith(
        color: context.colors.onPrimaryContainer,
      ),
      side: BorderSide.none,
    );
  }
}
