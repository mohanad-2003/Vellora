import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/localization/l10n_lookup.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/utils/haptics.dart';

/// Size (or any text option) picker: wrapping chips with a 48dp touch target.
class VariantSelector extends StatelessWidget {
  const VariantSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: options.map((option) {
            final isSelected = option == selected;
            return Semantics(
              button: true,
              selected: isSelected,
              label: option,
              excludeSemantics: true,
              onTap: () => onSelected(option),
              child: InkWell(
                onTap: () {
                  Haptics.selection();
                  onSelected(option);
                },
                borderRadius: AppRadius.rMd,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: const BoxConstraints(
                    minWidth: 52,
                    minHeight: 48,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : colors.surface,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : colors.outlineVariant,
                      width: 1.4,
                    ),
                  ),
                  // widthFactor/heightFactor keep the chip hugging its label.
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      option,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: isSelected ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Colour picker: round swatches with a check on the selected one and the
/// localized colour name beside the heading.
class ColorSwatchSelector extends StatelessWidget {
  const ColorSwatchSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  static Color swatch(String name) {
    switch (name.toLowerCase()) {
      case 'black':
        return const Color(0xFF16181F);
      case 'white':
        return const Color(0xFFFFFFFF);
      case 'red':
        return const Color(0xFFE5484D);
      case 'navy':
        return const Color(0xFF1F2A5A);
      case 'sand':
        return const Color(0xFFD9C5A0);
      case 'olive':
        return const Color(0xFF6B7A3A);
      default:
        return const Color(0xFF9AA1B0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: context.textTheme.titleMedium),
            if (selected != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                colorLabel(context, selected!),
                style: context.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: options.map((name) {
            final isSelected = name == selected;
            final color = swatch(name);
            final dark = color.computeLuminance() < 0.4;
            return Semantics(
              button: true,
              selected: isSelected,
              label: colorLabel(context, name),
              excludeSemantics: true,
              onTap: () => onSelected(name),
              child: InkResponse(
                onTap: () {
                  Haptics.selection();
                  onSelected(name);
                },
                radius: 28,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: isSelected ? 44 : 38,
                      height: isSelected ? 44 : 38,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colors.primary
                              : colors.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.outlineVariant,
                            width: 0.5,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: dark ? Colors.white : Colors.black87,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
