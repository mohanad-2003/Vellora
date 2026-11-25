import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/product_image.dart';
import '../../data/free_to_game_api.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final _api = FreeToGameApi();
  late Future<List<FreeGame>> _games;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _games = _api.loadGames();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _openLink(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } on PlatformException {
      // The device could not hand the URL to a browser.
    }
    if (!mounted) return;
    AppSnackbar.show(
      context,
      message: context.l10n.gamesLinkError,
      type: SnackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gutter = context.pageGutter;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.games)),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: Breakpoints.medium,
          child: FutureBuilder<List<FreeGame>>(
            future: _games,
            builder: (context, snapshot) {
              final games = snapshot.data;
              final query = _query.trim().toLowerCase();
              final visibleGames = games
                  ?.where((game) => game.matches(query))
                  .toList(growable: false);

              return CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        AppSpacing.lg,
                        gutter,
                        AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.gamesSubtitle,
                            style: context.textTheme.titleMedium,
                          ),
                          TextButton.icon(
                            onPressed: () => _openLink(FreeToGameApi.source),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            label: Text(l10n.gamesSource),
                          ),
                          if (games != null && games.isNotEmpty)
                            TextField(
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              decoration: InputDecoration(
                                labelText: l10n.gamesSearchHint,
                                prefixIcon: const Icon(Icons.search_rounded),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (snapshot.connectionState != ConnectionState.done)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      child: ErrorStateWidget(
                        message: l10n.gamesLoadError,
                        onRetry: () =>
                            setState(() => _games = _api.loadGames()),
                      ),
                    )
                  else if (visibleGames == null || visibleGames.isEmpty)
                    SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.sports_esports_outlined,
                        title: l10n.noResultsTitle,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        0,
                        gutter,
                        AppSpacing.xl,
                      ),
                      sliver: SliverList.separated(
                        itemCount: visibleGames.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, index) {
                          final game = visibleGames[index];
                          final link = game.link;
                          return _GameTile(
                            game: game,
                            onTap: link == null ? null : () => _openLink(link),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, this.onTap});

  final FreeGame game;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      game.genre,
      game.platform,
    ].where((value) => value.isNotEmpty).join(' · ');
    return Material(
      color: context.colors.surfaceContainer,
      borderRadius: AppRadius.rLg,
      child: InkWell(
        borderRadius: AppRadius.rLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.rSm,
                child: SizedBox(
                  width: 96,
                  height: 54,
                  child: kIsWeb && game.thumbnail.isNotEmpty
                      ? Image.network(
                          game.thumbnail,
                          fit: BoxFit.cover,
                          // FreeToGame's image host does not send CORS headers.
                          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) =>
                              const ProductImage(path: ''),
                        )
                      : ProductImage(path: game.thumbnail),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.titleMedium,
                    ),
                    if (metadata.isNotEmpty)
                      Text(
                        metadata,
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    if (game.description.isNotEmpty)
                      Text(
                        game.description,
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: context.colors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
