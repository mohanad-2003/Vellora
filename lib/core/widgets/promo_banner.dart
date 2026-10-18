import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/core/utils/haptics.dart';

import 'product_image.dart';

/// Visual treatment of a [PromoBanner].
class PromoBannerStyle {
  const PromoBannerStyle({
    required this.background,
    required this.foreground,
    required this.cta,
    required this.ctaForeground,
  });

  /// Panel gradient.
  final List<Color> background;
  final Color foreground;
  final Color cta;
  final Color ctaForeground;
}

/// Promotional banner: copy and a call to action on the start side, the photo
/// on the end side. The photo is shown whole, with a clean rounded cut against
/// the panel and nothing laid over it. Layout mirrors in RTL.
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.style,
    this.ctaLabel,
    this.onTap,
    this.eyebrow,
    this.deadline,
  });

  final String title;
  final String subtitle;

  /// The call-to-action pill; left out for a banner that opens nothing.
  final String? ctaLabel;
  final String imagePath;
  final PromoBannerStyle style;

  /// Null for a banner that opens nothing: no press effect either.
  final VoidCallback? onTap;
  final String? eyebrow;

  /// When the offer ends. A countdown shows over the picture while it is
  /// within [countdownWithin] of ending.
  final DateTime? deadline;

  static const countdownWithin = Duration(hours: 72);

  static const _cut = BorderRadiusDirectional.horizontal(
    start: Radius.circular(30),
  );

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final fg = style.foreground;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: _PressScale(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.rXl,
            boxShadow: [
              BoxShadow(
                color: style.background.last.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.rXl,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: style.background,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  final imageWidth = c.maxWidth * 0.42;
                  return Stack(
                    children: [
                      // Soft rings give the flat panel some depth.
                      PositionedDirectional(
                        start: -c.maxWidth * 0.12,
                        bottom: -c.maxWidth * 0.22,
                        child: _Ring(size: c.maxWidth * 0.55, color: fg),
                      ),
                      PositionedDirectional(
                        end: imageWidth * 0.55,
                        top: -c.maxWidth * 0.16,
                        child: _Ring(size: c.maxWidth * 0.36, color: fg),
                      ),
                      PositionedDirectional(
                        top: 0,
                        bottom: 0,
                        end: 0,
                        width: imageWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: _cut,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 16,
                                offset: const Offset(-4, 0),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: _cut,
                            child: ProductImage(
                              path: imagePath,
                              fit: BoxFit.cover,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      if (deadline != null)
                        PositionedDirectional(
                          top: 12,
                          end: 12,
                          child: BannerCountdown(deadline: deadline!),
                        ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          20,
                          16,
                          imageWidth + 12,
                          16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (eyebrow != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: fg.withValues(alpha: 0.16),
                                  borderRadius: AppRadius.rPill,
                                  border: Border.all(
                                    color: fg.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Text(
                                  eyebrow!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelSmall?.copyWith(
                                    color: fg,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.headlineSmall?.copyWith(color: fg),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                color: fg.withValues(alpha: 0.88),
                              ),
                            ),
                            if (ctaLabel != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: style.cta,
                                  borderRadius: AppRadius.rPill,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        ctaLabel!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.labelMedium?.copyWith(
                                          color: style.ctaForeground,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: style.ctaForeground,
                                      // Points the way the text reads (flips in RTL).
                                      textDirection: Directionality.of(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "02 : 14 : 33" over the picture, ticking each second; nothing while the end
/// is far off, and nothing once it has passed.
class BannerCountdown extends StatefulWidget {
  const BannerCountdown({super.key, required this.deadline, this.now});

  final DateTime deadline;

  /// The clock; replaced in tests.
  final DateTime Function()? now;

  @override
  State<BannerCountdown> createState() => _BannerCountdownState();
}

class _BannerCountdownState extends State<BannerCountdown> {
  Timer? _ticker;
  late Duration _left = _compute();

  Duration _compute() =>
      widget.deadline.difference((widget.now ?? DateTime.now)());

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _left = _compute());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (_left <= Duration.zero || _left > PromoBanner.countdownWithin) {
      return const SizedBox.shrink();
    }
    final label =
        '${_two(_left.inHours)}:${_two(_left.inMinutes.remainder(60))}:'
        '${_two(_left.inSeconds.remainder(60))}';
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: AppRadius.rPill,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Directionality(
            // Digits read left to right in Arabic too.
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A faint outlined circle used as background decoration.
class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.10), width: 1.5),
        ),
      ),
    );
  }
}

/// Shrinks slightly while pressed, with a light haptic on tap.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              Haptics.selection();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
