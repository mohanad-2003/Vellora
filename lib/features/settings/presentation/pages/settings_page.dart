import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/language_option_tile.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../cubit/notification_prefs_cubit.dart';

/// App settings: appearance, language, notifications, security, privacy, about.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    Widget section(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  right: AppSpacing.xs,
                  bottom: AppSpacing.md,
                ),
                child: Semantics(
                  header: true,
                  child: Text(title, style: context.textTheme.titleMedium),
                ),
              ),
              child,
            ],
          ),
        );

    return Scaffold(
      appBar: AppBarWidget(title: l10n.settings),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 720,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.pageGutter,
              AppSpacing.md,
              context.pageGutter,
              AppSpacing.xxl,
            ),
            children: [
              section(l10n.appearance, const ThemePicker()),
              section(l10n.language, const LanguagePicker()),
              section(
                l10n.notifications,
                BlocProvider(
                  create: (_) => sl<NotificationPrefsCubit>(),
                  child: const _NotificationPrefs(),
                ),
              ),
              section(
                l10n.security,
                _Group(
                  children: [
                    SettingsTile(
                      icon: Icons.shield_outlined,
                      title: l10n.signInSecurity,
                      onTap: () => context.pushNamed(RouteNames.nSecurity),
                    ),
                  ],
                ),
              ),
              section(
                l10n.privacy,
                _Group(
                  children: [
                    SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: l10n.termsPrivacyTitle,
                      onTap: () => context.pushNamed(RouteNames.nTermsPrivacy),
                    ),
                  ],
                ),
              ),
              section(
                l10n.about,
                _Group(
                  children: [
                    SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: AppConstants.appName,
                      subtitle: l10n.versionLabel(AppConstants.appVersion),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) => SizedBox(
        width: double.infinity,
        child: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ThemeMode.system,
              icon: const Icon(Icons.brightness_auto_outlined),
              label: Text(l10n.systemTheme),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: const Icon(Icons.light_mode_outlined),
              label: Text(l10n.lightTheme),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: const Icon(Icons.dark_mode_outlined),
              label: Text(l10n.darkTheme),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (s) =>
              context.read<ThemeCubit>().setThemeMode(s.first),
        ),
      ),
    );
  }
}

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        final cubit = context.read<LocaleCubit>();
        final isArabic = locale.languageCode == 'ar';
        return Column(
          children: [
            LanguageOptionTile(
              title: 'English',
              subtitle: l10n.languageEnglishHint,
              glyph: 'EN',
              selected: !isArabic,
              onTap: () => cubit.setLocale(const Locale('en')),
            ),
            const SizedBox(height: AppSpacing.sm),
            LanguageOptionTile(
              title: 'العربية',
              subtitle: l10n.languageArabicHint,
              glyph: 'ع',
              selected: isArabic,
              onTap: () => cubit.setLocale(const Locale('ar')),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationPrefs extends StatelessWidget {
  const _NotificationPrefs();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<NotificationPrefsCubit, NotificationPrefs>(
      builder: (context, prefs) {
        final cubit = context.read<NotificationPrefsCubit>();
        return _Group(
          children: [
            SettingsTile(
              icon: Icons.local_shipping_outlined,
              title: l10n.notifPrefOrders,
              subtitle: l10n.notifPrefOrdersSub,
              trailing: Switch(
                value: prefs.orderUpdates,
                onChanged: cubit.setOrderUpdates,
              ),
            ),
            SettingsTile(
              icon: Icons.local_offer_outlined,
              title: l10n.notifPrefPromos,
              subtitle: l10n.notifPrefPromosSub,
              trailing: Switch(
                value: prefs.promotions,
                onChanged: cubit.setPromotions,
              ),
            ),
          ],
        );
      },
    );
  }
}
