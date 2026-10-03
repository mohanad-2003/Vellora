import 'package:flutter/material.dart';

/// Window-width breakpoints (Material 3 window size classes).
class Breakpoints {
  Breakpoints._();

  /// Phones in portrait.
  static const double compact = 600;

  /// Large phones in landscape / small tablets.
  static const double medium = 840;

  /// Tablets and desktop-like windows.
  static const double expanded = 1200;

  /// Widest a single-column reading/form layout should grow.
  static const double formMaxWidth = 460;

  /// Widest a content page should grow before it is centred.
  static const double contentMaxWidth = 1100;
}

/// Product-grid columns for an available [width] (window or sliver width).
int gridColumnsForWidth(double width) {
  if (width >= 1040) return 5;
  if (width >= 800) return 4;
  if (width >= 560) return 3;
  return 2;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isCompact => screenWidth < Breakpoints.compact;
  bool get isTablet => screenWidth >= Breakpoints.compact;
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// A short window (landscape phone) where tall hero layouts must collapse.
  bool get isShort => screenHeight < 520;

  double get textScale => MediaQuery.textScalerOf(this).scale(1);

  /// Product-grid column count for the current window width.
  int get gridColumns => gridColumnsForWidth(screenWidth);

  /// Horizontal page gutter that grows gently on larger windows.
  double get pageGutter => isTablet ? 32 : 20;
}

/// Centres [child] and caps its width. Use for forms and single-column pages
/// so they stay readable on tablets and landscape.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.formMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
