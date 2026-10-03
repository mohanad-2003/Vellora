import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/promo_banner.dart';
import '../../domain/entities/banner_entity.dart';

/// Auto-advancing promotional banners with a page indicator.
///
/// Auto-play pauses while the user drags, never runs when the system asks for
/// reduced motion, and its timer is cancelled on dispose.
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

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _autoPlay;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlay?.cancel();
    if (widget.banners.length < 2) return;
    _autoPlay = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      final next = (_index + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  PromoBannerStyle _styleFor(BannerEntity b) {
    switch (b.id) {
      case 'flash':
        return const PromoBannerStyle(
          background: [Color(0xFFDC2F3A), Color(0xFFFF6B4A)],
          foreground: Colors.white,
          cta: Colors.white,
          ctaForeground: Color(0xFFB42318),
        );
      case 'new':
        return const PromoBannerStyle(
          background: [Color(0xFFFFE1E8), Color(0xFFFFC4D2)],
          foreground: Color(0xFF3A0F1C),
          cta: Color(0xFF12141A),
          ctaForeground: Colors.white,
        );
      case 'summer':
      default:
        return const PromoBannerStyle(
          background: [Color(0xFF3641C0), Color(0xFF6A3FC4)],
          foreground: Colors.white,
          cta: Colors.white,
          ctaForeground: Color(0xFF2B3496),
        );
    }
  }

  (String, String) _copyFor(BannerEntity b) {
    final l10n = context.l10n;
    switch (b.id) {
      case 'flash':
        return (l10n.bannerFlashTitle, l10n.bannerFlashSubtitle);
      case 'new':
        return (l10n.bannerNewTitle, l10n.bannerNewSubtitle);
      case 'summer':
        return (l10n.bannerSummerTitle, l10n.bannerSummerSubtitle);
      default:
        return (b.title, b.subtitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Height tracks the width but is clamped, and grows with the text scale so
    // the copy never clips.
    final width = MediaQuery.sizeOf(context).width.clamp(0.0, 720.0);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final height = (width * 0.46).clamp(168.0, 230.0) * (0.85 + 0.15 * scale);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _autoPlay?.cancel();
              } else if (n is ScrollEndNotification) {
                _startAutoPlay();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.banners.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final b = widget.banners[i];
                final (title, subtitle) = _copyFor(b);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: PromoBanner(
                    title: title,
                    subtitle: subtitle,
                    ctaLabel: l10n.shopNow,
                    imagePath: b.imagePath,
                    style: _styleFor(b),
                    onTap: () => widget.onBannerTap(b),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: l10n.pageOf(_index + 1, widget.banners.length),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index
                      ? context.colors.primary
                      : context.colors.outlineVariant,
                  borderRadius: AppRadius.rPill,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
