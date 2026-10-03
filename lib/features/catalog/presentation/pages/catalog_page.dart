import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/favorites_listener.dart';
import '../../domain/catalog_filter.dart';
import '../cubit/catalog_cubit.dart';
import '../widgets/catalog_results_view.dart';
import '../widgets/catalog_toolbar.dart';

/// Navigation payload for [CatalogPage], passed as go_router `extra`.
class CatalogArgs {
  const CatalogArgs({required this.title, this.categoryId, this.collection});

  final String title;
  final String? categoryId;

  /// A curated list (Flash Sale, Featured…) instead of a category.
  final CatalogCollection? collection;
}

/// Product listing for a category tap or a section "See all", with sort,
/// filters and a grid / list toggle.
class CatalogPage extends StatelessWidget {
  const CatalogPage({
    super.key,
    required this.title,
    this.categoryId,
    this.collection,
  });

  final String title;
  final String? categoryId;
  final CatalogCollection? collection;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CatalogCubit>()
        ..load(categoryId: categoryId, collection: collection),
      child: Builder(
        builder: (context) => FavoritesListener(
          onChanged: () => context.read<CatalogCubit>().syncFavorites(),
          child: _CatalogView(
            title: title,
            categoryId: categoryId,
            collection: collection,
          ),
        ),
      ),
    );
  }
}

class _CatalogView extends StatefulWidget {
  const _CatalogView({
    required this.title,
    required this.categoryId,
    required this.collection,
  });

  final String title;
  final String? categoryId;
  final CatalogCollection? collection;

  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<_CatalogView> {
  CatalogViewMode _viewMode = CatalogViewMode.grid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBarWidget(
        title: widget.title.isEmpty ? l10n.products : widget.title,
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: Breakpoints.contentMaxWidth,
          child: BlocBuilder<CatalogCubit, CatalogState>(
            builder: (context, state) => CatalogResultsView(
              state: state,
              viewMode: _viewMode,
              onViewModeChanged: (m) => setState(() => _viewMode = m),
              heroPrefix: 'catalog',
              onRetry: () => context.read<CatalogCubit>().load(
                    categoryId: widget.categoryId,
                    collection: widget.collection,
                  ),
              emptyTitle: l10n.noProductsTitle,
              emptyMessage: l10n.noProductsBody,
            ),
          ),
        ),
      ),
    );
  }
}
