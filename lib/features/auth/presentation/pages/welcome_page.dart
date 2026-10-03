import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/asset_paths.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/vellora_logo.dart';
import '../../../../core/widgets/staggered_reveal.dart';

/// First impression: a full-bleed fashion photograph, the brand, one line of
/// value proposition and the two entry actions. Everything else (social
/// sign-in, forms) lives on the Login / Register screens.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => context.pushNamed(RouteNames.nTermsPrivacy);

  @override
  void dispose() {
    _termsTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final gutter = context.pageGutter;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kBrandNavy,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AssetPaths.onboardingRack,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, _, _) => const ColoredBox(color: kBrandNavy),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Color(0x00000000),
                    Color(0x660B0E2E),
                    Color(0xF20B0E2E),
                  ],
                  stops: [0, 0.28, 0.55, 1],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: AppSpacing.lg),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: VelloraLogo(height: 44, onDark: true),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.huge),
                          ResponsiveCenter(
                            child: StaggeredReveal(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xl,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        l10n.welcomeTitle,
                                        style: text.displayMedium?.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      l10n.welcomeTagline,
                                      style: text.bodyLarge?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxl),
                                    _LightButton(
                                      label: l10n.createAccount,
                                      onPressed: () => context.pushNamed(
                                        RouteNames.nRegister,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _GhostButton(
                                      label: l10n.login,
                                      onPressed: () =>
                                          context.pushNamed(RouteNames.nLogin),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Center(
                                      child: TextButton(
                                        onPressed: () =>
                                            context.goNamed(RouteNames.nHome),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(l10n.continueAsGuest),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text.rich(
                                      TextSpan(
                                        style: text.bodySmall?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                        children: [
                                          TextSpan(text: l10n.agreeToTerms),
                                          TextSpan(
                                            text: l10n.termsAndPrivacy,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: Colors.white,
                                            ),
                                            recognizer: _termsTap,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand-gold filled CTA for use over photography.
class _LightButton extends StatelessWidget {
  const _LightButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kBrandGold,
          foregroundColor: const Color(0xFF14102E),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

/// Outlined CTA for use over photography.
class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.10),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
