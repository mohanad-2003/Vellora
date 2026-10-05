import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/features/catalog/presentation/pages/search_page.dart';

/// Home search entry: a pill that opens the full Search screen, plus a filter
/// button that opens Search with the filter sheet already showing.
class SearchBarEntry extends StatelessWidget {
  const SearchBarEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: l10n.searchHint,
            excludeSemantics: true,
            onTap: () => context.pushNamed(RouteNames.nSearch),
            child: Material(
              color: colors.surfaceContainerHighest,
              borderRadius: AppRadius.rMd,
              child: InkWell(
                borderRadius: AppRadius.rMd,
                onTap: () => context.pushNamed(RouteNames.nSearch),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: colors.onSurfaceVariant,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.searchHint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: l10n.filters,
          excludeSemantics: true,
          onTap: () => _openFilters(context),
          child: Material(
            color: colors.primary,
            borderRadius: AppRadius.rMd,
            child: InkWell(
              borderRadius: AppRadius.rMd,
              onTap: () => _openFilters(context),
              child: SizedBox.square(
                dimension: 52,
                child: Icon(Icons.tune_rounded, color: colors.onPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openFilters(BuildContext context) => context.pushNamed(
    RouteNames.nSearch,
    extra: const SearchArgs(openFilters: true),
  );
}
