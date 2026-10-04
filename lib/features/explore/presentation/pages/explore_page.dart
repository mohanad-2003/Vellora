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
import 'package:vellora/core/widgets/shimmer_widgets.dart';
import 'package:vellora/features/catalog/presentation/pages/catalog_page.dart';
import 'package:vellora/features/home/domain/entities/category_entity.dart';
import 'package:vellora/features/home/domain/usecases/get_home_data_usecase.dart';
import 'package:vellora/features/home/presentation/widgets/search_bar_entry.dart';
import '../../../../core/utils/safe_emit.dart';
import '../../../../core/widgets/failure_state_view.dart';
import '../../../../core/widgets/slow_load_hint.dart';

enum ExploreStatus { loading, loaded, error }

class ExploreState extends Equatable {
  const ExploreState({
    this.status = ExploreStatus.loading,
    this.categories = const [],
    this.failureKey,
  });

  final ExploreStatus status;
  final List<CategoryEntity> categories;
  final String? failureKey;

  @override
  List<Object?> get props => [status, categories, failureKey];
}

/// Loads the category list for the Explore tab.
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
        ExploreState(status: ExploreStatus.loaded, categories: data.categories),
      ),
    );
  }
}

/// The Explore tab: browse every category as a large photo tile.
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
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.explore,
                              style: context.textTheme.displaySmall,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(l10n.exploreSubtitle),
                          const SizedBox(height: AppSpacing.xl),
                          const SearchBarEntry(),
                        ],
                      ),
                    ),
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
                    ExploreStatus.loaded => SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        0,
                        gutter,
                        AppSpacing.xxl,
                      ),
                      sliver: SliverLayoutBuilder(
                        builder: (context, c) {
                          final columns = c.crossAxisExtent >= 840
                              ? 4
                              : c.crossAxisExtent >= 560
                              ? 3
                              : 2;
                          return SliverGrid.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: AppSpacing.md,
                                  crossAxisSpacing: AppSpacing.md,
                                  childAspectRatio: 1.15,
                                ),
                            itemCount: state.categories.length,
                            itemBuilder: (context, i) {
                              final c = state.categories[i];
                              final label = categoryLabel(
                                context,
                                c.id,
                                fallback: c.name,
                              );
                              return CategoryTile(
                                label: label,
                                caption: l10n.productsCount(c.productCount),
                                imagePath: c.imagePath,
                                onTap: () => context.pushNamed(
                                  RouteNames.nCatalog,
                                  extra: CatalogArgs(
                                    title: label,
                                    categoryId: c.id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
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
