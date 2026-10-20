import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// The drawn pictures for empty states, in `assets/images/empty/`.
class EmptyArt {
  EmptyArt._();

  static const String _dir = 'assets/images/empty/';
  static const String cart = '${_dir}empty_cart.svg';
  static const String wishlist = '${_dir}empty_wishlist.svg';
  static const String orders = '${_dir}empty_orders.svg';
  static const String notifications = '${_dir}empty_notifications.svg';
  static const String addresses = '${_dir}empty_addresses.svg';
  static const String payment = '${_dir}empty_payment.svg';
  static const String search = '${_dir}empty_search.svg';
  static const String products = '${_dir}empty_products.svg';
  static const String filters = '${_dir}empty_filters.svg';
  static const String signInRequired = '${_dir}sign_in_required.svg';
  static const String notFound = '${_dir}not_found.svg';
  static const String comingSoon = '${_dir}coming_soon.svg';
}

/// Empty-state placeholder: a drawn picture (or a soft icon medallion when none
/// is given), title, short message and an optional call to action. Scrolls when space is tight (landscape, large
/// text) so it can never overflow.
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
                      _Illustration(
                        path: illustration!,
                        fallback: _Medallion(icon: icon, color: colors.primary),
                      )
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

/// One of the [EmptyArt] pictures. Its pale disc is dimmed a little in dark
/// mode so it does not glare against the dark page.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.path, required this.fallback});

  final String path;

  /// Shown if the picture cannot be read, so a bad file never breaks a screen.
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final picture = SvgPicture.asset(
      path,
      width: 200,
      height: 200,
      errorBuilder: (_, _, _) => fallback,
    );
    return ExcludeSemantics(
      child: dark
          ? ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.3),
                BlendMode.srcATop,
              ),
              child: picture,
            )
          : picture,
    );
  }
}

/// Icon on a gradient disc inside two soft rings, with a few champagne sparks —
/// the shared "illustration" for empty and error states.
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
