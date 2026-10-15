import 'dart:async';

import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'custom_snackbar.dart';

/// A notification shown over the top of the app while it is open, like the one
/// the system shows in the tray: it slides in below the status bar, opens what
/// it is about when tapped, goes away by itself after a few seconds, and can be
/// swiped up. It never covers the buttons at the bottom of a screen.
class InAppBanner {
  InAppBanner._();

  static OverlayEntry? _current;
  static Timer? _timer;

  /// Shows the banner on [overlay]; a banner already showing is replaced.
  static void show(
    OverlayState overlay, {
    required String title,
    required String body,
    required IconData icon,
    required VoidCallback onTap,
    Duration duration = const Duration(seconds: 5),
  }) {
    hide();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _BannerCard(
        title: title,
        body: body,
        icon: icon,
        onTap: () {
          if (_current == entry) hide();
          onTap();
        },
        onSwiped: () {
          if (_current == entry) hide();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
    _timer = Timer(duration, () {
      if (_current == entry) hide();
    });
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

class _BannerCard extends StatefulWidget {
  const _BannerCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.onTap,
    required this.onSwiped,
  });

  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onSwiped;

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  /// Aligned with the app's own direction, while each line keeps its own
  /// reading direction (English in the Arabic app keeps its full stop at the end).
  TextAlign _align(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
      ? TextAlign.right
      : TextAlign.left;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final top = MediaQuery.paddingOf(context).top;
    final align = _align(context);

    return Positioned(
      top: top + AppSpacing.sm,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1.4),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _in, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _in,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onSwiped(),
            child: Semantics(
              liveRegion: true,
              button: true,
              label: '${widget.title}. ${widget.body}',
              excludeSemantics: true,
              child: Material(
                color: colors.surface,
                elevation: 8,
                shadowColor: Colors.black45,
                borderRadius: AppRadius.rLg,
                child: InkWell(
                  borderRadius: AppRadius.rLg,
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.rLg,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            size: 20,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: align,
                                textDirection: AppSnackbar.directionOf(
                                  widget.title,
                                ),
                                style: text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.body.isNotEmpty)
                                Text(
                                  widget.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: align,
                                  textDirection: AppSnackbar.directionOf(
                                    widget.body,
                                  ),
                                  style: text.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                            ],
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
      ),
    );
  }
}
