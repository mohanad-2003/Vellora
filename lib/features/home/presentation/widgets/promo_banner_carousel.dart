import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/responsive/responsive.dart';
import 'package:vellora/core/widgets/promo_banner.dart';
import 'package:vellora/features/home/domain/entities/banner_entity.dart';

/// Promotional banners that loop endlessly and advance on their own.
///
/// The neighbouring banners sit slightly smaller and fainter. A pill over the
/// bottom corner shows which banner is up and how long until the next one.
/// Auto-play pauses while the user drags, never runs when the system asks for
/// reduced motion, and stops with the screen (the controller is a ticker).
class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({
    super.key,
    required this.banners,
    required this.onBannerTap,
  });

  final List<BannerEntity> banners;
  final void Function(BannerEntity banner) onBannerTap;

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel>
    with SingleTickerProviderStateMixin {
  static const _interval = Duration(seconds: 5);
  static const _gap = 6.0;

  /// Banners repeat, so start far enough into the list to swipe either way.
  late final int _initialPage = widget.banners.length * 1000;

  late final AnimationController _progress =
      AnimationController(vsync: this, duration: _interval)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _next();
        });

  PageController? _controller;
  double _fraction = 0;
  late int _page = _initialPage;
  bool _reduceMotion = false;

  int get _count => widget.banners.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _progress.stop();
    } else if (!_progress.isAnimating) {
      _restart();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _restart() {
    if (_count < 2 || _reduceMotion) return;
    _progress.forward(from: 0);
  }

  void _next() {
    final controller = _controller;
    if (!mounted || controller == null || !controller.hasClients) return;
    controller.nextPage(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
    );
  }

  /// The page controller depends on the width (so the first banner lines up
  /// with the rest of the page), so it is rebuilt if the width changes.
  PageController _controllerFor(double fraction) {
    if (_controller == null || (_fraction - fraction).abs() > 0.001) {
      _controller?.dispose();
      _fraction = fraction;
      _controller = PageController(
        viewportFraction: fraction,
        initialPage: _page,
      );
    }
    return _controller!;
  }

  /// Three different hues so each banner stands apart from the others and from
  /// the app's own indigo buttons. All are dark enough for white copy in both
  /// themes. "New" uses the logo's navy and gold.
  PromoBannerStyle _styleFor(BannerEntity b) {
    switch (b.id) {
      case 'flash':
        return const PromoBannerStyle(
          background: [Color(0xFFE11D48), Color(0xFFFF7A45)],
          foreground: Colors.white,
          cta: Colors.white,
          ctaForeground: Color(0xFFB4163A),
        );
      case 'new':
        return const PromoBannerStyle(
          background: [Color(0xFF1B1560), Color(0xFF3D2C9B)],
          foreground: Colors.white,
          cta: Color(0xFFE9B861),
          ctaForeground: Color(0xFF2A1F00),
        );
      case 'summer':
      default:
        return const PromoBannerStyle(
          background: [Color(0xFF0A8F8A), Color(0xFF075E85)],
          foreground: Colors.white,
          cta: Colors.white,
          ctaForeground: Color(0xFF075E85),
        );
    }
  }

  ({String title, String subtitle, String? badge}) _copyFor(BannerEntity b) {
    final l10n = context.l10n;
    switch (b.id) {
      case 'flash':
        return (
          title: l10n.bannerFlashTitle,
          subtitle: l10n.bannerFlashSubtitle,
          badge: l10n.bannerBadgeLimited,
        );
      case 'new':
        return (
          title: l10n.bannerNewTitle,
          subtitle: l10n.bannerNewSubtitle,
          badge: l10n.bannerBadgeNew,
        );
      case 'summer':
        return (
          title: l10n.bannerSummerTitle,
          subtitle: l10n.bannerSummerSubtitle,
          badge: l10n.bannerBadgeSeason,
        );
      default:
        return (title: b.title, subtitle: b.subtitle, badge: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gutter = context.pageGutter;
    // Height tracks the width but is clamped, and grows with the text scale so
    // the copy never clips.
    final width = MediaQuery.sizeOf(context).width.clamp(0.0, 720.0);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final height = (width * 0.5).clamp(176.0, 240.0) * (0.85 + 0.15 * scale);

    return LayoutBuilder(
      builder: (context, constraints) {
        // First banner's edge sits on the page gutter; a sliver of the next
        // one shows beside it.
        final fraction = (1 - 2 * (gutter - _gap) / constraints.maxWidth).clamp(
          0.6,
          1.0,
        );
        final controller = _controllerFor(fraction);
        final current = _page % _count;

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollStartNotification && n.dragDetails != null) {
                    _progress.stop();
                  } else if (n is ScrollEndNotification) {
                    _restart();
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: controller,
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    _restart();
                  },
                  itemBuilder: (context, i) {
                    final b = widget.banners[i % _count];
                    final copy = _copyFor(b);
                    return AnimatedBuilder(
                      animation: controller,
                      builder: (context, child) {
                        var delta = 0.0;
                        if (controller.hasClients &&
                            controller.position.haveDimensions) {
                          delta = ((controller.page ?? _page.toDouble()) - i)
                              .abs()
                              .clamp(0.0, 1.0);
                        }
                        return Transform.scale(
                          scale: 1 - 0.06 * delta,
                          child: Opacity(
                            opacity: 1 - 0.35 * delta,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: _gap),
                        child: PromoBanner(
                          title: copy.title,
                          subtitle: copy.subtitle,
                          eyebrow: copy.badge,
                          ctaLabel: l10n.shopNow,
                          imagePath: b.imagePath,
                          style: _styleFor(b),
                          onTap: () => widget.onBannerTap(b),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_count > 1)
                PositionedDirectional(
                  bottom: 14,
                  end: gutter + 6,
                  child: Semantics(
                    label: l10n.pageOf(current + 1, _count),
                    excludeSemantics: true,
                    child: _ProgressPill(
                      count: _count,
                      current: current,
                      progress: _progress,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Dots over the banner; the active one stretches and fills as the timer runs.
class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.count,
    required this.current,
    required this.progress,
  });

  final int count;
  final int current;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: i == current ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(3),
                ),
                clipBehavior: Clip.antiAlias,
                child: i == current
                    ? AnimatedBuilder(
                        animation: progress,
                        builder: (context, _) => Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FractionallySizedBox(
                            widthFactor: progress.value,
                            child: const ColoredBox(color: Colors.white),
                          ),
                        ),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
