import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/vellora_logo.dart';

/// Centred header shared by every authentication screen.
///
/// * [showLogo] puts the Vellora logo on a soft brand glow above the title
///   (Login, Register, Forgot password).
/// * [icon] instead shows a tinted medallion for deeper steps of a flow
///   (verification code, new password), where the brand mark would just repeat.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLogo = false,
    this.icon,
  });

  final String title;
  final String subtitle;
  final bool showLogo;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    Widget? lead;
    if (showLogo) {
      lead = SizedBox(
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Soft violet halo behind the logo — brand atmosphere, not chrome.
            Container(
              width: 320,
              height: 200,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withValues(
                      alpha: context.isDark ? 0.22 : 0.12,
                    ),
                    colors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            const VelloraLogo(height: 52),
          ],
        ),
      );
    } else if (icon != null) {
      lead = Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.primaryContainer,
        ),
        child: Icon(icon, size: 38, color: colors.primary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (lead != null) ...[lead, const SizedBox(height: AppSpacing.lg)],
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: text.displaySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}
