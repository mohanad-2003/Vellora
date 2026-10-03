import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
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

/// Promotional banner: copy and a call to action on the start side, a
/// product/lifestyle photo fading in from the end side. Layout mirrors in RTL.
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.imagePath,
    required this.style,
    required this.onTap,
    this.eyebrow,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final String imagePath;
  final PromoBannerStyle style;
  final VoidCallback onTap;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    // Panel colour where the photo meets the text area.
    final edge = Color.lerp(style.background.first, style.background.last, 0.55)!;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
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
                final imageWidth = c.maxWidth * 0.46;
                return Stack(
                  children: [
                    PositionedDirectional(
                      top: 0,
                      bottom: 0,
                      end: 0,
                      width: imageWidth,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ProductImage(
                            path: imagePath,
                            fit: BoxFit.cover,
                            padding: EdgeInsets.zero,
                          ),
                          // Fade the photo into the panel on its start edge.
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: AlignmentDirectional.centerStart,
                                end: AlignmentDirectional.centerEnd,
                                colors: [
                                  edge,
                                  edge.withValues(alpha: 0),
                                ],
                                stops: const [0, 0.55],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        20,
                        18,
                        imageWidth * 0.55,
                        18,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (eyebrow != null)
                            Text(
                              eyebrow!,
                              style: text.labelSmall?.copyWith(
                                color:
                                    style.foreground.withValues(alpha: 0.85),
                              ),
                            ),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.headlineMedium
                                ?.copyWith(color: style.foreground),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: style.foreground.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: style.cta,
                              borderRadius: AppRadius.rPill,
                            ),
                            child: Text(
                              ctaLabel,
                              style: text.labelMedium
                                  ?.copyWith(color: style.ctaForeground),
                            ),
                          ),
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
    );
  }
}
