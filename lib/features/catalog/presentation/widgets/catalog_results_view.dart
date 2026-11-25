import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/utils/quick_add_to_cart.dart';
import 'package:vellora/core/widgets/failure_state_view.dart';
import 'package:vellora/core/widgets/shimmer_widgets.dart';
import 'package:vellora/core/widgets/slow_load_hint.dart';
import 'package:vellora/features/catalog/domain/catalog_filter.dart';
import 'package:vellora/features/catalog/presentation/cubit/catalog_cubit.dart';

import '../../../../core/widgets/empty_state_widget.dart';
import 'catalog_toolbar.dart';
import 'filter_sheet.dart';
import 'product_results.dart';

/// Loading / error / empty / results presentation shared by the Catalog and
/// Search screens. Owns the sort + filter + view-mode plumbing so both screens
/// stay thin.
class CatalogResultsView extends StatelessWidget {
  const CatalogResultsView({
    super.key,
    required this.state,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.heroPrefix,
    required this.onRetry,
    required this.emptyTitle,
    required this.emptyMessage,
    this.emptyArt = EmptyArt.products,
    this.emptySuggestions,
  });

  final CatalogState state;
  final CatalogViewMode viewMode;
  final ValueChanged<CatalogViewMode> onViewModeChanged;
  final String heroPrefix;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptyMessage;
  final String emptyArt;
  final Widget? emptySuggestions;

  Future<void> _openFilters(BuildContext context) async {
    final cubit = context.read<CatalogCubit>();
    final result = await FilterSheet.show(
      context,
      initial: state.filter,
      baseProducts: state.baseProducts,
    );
    if (result != null) cubit.applyFilter(result);
  }

  Future<void> _openSort(BuildContext context) async {
    final cubit = context.read<CatalogCubit>();
    final result = await showSortSheet(context, current: state.sort);
    if (result != null) cubit.setSort(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CatalogCubit>();

    switch (state.status) {
      case CatalogStatus.initial:
      case CatalogStatus.loading:
        return const Stack(
          fit: StackFit.expand,
          children: [
            ProductGridShimmer(),
            Align(alignment: Alignment.bottomCenter, child: SlowLoadHint()),
          ],
        );
      case CatalogStatus.error:
        return FailureStateView(failureKey: state.failureKey, onRetry: onRetry);
      case CatalogStatus.empty:
      case CatalogStatus.loaded:
        break;
    }

    final filtersActive = state.filter.isActive;
    final toolbar = CatalogToolbar(
      resultCount: state.products.length,
      sort: state.sort,
      filter: state.filter,
      viewMode: viewMode,
      onSort: () => _openSort(context),
      onFilter: () => _openFilters(context),
      onViewModeChanged: onViewModeChanged,
      onRemoveCategory: (id) => cubit.applyFilter(
        state.filter.copyWith(
          categories: {...state.filter.categories}..remove(id),
        ),
      ),
      onRemoveBrand: (b) => cubit.applyFilter(
        state.filter.copyWith(brands: {...state.filter.brands}..remove(b)),
      ),
      onClearPrice: () =>
          cubit.applyFilter(state.filter.copyWith(clearPrice: true)),
      onClearRating: () =>
          cubit.applyFilter(state.filter.copyWith(minRating: 0)),
      onClearSale: () =>
          cubit.applyFilter(state.filter.copyWith(onSaleOnly: false)),
      onClearAll: cubit.clearFilter,
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: toolbar),
        if (state.status == CatalogStatus.empty) ...[
          if (!filtersActive && emptySuggestions != null)
            SliverToBoxAdapter(child: emptySuggestions),
          SliverFillRemaining(
            // The placeholder scrolls by itself and takes the whole remaining height.
            hasScrollBody: true,
            child: EmptyStateWidget(
              illustration: filtersActive ? EmptyArt.filters : emptyArt,
              title: filtersActive ? l10n.noFilterResultsTitle : emptyTitle,
              message: filtersActive ? l10n.noFilterResultsBody : emptyMessage,
              actionLabel: filtersActive ? l10n.clearAll : null,
              onAction: filtersActive ? cubit.clearFilter : null,
            ),
          ),
        ] else ...[
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
          SliverProductResults(
            products: state.products,
            viewMode: viewMode,
            heroPrefix: heroPrefix,
            onTap: (p, tag) => context.pushNamed(
              RouteNames.nProduct,
              pathParameters: {'id': p.id},
              extra: tag,
            ),
            onFavorite: (p) => cubit.toggleFavorite(p.id),
            onAddToCart: (p) => quickAddToCart(context, p),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
        ],
      ],
    );
  }
}

/// Convenience: whether the cubit currently has a user-visible filter.
extension CatalogStateX on CatalogState {
  bool get hasActiveFilter => filter != CatalogFilter.empty;
}
