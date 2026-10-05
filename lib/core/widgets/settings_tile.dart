import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// A single settings row: a soft-tinted leading icon, a title/subtitle column,
/// and a trailing widget (defaults to a chevron when [onTap] is set).
/// Content-driven height — never tied to a `.w` width.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Overrides the leading icon tint. Ignored when [destructive] is true.
  final Color? iconColor;

  /// Renders the row in the error color (used for Logout).
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent =
        destructive ? context.colors.error : (iconColor ?? context.colors.primary);
    final titleColor = destructive ? context.colors.error : null;

    final flat = _FlatScope.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: flat ? null : AppRadius.rLg,
        child: Padding(
          padding: EdgeInsets.symmetric(
            // Flat rows line up with the page's own margin.
            horizontal: flat ? 0 : AppSpacing.md,
            vertical: AppSpacing.vMd,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.rMd,
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              trailing ??
                  (onTap != null
                      ? Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: context.colors.outline,
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marks its subtree as flat, so [SettingsTile]s drop their side padding.
class _FlatScope extends InheritedWidget {
  const _FlatScope({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FlatScope>() != null;

  @override
  bool updateShouldNotify(_FlatScope oldWidget) => false;
}

/// A list of [SettingsTile]s drawn straight on the page: no card or border,
/// just a divider between rows that starts after the icon.
class FlatTileGroup extends StatelessWidget {
  const FlatTileGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _FlatScope(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                // Past the 40-wide icon and the gap that follows it.
                indent: 40 + AppSpacing.lg,
                color: context.colors.outlineVariant,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
