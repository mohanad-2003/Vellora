/// 4-pt spacing scale: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48.
///
/// Plain, unscaled logical pixels. Use these everywhere instead of ad-hoc
/// numbers. Horizontal (`xs`…) and vertical (`vXs`…) names are kept so existing
/// call sites read naturally; both resolve to the same scale.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double x4l = 40;
  static const double huge = 48;

  static const double vXs = xs;
  static const double vSm = sm;
  static const double vMd = md;
  static const double vLg = lg;
  static const double vXl = xl;
  static const double vXxl = xxl;
  static const double vXxxl = xxxl;

  /// Standard screen edge padding.
  static const double screenH = lg + xs; // 20
  static const double screenV = lg;
}
