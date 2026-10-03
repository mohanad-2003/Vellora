import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Client-side password strength level.
enum PasswordStrength { none, weak, medium, strong }

/// Computes strength from length + character-class variety.
PasswordStrength computePasswordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.none;
  var score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password)) {
    score++;
  }
  if (RegExp(r'\d').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

  if (score <= 1) return PasswordStrength.weak;
  if (score <= 3) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

/// Reusable strength bar (3 segments) + label. Segments fill by level and the
/// label text is single-line/ellipsised to stay overflow-safe.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = computePasswordStrength(password);
    if (strength == PasswordStrength.none) {
      return const SizedBox.shrink();
    }

    final (filled, color, label) = switch (strength) {
      PasswordStrength.weak => (1, AppColors.error, context.l10n.weak),
      PasswordStrength.medium => (2, AppColors.warning, context.l10n.medium),
      PasswordStrength.strong => (3, AppColors.success, context.l10n.strong),
      PasswordStrength.none => (0, AppColors.error, ''),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.vSm),
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsetsDirectional.only(end: i < 2 ? AppSpacing.xs : 0),
                height: 6,
                decoration: BoxDecoration(
                  color: i < filled
                      ? color
                      : context.colors.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: AppRadius.rPill,
                ),
              ),
            );
          }),
        ),
        SizedBox(height: AppSpacing.vXs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                context.l10n.passwordStrength,
                style: context.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
