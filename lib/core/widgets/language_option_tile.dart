import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/haptics.dart';

/// Selectable language row for the language screen and settings.
///
/// Shows a short monogram (e.g. "EN", "ع"), the language name in its own
/// script, a secondary label and a radio-style indicator. Deliberately uses no
/// country flags — a flag is not a language.
class LanguageOptionTile extends StatelessWidget {
  const LanguageOptionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String glyph;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primary = colors.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: () {
          if (!selected) Haptics.selection();
          onTap();
        },
        borderRadius: AppRadius.rLg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surface,
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: selected ? primary : colors.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? primary : colors.surfaceContainerHighest,
                  borderRadius: AppRadius.rMd,
                ),
                child: Text(
                  glyph,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: selected ? colors.onPrimary : colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? primary : colors.outline,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 16, color: colors.onPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
