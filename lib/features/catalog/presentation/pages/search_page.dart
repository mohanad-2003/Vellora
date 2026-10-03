import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/favorites_listener.dart';
import '../../data/recent_searches_store.dart';
import '../cubit/catalog_cubit.dart';
import '../widgets/catalog_results_view.dart';
import '../widgets/catalog_toolbar.dart';
import '../widgets/filter_sheet.dart';
import 'catalog_page.dart';

/// Optional payload for the Search route.
class SearchArgs {
  const SearchArgs({this.openFilters = false, this.initialQuery});

  /// Load every product and open the filter sheet immediately (Home's filter
  /// button).
  final bool openFilters;
  final String? initialQuery;
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.args});

  final SearchArgs? args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CatalogCubit>(),
      child: Builder(
        builder: (context) => FavoritesListener(
          onChanged: () => context.read<CatalogCubit>().syncFavorites(),
          child: _SearchView(args: args),
        ),
      ),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView({this.args});

  final SearchArgs? args;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _store = sl<RecentSearchesStore>();
  Timer? _debounce;
  late List<String> _recent = _store.read();
  CatalogViewMode _viewMode = CatalogViewMode.grid;

  /// Search keywords that match the mock catalogue (data, not UI copy).
  static const _popularTerms = [
    'Nike',
    'Sneakers',
    'Dress',
    'Watch',
    'Hoodie',
    'Camera',
  ];

  static const _browseCategories = [
    'men',
    'women',
    'shoes',
    'accessories',
    'beauty',
    'electronics',
    'grocery',
  ];

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    if (args?.initialQuery != null) _controller.text = args!.initialQuery!;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cubit = context.read<CatalogCubit>();
      if (args?.openFilters ?? false) {
        await cubit.load();
        if (!mounted) return;
        final result = await FilterSheet.show(
          context,
          initial: cubit.state.filter,
          baseProducts: cubit.state.baseProducts,
        );
        if (result != null) cubit.applyFilter(result);
      } else if (args?.initialQuery?.isNotEmpty ?? false) {
        cubit.search(args!.initialQuery!);
      } else {
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // refresh the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final q = value.trim();
      final cubit = context.read<CatalogCubit>();
      q.isEmpty ? cubit.reset() : cubit.search(q);
    });
  }

  Future<void> _submit(String term) async {
    final q = term.trim();
    if (q.isEmpty) return;
    _debounce?.cancel();
    _controller
      ..text = q
      ..selection = TextSelection.collapsed(offset: q.length);
    _focus.unfocus();
    final cubit = context.read<CatalogCubit>();
    final next = await _store.add(q);
    if (!mounted) return;
    setState(() => _recent = next);
    cubit.search(q);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    context.read<CatalogCubit>().reset();
    setState(() {});
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gutter = context.pageGutter;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: Breakpoints.contentMaxWidth,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(gutter - 8, 8, gutter, 8),
                child: Row(
                  children: [
                    AppIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconSize: 18,
                      filled: false,
                      semanticLabel:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: _SearchField(
                        controller: _controller,
                        focusNode: _focus,
                        hint: l10n.searchHint,
                        clearLabel: l10n.clearSearch,
                        onChanged: _onChanged,
                        onSubmitted: _submit,
                        onClear: _clear,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<CatalogCubit, CatalogState>(
                  builder: (context, state) {
                    if (state.status == CatalogStatus.initial) {
                      return _Suggestions(
                        recent: _recent,
                        popular: _popularTerms,
                        categories: _browseCategories,
                        onTerm: _submit,
                        onRemoveRecent: (t) async {
                          final next = await _store.remove(t);
                          if (mounted) setState(() => _recent = next);
                        },
                        onClearRecent: () async {
                          await _store.clear();
                          if (mounted) setState(() => _recent = const []);
                        },
                        onCategory: (id) => context.pushNamed(
                          RouteNames.nCatalog,
                          extra: CatalogArgs(
                            title: categoryLabel(context, id),
                            categoryId: id,
                          ),
                        ),
                      );
                    }
                    return CatalogResultsView(
                      state: state,
                      viewMode: _viewMode,
                      onViewModeChanged: (m) => setState(() => _viewMode = m),
                      heroPrefix: 'search',
                      onRetry: () => context
                          .read<CatalogCubit>()
                          .search(_controller.text.trim()),
                      emptyTitle: l10n.noResultsTitle,
                      emptyMessage: l10n.noResultsBody(state.query),
                      emptyIcon: Icons.search_off_rounded,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.clearLabel,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String clearLabel;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: context.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 22),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: clearLabel,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClear,
                ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.recent,
    required this.popular,
    required this.categories,
    required this.onTerm,
    required this.onRemoveRecent,
    required this.onClearRecent,
    required this.onCategory,
  });

  final List<String> recent;
  final List<String> popular;
  final List<String> categories;
  final ValueChanged<String> onTerm;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback onClearRecent;
  final ValueChanged<String> onCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final gutter = context.pageGutter;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(gutter, AppSpacing.sm, gutter, AppSpacing.xxl),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(l10n.recentSearches, style: text.titleMedium),
              ),
              TextButton(onPressed: onClearRecent, child: Text(l10n.clearAll)),
            ],
          ),
          for (final term in recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                Icons.history_rounded,
                color: context.colors.onSurfaceVariant,
              ),
              title: Text(term, style: text.bodyLarge),
              trailing: IconButton(
                tooltip: l10n.removeItem,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => onRemoveRecent(term),
              ),
              onTap: () => onTerm(term),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
        Text(l10n.popularSearches, style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final term in popular)
              ActionChip(
                label: Text(term),
                avatar: const Icon(Icons.trending_up_rounded, size: 16),
                onPressed: () => onTerm(term),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.browseCategories, style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final id in categories)
              ActionChip(
                label: Text(categoryLabel(context, id)),
                avatar: Icon(categoryIcon(id), size: 16),
                onPressed: () => onCategory(id),
              ),
          ],
        ),
      ],
    );
  }
}
