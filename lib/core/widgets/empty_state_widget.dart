import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Empty-state placeholder: soft icon medallion, title, short message and an
/// optional call to action. Scrolls when space is tight (landscape, large
/// text) so it can never overflow.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String? message;
  final IconData icon;
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
