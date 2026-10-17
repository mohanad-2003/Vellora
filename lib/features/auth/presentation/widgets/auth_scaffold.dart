import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/vellora_logo.dart';
import 'social_login_buttons.dart';

/// How much room the screen has, and what to show because of it.
///
/// Login and Register are meant to fit on one screen without scrolling. The
/// density is chosen from the screen height with the keyboard closed (so it
/// does not jump while typing); what does not fit is dropped (the subtitle,
/// then the social row) rather than scrolled.
@immutable
class AuthDensity {
  const AuthDensity({
    required this.logoHeight,
    required this.gap,
    required this.fieldPadding,
    required this.showSubtitle,
    required this.showSocial,
    required this.socialHeight,
    required this.large,
    this.showLogo = true,
  });

  final double logoHeight;

  /// Space between form rows.
  final double gap;

  /// Vertical padding inside a text field (16 gives the usual 56dp field).
  final double fieldPadding;
  final bool showSubtitle;
  final bool showSocial;
  final double socialHeight;

  /// Roomy phones get the larger title.
  final bool large;

  /// Dropped on the smallest screens, where the title alone has to do.
  final bool showLogo;

  /// [available] is the window height minus the system bars. [socialMin] is
  /// the height from which the screen has room for the social row.
  factory AuthDensity.forHeight(double available, {required double socialMin}) {
    if (available >= 740) {
      return AuthDensity(
        logoHeight: 46,
        gap: 16,
        fieldPadding: 16,
        showSubtitle: true,
        showSocial: available >= socialMin,
        socialHeight: 50,
        large: true,
      );
    }
    if (available >= 620) {
      return AuthDensity(
        logoHeight: 38,
        gap: 12,
        fieldPadding: 15,
        showSubtitle: true,
        showSocial: available >= socialMin,
        socialHeight: 46,
        large: false,
      );
    }
    if (available >= 560) {
      return AuthDensity(
        logoHeight: 30,
        gap: 10,
        fieldPadding: 13,
        showSubtitle: false,
        showSocial: available >= socialMin,
        socialHeight: 44,
        large: false,
      );
    }
    return AuthDensity(
      logoHeight: 0,
      gap: 8,
      fieldPadding: 11,
      showSubtitle: false,
      showSocial: available >= socialMin,
      socialHeight: 44,
      large: false,
      showLogo: false,
    );
  }
}

/// The frame shared by Login and Register: a slim top bar with Back, the logo
/// and title, the form, then the social row and the "switch screen" link
/// pinned to the bottom.
///
/// It scrolls only as a safety net: when the keyboard is open, or the text is
/// scaled up, and the content is taller than the screen. On a closed keyboard
/// at normal text size it always fits.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.switchPrompt,
    required this.switchLabel,
    required this.onSwitch,
    required this.socialMinHeight,
    this.banner,
    this.orLabel,
  });

  final String title;
  final String subtitle;

  /// The form, built for the current [AuthDensity].
  final Widget Function(BuildContext context, AuthDensity density) body;

  /// "Don't have an account?" and the link beside it.
  final String switchPrompt;
  final String switchLabel;
  final VoidCallback onSwitch;

  /// Window height (minus system bars) needed to also show the social row.
  final double socialMinHeight;
  final Widget? banner;
  final String? orLabel;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final available =
        media.size.height - media.padding.top - media.padding.bottom;
    final density = AuthDensity.forHeight(
      available,
      socialMin: socialMinHeight,
    );
    final text = context.textTheme;
    final canPop =
        GoRouter.maybeOf(context)?.canPop() ?? Navigator.canPop(context);
    final gutter = context.pageGutter;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: Breakpoints.formMaxWidth,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Slim top bar: Back on the start side.
                      SizedBox(
                        height: density.showLogo ? 48 : 40,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: canPop
                              ? AppIconButton(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  iconSize: 18,
                                  semanticLabel: MaterialLocalizations.of(
                                    context,
                                  ).backButtonTooltip,
                                  onPressed: () => context.pop(),
                                )
                              : null,
                        ),
                      ),
                      // Spare height is split above and below the group, so the form
                      // and the social row stay close together on tall phones.
                      const Spacer(),
                      if (density.showLogo) ...[
                        Center(child: VelloraLogo(height: density.logoHeight)),
                        SizedBox(height: density.gap),
                      ],
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: density.large
                              ? text.headlineMedium
                              : text.headlineSmall,
                        ),
                      ),
                      if (density.showSubtitle) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium,
                        ),
                      ],
                      ?banner,
                      SizedBox(height: density.gap + 2),
                      body(context, density),
                      // Room between the form and the social row grows only a little.
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 28),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      if (density.showSocial && orLabel != null) ...[
                        SizedBox(height: density.gap),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Text(orLabel!, style: text.bodySmall),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        SizedBox(height: density.gap),
                        SocialLoginButtons(height: density.socialHeight),
                      ],
                      SizedBox(height: density.gap - 4),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(switchPrompt, style: text.bodyMedium),
                          TextButton(
                            onPressed: onSwitch,
                            child: Text(switchLabel),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
