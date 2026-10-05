import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/favorites_listener.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/widgets/staggered_reveal.dart';
import '../../../catalog/domain/catalog_filter.dart';
import '../../../catalog/presentation/pages/catalog_page.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/home_data_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/home_bloc.dart';
import '../widgets/category_list.dart';
import '../widgets/home_extras.dart';
import '../widgets/home_header.dart';
import '../widgets/home_sections.dart';
import '../widgets/promo_banner_carousel.dart';
import '../widgets/search_bar_entry.dart';
import '../../../../core/widgets/failure_state_view.dart';
import '../../../../core/widgets/slow_load_hint.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
      child: Builder(
        builder: (context) => FavoritesListener(
          onChanged: () =>
              context.read<HomeBloc>().add(const HomeFavoritesSynced()),
          child: const _HomeView(),
        ),
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<HomeBloc>();
    final before = bloc.state.refreshCount;
    bloc.add(const HomeRefreshed());
    await bloc.stream
        .firstWhere((s) => s.refreshCount > before)
        .timeout(const Duration(seconds: 10), onTimeout: () => bloc.state);
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          maxWidth: Breakpoints.contentMaxWidth,
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          AppSpacing.md,
                          gutter,
                          0,
                        ),
                        child: const Column(
                          children: [
                            HomeHeader(),
                            SizedBox(height: AppSpacing.lg),
                            SearchBarEntry(),
                            SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                    if (state.status == HomeStatus.error)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: FailureStateView(
                          failureKey: state.failureKey,
                          onRetry: () =>
                              context.read<HomeBloc>().add(const HomeStarted()),
                        ),
                      )
                    else if (state.status == HomeStatus.loaded &&
                        state.data != null)
                      ..._content(context, state.data!)
                    else
                      const SliverToBoxAdapter(
                        child: Column(
                          children: [
                            Center(child: SlowLoadHint()),
                            _HomeLoading(),
                          ],
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxl),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, HomeDataEntity data) {
    final l10n = context.l10n;
    final bloc = context.read<HomeBloc>();

    final actions = ProductActions(
      onTap: (p, tag) => context.pushNamed(
        RouteNames.nProduct,
        pathParameters: {'id': p.id},
        extra: tag,
      ),
      onFavorite: (p) => bloc.add(HomeFavoriteToggled(p.id)),
      onAddToCart: (ProductEntity p) {
        bloc.add(HomeAddToCartRequested(p));
        AppSnackbar.show(
          context,
          message: l10n.addedToCart,
          type: SnackType.success,
          actionLabel: l10n.viewCart,
          onAction: () => context.goNamed(RouteNames.nCart),
        );
      },
    );

    void openCollection(String title, CatalogCollection collection) =>
        context.pushNamed(
          RouteNames.nCatalog,
          extra: CatalogArgs(title: title, collection: collection),
        );

    void openBanner(BannerEntity b) {
      switch (b.id) {
        case 'flash':
          openCollection(l10n.flashSale, CatalogCollection.flashSale);
        case 'new':
          openCollection(l10n.newArrivals, CatalogCollection.newArrivals);
        default:
          openCollection(l10n.bannerSummerTitle, CatalogCollection.featured);
      }
    }

    // Each block fades in slightly after the previous one.
    var step = 0;
    Widget reveal(Widget child) => StaggeredReveal(
      delay: Duration(milliseconds: 70 * step++),
      child: child,
    );
    Widget gap([double h = AppSpacing.xxl]) =>
        SliverToBoxAdapter(child: SizedBox(height: h));

    return [
      SliverToBoxAdapter(
        child: reveal(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: PromoBannerCarousel(
              banners: data.banners,
              onBannerTap: openBanner,
            ),
          ),
        ),
      ),
      gap(AppSpacing.xl),
      SliverToBoxAdapter(child: reveal(const ValuePropsStrip())),
      gap(),
      SliverToBoxAdapter(
        child: reveal(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.categories,
                actionLabel: l10n.seeAll,
                onAction: () => context.goNamed(RouteNames.nExplore),
              ),
              const SizedBox(height: AppSpacing.md),
              CategoryList(
                categories: data.categories,
                onTap: (c) => context.pushNamed(
                  RouteNames.nCatalog,
                  extra: CatalogArgs(
                    title: categoryLabel(context, c.id, fallback: c.name),
                    categoryId: c.id,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      gap(),
      SliverToBoxAdapter(
        child: reveal(
          FlashSaleSection(
            products: data.flashSale,
            actions: actions,
            onSeeAll: () =>
                openCollection(l10n.flashSale, CatalogCollection.flashSale),
          ),
        ),
      ),
      if (data.offers.isNotEmpty) ...[
        gap(),
        SliverToBoxAdapter(child: CouponsSection(offers: data.offers)),
      ],
      gap(),
      SliverToBoxAdapter(
        child: FeaturedSection(
          products: data.featured,
          actions: actions,
          onSeeAll: () =>
              openCollection(l10n.featured, CatalogCollection.featured),
        ),
      ),
      if (data.brands.isNotEmpty) ...[
        gap(),
        SliverToBoxAdapter(
          child: BrandsSection(
            brands: data.brands,
            onTap: (b) => context.pushNamed(
              RouteNames.nCatalog,
              extra: CatalogArgs(title: b.name, brand: b.name),
            ),
          ),
        ),
      ],
      gap(),
      SliverProductSection(
        title: l10n.newArrivals,
        subtitle: l10n.newArrivalsSubtitle,
        products: data.newArrivals.take(4).toList(),
        actions: actions,
        heroPrefix: 'home_new',
        onSeeAll: () =>
            openCollection(l10n.newArrivals, CatalogCollection.newArrivals),
      ),
      gap(),
      SliverToBoxAdapter(
        child: BestSellersSection(
          products: data.bestSellers.take(6).toList(),
          actions: actions,
          onSeeAll: () =>
              openCollection(l10n.bestSellers, CatalogCollection.bestSellers),
        ),
      ),
      if (data.budgetPicks.isNotEmpty) ...[
        gap(),
        SliverToBoxAdapter(
          child: ProductRailSection(
            title: l10n.budgetPicks(data.budgetLimit.toPrice()),
            subtitle: l10n.budgetPicksSubtitle,
            products: data.budgetPicks,
            actions: actions,
            heroPrefix: 'home_budget',
            onSeeAll: () => openCollection(
              l10n.budgetPicks(data.budgetLimit.toPrice()),
              CatalogCollection.budgetPicks,
            ),
          ),
        ),
      ],
      if (data.topRated.isNotEmpty) ...[
        gap(),
        SliverToBoxAdapter(
          child: ProductRailSection(
            title: l10n.topRated,
            subtitle: l10n.topRatedSubtitle,
            products: data.topRated,
            actions: actions,
            heroPrefix: 'home_top',
            onSeeAll: () =>
                openCollection(l10n.topRated, CatalogCollection.topRated),
          ),
        ),
      ],
      gap(),
      SliverProductSection(
        title: l10n.recommendedForYou,
        subtitle: l10n.recommendedSubtitle,
        products: data.recommended.take(6).toList(),
        actions: actions,
        heroPrefix: 'home_rec',
      ),
      if (!data.stats.isEmpty) ...[
        gap(),
        SliverToBoxAdapter(
          child: CatalogueStatsCard(
            productCount: data.stats.productCount,
            brandCount: data.stats.brandCount,
            categoryCount: data.stats.categoryCount,
            onExplore: () => context.goNamed(RouteNames.nExplore),
          ),
        ),
      ],
    ];
  }
}

/// Skeleton that mirrors the loaded layout (banner, categories, rail).
class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmer(child: ShimmerBox(width: double.infinity, height: 180)),
          SizedBox(height: AppSpacing.xxl),
          AppShimmer(
            child: Row(
              children: [
                _CategorySkeleton(),
                SizedBox(width: 12),
                _CategorySkeleton(),
                SizedBox(width: 12),
                _CategorySkeleton(),
                SizedBox(width: 12),
                _CategorySkeleton(),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xxl),
          HorizontalListShimmer(),
        ],
      ),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: Column(
        children: [
          AspectRatio(aspectRatio: 1, child: ShimmerBox()),
          SizedBox(height: 8),
          ShimmerBox(width: 44, height: 10),
        ],
      ),
    );
  }
}
