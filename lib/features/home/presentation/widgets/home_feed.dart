import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/localization/l10n_lookup.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/widgets/favorites_listener.dart';
import 'package:vellora/core/widgets/product_card.dart';
import 'package:vellora/core/widgets/product_grid.dart';
import 'package:vellora/core/widgets/section_header.dart';
import 'package:vellora/core/widgets/shimmer_widgets.dart';
import 'package:vellora/features/catalog/presentation/cubit/catalog_cubit.dart';
import 'package:vellora/features/home/domain/entities/category_entity.dart';
import 'package:vellora/features/home/presentation/widgets/home_sections.dart';

/// "All products" at the bottom of Home: a pinned row of category chips over a
/// grid that shows [pageSize] products and grows by that much as the shopper
/// scrolls towards the end of [scroll]. Emits slivers.
class HomeFeedSection extends StatefulWidget {
  const HomeFeedSection({
    super.key,
    required this.scroll,
    required this.categories,
    required this.actions,
  });

  /// The Home scroll view; the feed grows when it nears its end.
  final ScrollController scroll;
  final List<CategoryEntity> categories;
  final ProductActions actions;

  static const pageSize = 20;

  @override
  State<HomeFeedSection> createState() => _HomeFeedSectionState();
}

class _HomeFeedSectionState extends State<HomeFeedSection> {
  late final CatalogCubit _cubit = sl<CatalogCubit>()..load();
  String? _category;
  int _visible = HomeFeedSection.pageSize;

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(HomeFeedSection old) {
    super.didUpdateWidget(old);
    if (old.scroll != widget.scroll) {
      old.scroll.removeListener(_onScroll);
      widget.scroll.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_onScroll);
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    final c = widget.scroll;
    if (!c.hasClients) return;
    final total = _cubit.state.products.length;
    if (_visible < total && c.position.extentAfter < 900) {
      setState(() => _visible += HomeFeedSection.pageSize);
    }
  }

  void _select(String? id) {
    if (id == _category) return;
    setState(() {
      _category = id;
      _visible = HomeFeedSection.pageSize;
    });
    _cubit.load(categoryId: id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FavoritesListener(
      onChanged: _cubit.syncFavorites,
      child: BlocProvider.value(
        value: _cubit,
        child: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SectionHeader(title: l10n.allProducts),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _ChipsHeader(
                background: Theme.of(context).scaffoldBackgroundColor,
                allLabel: l10n.chipAll,
                categories: widget.categories,
                selected: _category,
                onSelected: _select,
                labelOf: (c) => categoryLabel(context, c.id, fallback: c.name),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            BlocBuilder<CatalogCubit, CatalogState>(
              builder: (context, state) {
                if (state.status == CatalogStatus.initial ||
                    state.status == CatalogStatus.loading) {
                  return const SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH,
                    ),
                    sliver: SliverProductGridSkeleton(),
                  );
                }
                if (state.status == CatalogStatus.error) {
                  return SliverToBoxAdapter(
                    child: _FeedMessage(
                      text: l10n.somethingWentWrong,
                      action: TextButton(
                        onPressed: () => _cubit.load(categoryId: _category),
                        child: Text(l10n.retry),
                      ),
                    ),
                  );
                }
                final products = state.products;
                final shown = products.length < _visible
                    ? products.length
                    : _visible;
                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenH,
                      ),
                      sliver: SliverProductGrid(
                        itemCount: shown,
                        reveal: false,
                        itemBuilder: (context, i) {
                          final p = products[i];
                          final tag = 'home_feed_${p.id}';
                          return ProductCard(
                            heroTag: tag,
                            imagePath: p.imagePath,
                            title: p.name,
                            brand: p.brand,
                            price: p.price,
                            originalPrice: p.originalPrice,
                            rating: p.rating,
                            reviewCount: p.reviewCount,
                            isFavorite: p.isFavorite,
                            onTap: () => widget.actions.onTap(p, tag),
                            onFavoriteToggle: () => _cubit.toggleFavorite(p.id),
                            onAddToCart: widget.actions.onAddToCart == null
                                ? null
                                : () => widget.actions.onAddToCart!(p),
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: shown < products.length
                          ? const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.xl,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                ),
                              ),
                            )
                          : _FeedMessage(
                              text: products.isEmpty
                                  ? l10n.noProductsTitle
                                  : l10n.feedEnd,
                            ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// The pinned row of chips: "All" plus one per category.
class _ChipsHeader extends SliverPersistentHeaderDelegate {
  _ChipsHeader({
    required this.background,
    required this.allLabel,
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.labelOf,
  });

  final Color background;
  final String allLabel;
  final List<CategoryEntity> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String Function(CategoryEntity) labelOf;

  static const _height = 52.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final chips = <(String?, String)>[
      (null, allLabel),
      for (final c in categories) (c.id, labelOf(c)),
    ];
    return Container(
      color: background,
      alignment: Alignment.center,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final (id, label) = chips[i];
          return ChoiceChip(
            label: Text(label),
            selected: id == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(id),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_ChipsHeader old) =>
      old.selected != selected ||
      old.background != background ||
      old.categories != categories ||
      old.allLabel != allLabel;
}
