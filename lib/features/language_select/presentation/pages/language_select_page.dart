import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/responsive/responsive.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/theme/app_colors.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/utils/haptics.dart';
import 'package:vellora/core/widgets/vellora_logo.dart';
import 'package:vellora/features/language_select/presentation/cubit/language_select_cubit.dart';

class LanguageSelectPage extends StatelessWidget {
  const LanguageSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LanguageSelectCubit>(),
      child: const _LanguageSelectView(),
    );
  }
}

/// First-launch language gate. A brand moment like onboarding: always deep
/// navy with gold accents, whichever theme the device is in. The choice is
/// applied live, so the screen itself flips to RTL as soon as Arabic is tapped.
class _LanguageSelectView extends StatelessWidget {
  const _LanguageSelectView();

  Future<void> _continue(BuildContext context) async {
    await context.read<LanguageSelectCubit>().confirm();
    if (context.mounted) context.goNamed(RouteNames.nOnboarding);
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
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.75),
              radius: 1.1,
              colors: [Color(0xFF2A1B7A), kBrandNavy],
            ),
          ),
          child: SafeArea(
            child: BlocBuilder<LanguageSelectCubit, Locale>(
              builder: (context, locale) {
                final cubit = context.read<LanguageSelectCubit>();
                final isArabic = locale.languageCode == 'ar';
                return ResponsiveCenter(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            gutter,
                            AppSpacing.x4l,
                            gutter,
                            AppSpacing.lg,
                          ),
                          child: Column(
                            children: [
                              const VelloraLogo(height: 52, onDark: true),
                              const SizedBox(height: AppSpacing.huge),
                              Semantics(
                                header: true,
                                child: Text(
                                  l10n.selectLanguage,
                                  textAlign: TextAlign.center,
                                  style: text.displaySmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              // Always bilingual so nobody is stranded on a
                              // language they cannot read.
                              Text(
                                isArabic ? 'Choose your language' : 'اختر لغتك',
                                textAlign: TextAlign.center,
                                style: text.titleMedium?.copyWith(
                                  color: kBrandGold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                l10n.selectLanguageSubtitle,
                                textAlign: TextAlign.center,
                                style: text.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxxl),
                              _LanguageCard(
                                title: 'English',
                                subtitle: l10n.languageEnglishHint,
                                glyph: 'EN',
                                selected: !isArabic,
                                onTap: () => cubit.select(const Locale('en')),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _LanguageCard(
                                title: 'العربية',
                                subtitle: l10n.languageArabicHint,
                                glyph: 'ع',
                                selected: isArabic,
                                onTap: () => cubit.select(const Locale('ar')),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          AppSpacing.sm,
                          gutter,
                          AppSpacing.xl,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Haptics.selection();
                              _continue(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBrandGold,
                              foregroundColor: const Color(0xFF14102E),
                              minimumSize: const Size(0, 56),
                            ),
                            iconAlignment: IconAlignment.end,
                            // Directional arrow mirrors in RTL.
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                            label: Text(l10n.continueLabel),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
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
    final text = context.textTheme;
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? kBrandGold.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: selected
                  ? kBrandGold
                  : Colors.white.withValues(alpha: 0.16),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? kBrandGold
                      : Colors.white.withValues(alpha: 0.10),
                  borderRadius: AppRadius.rMd,
                ),
                child: Text(
                  glyph,
                  style: text.titleMedium?.copyWith(
                    color: selected ? const Color(0xFF14102E) : Colors.white,
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
                      style: text.titleLarge?.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? kBrandGold : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? kBrandGold
                        : Colors.white.withValues(alpha: 0.4),
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Color(0xFF14102E),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
