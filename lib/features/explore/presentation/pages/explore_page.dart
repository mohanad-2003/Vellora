import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/localization/l10n_lookup.dart';
import 'package:vellora/core/responsive/responsive.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/usecases/usecase.dart';
import 'package:vellora/core/widgets/category_card.dart';
import 'package:vellora/core/extensions/num_extensions.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/core/widgets/section_header.dart';
import 'package:vellora/core/widgets/shimmer_widgets.dart';
import 'package:vellora/core/widgets/tab_page_header.dart';
import 'package:vellora/features/catalog/domain/catalog_filter.dart';
import 'package:vellora/features/catalog/presentation/pages/catalog_page.dart';
import 'package:vellora/features/home/domain/entities/brand_entity.dart';
import 'package:vellora/features/home/domain/entities/category_entity.dart';
import 'package:vellora/features/home/domain/entities/home_data_entity.dart';
import 'package:vellora/features/home/domain/usecases/get_home_data_usecase.dart';
import 'package:vellora/features/home/presentation/widgets/home_extras.dart';
import 'package:vellora/features/home/presentation/widgets/search_bar_entry.dart';
import '../../../../core/utils/safe_emit.dart';
import '../../../../core/widgets/failure_state_view.dart';
import '../../../../core/widgets/slow_load_hint.dart';

enum ExploreStatus { loading, loaded, error }

class ExploreState extends Equatable {
  const ExploreState({
    this.status = ExploreStatus.loading,
    this.categories = const [],
    this.brands = const [],
    this.failureKey,
  });

  final ExploreStatus status;
  final List<CategoryEntity> categories;
  final List<BrandEntity> brands;
  final String? failureKey;

  @override
  List<Object?> get props => [status, categories, brands, failureKey];
}

/// Loads the categories and brands for the Explore tab.
@injectable
class ExploreCubit extends Cubit<ExploreState> with SafeEmit<ExploreState> {
  ExploreCubit(this._getHomeData) : super(const ExploreState());

  final GetHomeDataUseCase _getHomeData;

  Future<void> load() async {
    emit(const ExploreState());
    final result = await _getHomeData(const NoParams());
    result.match(
      (failure) => emit(
        ExploreState(status: ExploreStatus.error, failureKey: failure.l10nKey),
      ),
      (data) => emit(
        ExploreState(
          status: ExploreStatus.loaded,
          categories: data.categories,
          brands: data.brands,
        ),
      ),
    );
  }
}

/// The Explore tab: quick collections, every category as a photo tile (the
/// first one large) and the top brands.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExploreCubit>()..load(),
      child: const _ExploreView(),
    );
  }
}

class _ExploreView extends StatelessWidget {
  const _ExploreView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gutter = context.pageGutter;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          maxWidth: Breakpoints.contentMaxWidth,
          child: BlocBuilder<ExploreCubit, ExploreState>(
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        AppSpacing.lg,
                        gutter,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TabPageHeader(
                            title: l10n.explore,
                            subtitle: l10n.exploreSubtitle,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const SearchBarEntry(),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _QuickCollections()),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
                  switch (state.status) {
                    ExploreStatus.loading => SliverMainAxisGroup(
                      slivers: [
                        const SliverToBoxAdapter(
                          child: Center(child: SlowLoadHint()),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: gutter),
                          sliver: SliverGrid.count(
                            crossAxisCount: context.isTablet ? 3 : 2,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                            childAspectRatio: 1.15,
                            children: List.generate(
                              6,
                              (_) => const AppShimmer(
                                child: ShimmerBox(width: double.infinity),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ExploreStatus.error => SliverFillRemaining(
                      hasScrollBody: false,
                      child: FailureStateView(
                        failureKey: state.failureKey,
                        onRetry: () => context.read<ExploreCubit>().load(),
                      ),
                    ),
                    ExploreStatus.loaded => _LoadedExplore(state: state),
                  },
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Shortcut chips into the curated collections.
class _QuickCollections extends StatelessWidget {
  const _QuickCollections();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final budget = l10n.budgetPicks(
      HomeDataEntity.defaultBudgetLimit.toPrice(),
    );
    final items = [
      (
        Icons.bolt_rounded,
        l10n.flashSale,
        CatalogCollection.flashSale,
        context.vellora.accent,
      ),
      (
        Icons.fiber_new_outlined,
        l10n.newArrivals,
        CatalogCollection.newArrivals,
        context.colors.primary,
      ),
      (
        Icons.local_fire_department_outlined,
        l10n.bestSellers,
        CatalogCollection.bestSellers,
        const Color(0xFFE08A1E),
      ),
      (
        Icons.star_outline_rounded,
        l10n.topRated,
        CatalogCollection.topRated,
        const Color(0xFFD99A00),
      ),
      (
        Icons.sell_outlined,
        budget,
        CatalogCollection.budgetPicks,
        const Color(0xFF0E9F8F),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.quickCollections,
          padding: EdgeInsets.symmetric(horizontal: context.pageGutter),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.pageGutter),
          child: Row(
            children: [
              for (final (icon, label, collection, color) in items)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: Material(
                    color: color.withValues(alpha: context.isDark ? 0.16 : 0.1),
                    borderRadius: AppRadius.rPill,
                    child: InkWell(
                      borderRadius: AppRadius.rPill,
                      onTap: () => context.pushNamed(
                        RouteNames.nCatalog,
                        extra: CatalogArgs(
                          title: label,
                          collection: collection,
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 18, color: color),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                label,
                                style: context.textTheme.labelLarge?.copyWith(
                                  color: context.colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadedExplore extends StatelessWidget {
  const _LoadedExplore({required this.state});

  final ExploreState state;

  void _open(BuildContext context, CategoryEntity c, String label) =>
      context.pushNamed(
        RouteNames.nCatalog,
        extra: CatalogArgs(title: label, categoryId: c.id),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gutter = context.pageGutter;
    final categories = state.categories;
    if (categories.isEmpty) return const SliverToBoxAdapter();

    final first = categories.first;
    final firstLabel = categoryLabel(context, first.id, fallback: first.name);
    final rest = categories.skip(1).toList();

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.md),
            child: SectionHeader(
              title: l10n.categories,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        // The first category leads as a wide banner tile.
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: context.isTablet ? 3.2 : 2.1,
              child: CategoryTile(
                label: firstLabel,
                caption: l10n.productsCount(first.productCount),
                imagePath: first.imagePath,
                onTap: () => _open(context, first, firstLabel),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverLayoutBuilder(
            builder: (context, c) {
              final columns = c.crossAxisExtent >= 840
                  ? 4
                  : c.crossAxisExtent >= 560
                  ? 3
                  : 2;
              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.15,
                ),
                itemCount: rest.length,
                itemBuilder: (context, i) {
                  final c = rest[i];
                  final label = categoryLabel(context, c.id, fallback: c.name);
                  return CategoryTile(
                    label: label,
                    caption: l10n.productsCount(c.productCount),
                    imagePath: c.imagePath,
                    onTap: () => _open(context, c, label),
                  );
                },
              );
            },
          ),
        ),
        if (state.brands.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          SliverToBoxAdapter(
            child: BrandsSection(
              brands: state.brands,
              onTap: (b) => context.pushNamed(
                RouteNames.nCatalog,
                extra: CatalogArgs(title: b.name, brand: b.name),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
}
