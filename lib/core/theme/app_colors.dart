import 'package:flutter/material.dart';

/// Raw Vellora palette. Widgets should read colours from the theme
/// (`context.colors`, `context.vellora`) rather than from here; this file is the
/// single source of truth for the values the theme is built from.
class AppColors {
  AppColors._();

  // Brand.
  static const Color seed = Color(0xFF4553D8);
  static const Color primary = Color(0xFF4553D8);
  static const Color primaryDark = Color(0xFF8D98FF);
  static const Color primarySoft = Color(0xFFE9EBFC);
  static const Color primarySoftDark = Color(0xFF232849);
  static const Color secondary = Color(0xFF14161F);
  static const Color accent = Color(0xFFFF5A5F);

  // Semantic.
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color star = Color(0xFFFFB400);

  // Light surfaces.
  static const Color lightBackground = Color(0xFFFAFAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF2F3F7);
  static const Color lightDivider = Color(0xFFE6E8EF);
  static const Color lightTextPrimary = Color(0xFF12141A);
  static const Color lightTextSecondary = Color(0xFF5B6270);
  static const Color lightImageBackdrop = Color(0xFFF1F2F6);

  // Dark surfaces.
  static const Color darkBackground = Color(0xFF0E1015);
  static const Color darkSurface = Color(0xFF171A21);
  static const Color darkSurfaceVariant = Color(0xFF20242D);
  static const Color darkDivider = Color(0xFF2B303B);
  static const Color darkTextPrimary = Color(0xFFF4F5F8);
  static const Color darkTextSecondary = Color(0xFFA3AAB8);
  static const Color darkImageBackdrop = Color(0xFF20242D);

  static const Color shadow = Color(0x14000000);
}

/// Colours that Material's [ColorScheme] has no slot for. Read with
/// `context.vellora`.
@immutable
class VelloraColors extends ThemeExtension<VelloraColors> {
  const VelloraColors({
    required this.accent,
    required this.success,
    required this.warning,
    required this.star,
    required this.imageBackdrop,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.primarySoft,
  });

  final Color accent;
  final Color success;
  final Color warning;
  final Color star;
  final Color imageBackdrop;
  final Color skeletonBase;
  final Color skeletonHighlight;
  final Color primarySoft;

  static const light = VelloraColors(
    accent: AppColors.accent,
    success: AppColors.success,
    warning: AppColors.warning,
    star: AppColors.star,
    imageBackdrop: AppColors.lightImageBackdrop,
    skeletonBase: Color(0xFFE9EBF1),
    skeletonHighlight: Color(0xFFF6F7FA),
    primarySoft: AppColors.primarySoft,
  );

  static const dark = VelloraColors(
    accent: Color(0xFFFF7478),
    success: Color(0xFF34D27B),
    warning: Color(0xFFFBBF4A),
    star: AppColors.star,
    imageBackdrop: AppColors.darkImageBackdrop,
    skeletonBase: Color(0xFF232731),
    skeletonHighlight: Color(0xFF2D323E),
    primarySoft: AppColors.primarySoftDark,
  );

  @override
  VelloraColors copyWith({
    Color? accent,
    Color? success,
    Color? warning,
    Color? star,
    Color? imageBackdrop,
    Color? skeletonBase,
    Color? skeletonHighlight,
    Color? primarySoft,
  }) =>
      VelloraColors(
        accent: accent ?? this.accent,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        star: star ?? this.star,
        imageBackdrop: imageBackdrop ?? this.imageBackdrop,
        skeletonBase: skeletonBase ?? this.skeletonBase,
        skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
        primarySoft: primarySoft ?? this.primarySoft,
      );

  @override
  VelloraColors lerp(ThemeExtension<VelloraColors>? other, double t) {
    if (other is! VelloraColors) return this;
    return VelloraColors(
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      star: Color.lerp(star, other.star, t)!,
      imageBackdrop: Color.lerp(imageBackdrop, other.imageBackdrop, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight:
          Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
    );
  }
}

/// Vellora signature gold and the deep navy it sits on. Used on the dark brand
/// moments (language, onboarding, welcome) regardless of the app theme.
const Color kBrandGold = Color(0xFFE9B861);
const Color kBrandNavy = Color(0xFF0B0E2E);
