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

/// Icon on two soft concentric discs — the shared "illustration" for empty and
/// error states.
class _Medallion extends StatelessWidget {
  const _Medallion({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 128,
        height: 128,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.07),
        ),
        child: Container(
          width: 92,
          height: 92,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Icon(icon, size: 40, color: color),
        ),
      ),
    );
  }
}
