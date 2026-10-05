import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/localization/l10n_lookup.dart';
import 'package:vellora/core/responsive/responsive.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/widgets/empty_state_widget.dart';
import 'package:vellora/core/widgets/error_state_widget.dart';
import 'package:vellora/core/widgets/favorites_listener.dart';
import 'package:vellora/core/widgets/shimmer_widgets.dart';
import 'package:vellora/core/widgets/tab_page_header.dart';
import 'package:vellora/features/catalog/presentation/widgets/catalog_toolbar.dart';
import 'package:vellora/features/catalog/presentation/widgets/product_results.dart';
import 'package:vellora/features/wishlist/presentation/bloc/wishlist_bloc.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WishlistBloc>()..add(const WishlistStarted()),
      child: Builder(
        builder: (context) => FavoritesListener(
          onChanged: () =>
              context.read<WishlistBloc>().add(const WishlistRefreshed()),
          child: const _WishlistView(),
        ),
      ),
    );
  }
}

class _WishlistView extends StatelessWidget {
  const _WishlistView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gutter = context.pageGutter;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          maxWidth: Breakpoints.contentMaxWidth,
          child: BlocBuilder<WishlistBloc, WishlistState>(
            builder: (context, state) {
              final header = TabPageHeader(
                title: l10n.wishlist,
                subtitle: l10n.wishlistSubtitle,
                count: state.status == WishlistStatus.loaded
                    ? l10n.productsCount(state.products.length)
                    : null,
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.lg,
                  gutter,
                  AppSpacing.lg,
                ),
              );

              final Widget body = switch (state.status) {
                WishlistStatus.loading => ProductGridShimmer(),
                WishlistStatus.error => ErrorStateWidget(
                  message: state.failureKey != null
                      ? tr(context, state.failureKey!)
                      : l10n.somethingWentWrong,
                  onRetry: () =>
                      context.read<WishlistBloc>().add(const WishlistStarted()),
                ),
                WishlistStatus.empty => EmptyStateWidget(
                  icon: Icons.favorite_border_rounded,
                  title: l10n.emptyWishlistTitle,
                  message: l10n.emptyWishlistBody,
                  actionLabel: l10n.exploreProducts,
                  onAction: () => context.goNamed(RouteNames.nExplore),
                ),
                WishlistStatus.loaded => CustomScrollView(
                  slivers: [
                    SliverProductResults(
                      products: state.products,
                      viewMode: CatalogViewMode.grid,
                      heroPrefix: 'wishlist',
                      onTap: (p, tag) => context.pushNamed(
                        RouteNames.nProduct,
                        pathParameters: {'id': p.id},
                        extra: tag,
                      ),
                      onFavorite: (p) => context.read<WishlistBloc>().add(
                        WishlistItemRemoved(p.id),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxl),
                    ),
                  ],
                ),
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  Expanded(child: body),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
