import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/haptics.dart';

/// Radio-style selectable row used for address, delivery and payment choices.
/// The border highlights only when selected; a leading widget, title, optional
/// subtitle and trailing widget are all optional building blocks.
class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.title,
    required this.selected,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showRadio = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;

  /// Hide the radio indicator for read-only presentations.
  final bool showRadio;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: subtitle == null ? title : '$title, $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                if (!selected) Haptics.selection();
                onTap!();
              },
        borderRadius: AppRadius.rLg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer.withValues(alpha: 0.5) : colors.surface,
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: text.titleSmall),
                    if (subtitle != null)
                      Text(subtitle!, style: text.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
              if (showRadio) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? colors.primary : colors.outline,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Square tinted icon container for [SelectableTile.leading].
class TileIcon extends StatelessWidget {
  const TileIcon({super.key, required this.icon, this.child});

  final IconData icon;

  /// Replaces the icon (e.g. a payment-brand logo).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: AppRadius.rMd,
      ),
      child: child ?? Icon(icon, color: context.colors.primary, size: 22),
    );
  }
}
