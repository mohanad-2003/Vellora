import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../domain/catalog_filter.dart';
import '../cubit/catalog_cubit.dart';
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
    this.emptyIcon = Icons.inventory_2_outlined,
  });

  final CatalogState state;
  final CatalogViewMode viewMode;
  final ValueChanged<CatalogViewMode> onViewModeChanged;
  final String heroPrefix;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;

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
        return const ProductGridShimmer();
      case CatalogStatus.error:
        return ErrorStateWidget(
          message: state.failureKey != null
              ? tr(context, state.failureKey!)
              : l10n.somethingWentWrong,
          onRetry: onRetry,
        );
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
      onRemoveCategory: (id) => cubit.applyFilter(state.filter.copyWith(
        categories: {...state.filter.categories}..remove(id),
      )),
      onRemoveBrand: (b) => cubit.applyFilter(state.filter.copyWith(
        brands: {...state.filter.brands}..remove(b),
      )),
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
        if (state.status == CatalogStatus.empty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: filtersActive ? Icons.filter_alt_off_rounded : emptyIcon,
              title: filtersActive ? l10n.noFilterResultsTitle : emptyTitle,
              message:
                  filtersActive ? l10n.noFilterResultsBody : emptyMessage,
              actionLabel: filtersActive ? l10n.clearAll : null,
              onAction: filtersActive ? cubit.clearFilter : null,
            ),
          )
        else ...[
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
            onAddToCart: (p) {
              cubit.addToCart(p);
              AppSnackbar.show(
                context,
                message: l10n.addedToCart,
                type: SnackType.success,
                actionLabel: l10n.viewCart,
                onAction: () => context.goNamed(RouteNames.nCart),
              );
            },
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
