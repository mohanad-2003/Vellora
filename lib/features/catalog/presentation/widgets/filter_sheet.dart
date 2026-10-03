import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../domain/catalog_filter.dart';

/// Modal filter sheet. Edits a local draft and only returns it on "Apply", so
/// dismissing the sheet never changes the list.
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.initial,
    required this.baseProducts,
  });

  final CatalogFilter initial;

  /// Unfiltered list — source of the available brands, categories, price range
  /// and the live "Show N results" count.
  final List<ProductEntity> baseProducts;

  /// Opens the sheet; resolves to the applied filter, or null if dismissed.
  static Future<CatalogFilter?> show(
    BuildContext context, {
    required CatalogFilter initial,
    required List<ProductEntity> baseProducts,
  }) {
    return AppBottomSheet.show<CatalogFilter>(
      context,
      title: context.l10n.filters,
      scrollable: false,
      child: FilterSheet(initial: initial, baseProducts: baseProducts),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late CatalogFilter _draft = widget.initial;

  late final double _lo;
  late final double _hi;
  late final List<String> _brands;
  late final List<String> _categories;

  static const _ratingSteps = [0.0, 3.0, 4.0, 4.5];

  @override
  void initState() {
    super.initState();
    final prices = widget.baseProducts.map((p) => p.price);
    _lo = prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b).floorToDouble();
    final hi = prices.isEmpty ? 100.0 : prices.reduce((a, b) => a > b ? a : b);
    _hi = hi.ceilToDouble() <= _lo ? _lo + 1 : hi.ceilToDouble();
    _brands = ({for (final p in widget.baseProducts) p.brand}.toList()..sort());
    _categories = [
      for (final id in _categoryOrder)
        if (widget.baseProducts.any((p) => p.category == id)) id,
    ];
  }

  static const _categoryOrder = [
    'men',
    'women',
    'shoes',
    'accessories',
    'beauty',
    'electronics',
    'grocery',
  ];

  RangeValues get _range => RangeValues(
        (_draft.minPrice ?? _lo).clamp(_lo, _hi),
        (_draft.maxPrice ?? _hi).clamp(_lo, _hi),
      );

  void _toggle(Set<String> set, String value, void Function(Set<String>) set0) {
    final next = {...set};
    next.contains(value) ? next.remove(value) : next.add(value);
    Haptics.selection();
    setState(() => set0(next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final count = _draft.apply(widget.baseProducts).length;

    Widget group(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.lg,
              AppSpacing.screenH,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_categories.length > 1)
                  group(
                    l10n.category,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final id in _categories)
                          FilterChip(
                            label: Text(categoryLabel(context, id)),
                            selected: _draft.categories.contains(id),
                            onSelected: (_) => _toggle(
                              _draft.categories,
                              id,
                              (s) => _draft = _draft.copyWith(categories: s),
                            ),
                          ),
                      ],
                    ),
                  ),
                group(
                  l10n.priceRange,
                  Column(
                    children: [
                      RangeSlider(
                        values: _range,
                        min: _lo,
                        max: _hi,
                        labels: RangeLabels(
                          _range.start.toPrice(),
                          _range.end.toPrice(),
                        ),
                        onChanged: (v) => setState(() {
                          _draft = (v.start <= _lo && v.end >= _hi)
                              ? _draft.copyWith(clearPrice: true)
                              : _draft.copyWith(
                                  minPrice: v.start,
                                  maxPrice: v.end,
                                );
                        }),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_range.start.toPrice(), style: text.labelLarge),
                          Text(_range.end.toPrice(), style: text.labelLarge),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_brands.length > 1)
                  group(
                    l10n.brand,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final b in _brands)
                          FilterChip(
                            label: Text(b),
                            selected: _draft.brands.contains(b),
                            onSelected: (_) => _toggle(
                              _draft.brands,
                              b,
                              (s) => _draft = _draft.copyWith(brands: s),
                            ),
                          ),
                      ],
                    ),
                  ),
                group(
                  l10n.rating,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final r in _ratingSteps)
                        ChoiceChip(
                          avatar: r == 0
                              ? null
                              : Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: context.vellora.star,
                                ),
                          label: Text(r == 0 ? l10n.anyRating : '$r+'),
                          selected: _draft.minRating == r,
                          onSelected: (_) {
                            Haptics.selection();
                            setState(
                              () => _draft = _draft.copyWith(minRating: r),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.onSaleOnly, style: text.titleMedium),
                  value: _draft.onSaleOnly,
                  onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(onSaleOnly: v),
                  ),
                ),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(
              top: BorderSide(color: context.colors.outlineVariant),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: l10n.clearAll,
                    variant: AppButtonVariant.outline,
                    onPressed: _draft.isActive
                        ? () => setState(() => _draft = CatalogFilter.empty)
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: l10n.applyFilters(count),
                    onPressed: count == 0
                        ? null
                        : () => Navigator.of(context).pop(_draft),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
