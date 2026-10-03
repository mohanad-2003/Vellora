import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/asset_paths.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_snackbar.dart';

/// UI-only social sign-in row. There is no OAuth integration yet, so tapping a
/// provider says so honestly instead of pretending to sign the user in.
///
/// "Continue with Apple" is shown only on Apple platforms, as Apple's
/// guidelines require it there and it has no meaning elsewhere.
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  static bool get _showApple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final providers = <_Provider>[
      _Provider(AssetPaths.socialGoogle, l10n.continueWithGoogle),
      if (_showApple)
        _Provider(AssetPaths.socialApple, l10n.continueWithApple, tint: true),
      _Provider(AssetPaths.socialFacebook, l10n.continueWithFacebook),
    ];

    return Row(
      children: [
        for (var i = 0; i < providers.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: _SocialButton(provider: providers[i])),
        ],
      ],
    );
  }
}

class _Provider {
  const _Provider(this.asset, this.label, {this.tint = false});

  final String asset;
  final String label;

  /// Monochrome marks (Apple) are tinted to stay visible in dark mode.
  final bool tint;
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.provider});

  final _Provider provider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: provider.label,
      excludeSemantics: true,
      onTap: () => _notAvailable(context),
      child: InkWell(
        borderRadius: AppRadius.rMd,
        onTap: () => _notAvailable(context),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(color: colors.outlineVariant, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            provider.asset,
            height: 24,
            width: 24,
            // Source marks are thousands of px wide; decode them at icon size.
            cacheWidth: 72,
            filterQuality: FilterQuality.medium,
            color: provider.tint ? colors.onSurface : null,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.login_rounded, size: 22),
          ),
        ),
      ),
    );
  }

  void _notAvailable(BuildContext context) =>
      AppSnackbar.show(context, message: context.l10n.comingSoon);
}
