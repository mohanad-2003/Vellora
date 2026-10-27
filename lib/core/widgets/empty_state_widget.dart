import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// The illustrated pictures for empty states, in `assets/images/empty/`.
class EmptyArt {
  EmptyArt._();

  static const String _dir = 'assets/images/empty/';
  static const String cart = '${_dir}empty_cart.png';
  static const String wishlist = '${_dir}empty_wishlist.png';
  static const String orders = '${_dir}empty_orders.png';
  static const String notifications = '${_dir}empty_notifications.png';
  static const String addresses = '${_dir}empty_addresses.png';
  static const String payment = '${_dir}empty_payment.png';
  static const String search = '${_dir}empty_search.png';
  static const String products = '${_dir}empty_products.png';
  static const String filters = '${_dir}empty_filters.png';
  static const String signInRequired = '${_dir}sign_in_required.png';
  static const String notFound = '${_dir}not_found.png';
  static const String comingSoon = '${_dir}coming_soon.png';
}

/// Empty-state placeholder: a drawn picture (or a soft icon medallion when none
/// is given), title, short message and an optional call to action. Scrolls when
/// space is tight (landscape, large text) so it can never overflow.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.illustration,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String? message;
  final IconData icon;

  /// An [EmptyArt] picture shown instead of the icon medallion.
  final String? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (illustration != null)
                      _Illustration(path: illustration!)
                    else
                      _Medallion(icon: icon, color: colors.primary),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      title,
                      style: context.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        message!,
                        style: context.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      AppButton(
                        label: actionLabel!,
                        onPressed: onAction,
                        expand: false,
                      ),
                    ],
                    if (secondaryLabel != null && onSecondary != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: secondaryLabel!,
                        variant: AppButtonVariant.text,
                        onPressed: onSecondary,
                        expand: false,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Transparent artwork sits on a theme-aware halo so ivory details stay legible
/// in light mode and the emerald and gold edges stay clear in dark mode.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = context.colors.primary;
    return ExcludeSemantics(
      child: Container(
        width: 200,
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: dark
                ? const [Color(0xFF1C4137), Color(0xFF112B24)]
                : const [Color(0xFFFFFFFF), Color(0xFFE4F1EC)],
          ),
          border: Border.all(
            color: primary.withValues(alpha: dark ? 0.28 : 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: dark ? 0.10 : 0.06),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            path,
            width: 184,
            height: 184,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => _Medallion(
              icon: Icons.image_not_supported_outlined,
              color: primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon on a gradient disc inside two soft rings, with a few champagne sparks —
/// the shared fallback illustration for an empty or error state.
class _Medallion extends StatelessWidget {
  const _Medallion({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spark = context.vellora.accent;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 148,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.05),
              ),
            ),
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.08),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
            ),
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0.10),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 38, color: color),
            ),
            PositionedDirectional(
              top: 14,
              end: 20,
              child: _Spark(size: 10, color: spark),
            ),
            PositionedDirectional(
              bottom: 22,
              start: 10,
              child: _Spark(size: 7, color: spark.withValues(alpha: 0.7)),
            ),
            PositionedDirectional(
              top: 44,
              start: 2,
              child: _Spark(size: 5, color: color.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spark extends StatelessWidget {
  const _Spark({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
