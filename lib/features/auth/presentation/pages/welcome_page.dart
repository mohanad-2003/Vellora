import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/asset_paths.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_artwork.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../core/widgets/vellora_logo.dart';

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
    final content = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EC),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.welcomeTitle,
              style: text.displayMedium?.copyWith(color: kBrandNavy),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.welcomeTagline,
            style: text.bodyMedium?.copyWith(color: const Color(0xFF52655E)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pushNamed(RouteNames.nRegister),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandNavy,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 54),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(l10n.createAccount, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.pushNamed(RouteNames.nLogin),
            style: OutlinedButton.styleFrom(
              foregroundColor: kBrandNavy,
              minimumSize: const Size(0, 54),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              side: const BorderSide(color: Color(0xFFC5CEC6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(l10n.login, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => context.goNamed(RouteNames.nHome),
            style: TextButton.styleFrom(
              foregroundColor: kBrandNavy,
              minimumSize: const Size(0, 48),
            ),
            child: Text(l10n.continueAsGuest, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: text.bodySmall?.copyWith(color: const Color(0xFF52655E)),
              children: [
                TextSpan(text: l10n.agreeToTerms),
                TextSpan(
                  text: l10n.termsAndPrivacy,
                  style: const TextStyle(
                    color: kBrandNavy,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _termsTap,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kBrandNavy,
        body: BrandBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 20, 28, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: VelloraLogo(height: 32, onDark: true),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      const artwork = BrandArtwork(
                        imagePath: AssetPaths.onboardingRack,
                      );
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (constraints.maxHeight - 20).clamp(
                              0.0,
                              double.infinity,
                            ),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: wide ? 1000 : 460,
                              ),
                              child: wide
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: (constraints.maxHeight - 40)
                                                .clamp(120.0, 430.0),
                                            child: artwork,
                                          ),
                                        ),
                                        const SizedBox(width: 40),
                                        Expanded(child: content),
                                      ],
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: (constraints.maxHeight * 0.30)
                                              .clamp(130.0, 260.0),
                                          child: artwork,
                                        ),
                                        const SizedBox(height: 12),
                                        content,
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
