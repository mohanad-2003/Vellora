import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/google_id_token.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../bloc/auth_bloc.dart';

/// The social sign-in row. "Continue with Google" is real: it asks Google for the person's ID token and
/// hands it to the [AuthBloc], which signs in or creates the account on the server. The other providers
/// are not connected yet, so tapping them says so honestly instead of pretending to sign the user in.
///
/// "Continue with Apple" is shown only on Apple platforms, as Apple's
/// guidelines require it there and it has no meaning elsewhere.
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key, this.height = 52});

  final double height;

  static bool get _showApple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final providers = <_Provider>[
      _Provider(AssetPaths.socialGoogle, l10n.continueWithGoogle, google: true),
      if (_showApple)
        _Provider(AssetPaths.socialApple, l10n.continueWithApple, tint: true),
      _Provider(AssetPaths.socialFacebook, l10n.continueWithFacebook),
    ];

    return Row(
      children: [
        for (var i = 0; i < providers.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _SocialButton(provider: providers[i], height: height),
          ),
        ],
      ],
    );
  }
}

class _Provider {
  const _Provider(
    this.asset,
    this.label, {
    this.tint = false,
    this.google = false,
  });

  final String asset;
  final String label;

  /// The one provider that signs in for real.
  final bool google;

  /// Monochrome marks (Apple) are tinted to stay visible in dark mode.
  final bool tint;
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.provider, required this.height});

  final _Provider provider;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: provider.label,
      excludeSemantics: true,
      onTap: () => _tap(context),
      child: InkWell(
        borderRadius: AppRadius.rMd,
        onTap: () => _tap(context),
        child: Container(
          height: height,
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

  void _tap(BuildContext context) =>
      provider.google ? _signInWithGoogle(context) : _notAvailable(context);

  Future<void> _signInWithGoogle(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final l10n = context.l10n;
    // Do nothing while an earlier sign-in is still being sent.
    if (bloc.state.status == AuthStatus.loading) return;
    try {
      final idToken = await googleIdTokenSource();
      // null: the person closed the account chooser.
      if (idToken == null || bloc.isClosed) return;
      bloc.add(AuthGoogleSubmitted(idToken: idToken));
    } catch (_) {
      if (context.mounted) AppSnackbar.error(context, l10n.googleSignInFailed);
    }
  }

  void _notAvailable(BuildContext context) =>
      AppSnackbar.show(context, message: context.l10n.comingSoon);
}
