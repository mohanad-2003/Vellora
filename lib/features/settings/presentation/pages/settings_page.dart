import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/cache_cleaner.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/language_option_tile.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../../../../core/widgets/vellora_logo.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/user_session_cubit.dart';
import '../../../profile/presentation/widgets/delete_account_sheet.dart';
import '../cubit/notification_prefs_cubit.dart';

/// App settings: appearance, language, notifications, security, privacy, about.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    Widget section(IconData icon, String title, Widget child) => Padding(
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
              child: Row(
                children: [
                  Icon(icon, size: 18, color: context.colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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
              section(
                Icons.palette_outlined,
                l10n.appearance,
                const ThemePicker(),
              ),
              section(
                Icons.translate_rounded,
                l10n.language,
                const LanguagePicker(),
              ),
              section(
                Icons.notifications_none_rounded,
                l10n.notifications,
                BlocProvider(
                  create: (_) => sl<NotificationPrefsCubit>(),
                  child: const _NotificationPrefs(),
                ),
              ),
              section(
                Icons.lock_outline_rounded,
                l10n.security,
                _Group(
                  children: [
                    SettingsTile(
                      icon: Icons.shield_outlined,
                      iconColor: context.vellora.success,
                      title: l10n.signInSecurity,
                      onTap: () => context.pushNamed(RouteNames.nSecurity),
                    ),
                  ],
                ),
              ),
              section(
                Icons.visibility_outlined,
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
                Icons.storage_rounded,
                l10n.storage,
                const _Group(children: [_ClearCacheTile()]),
              ),
              // Deleting an account only makes sense while signed in.
              BlocBuilder<UserSessionCubit, SessionUser?>(
                builder: (context, user) => user == null
                    ? const SizedBox.shrink()
                    : section(
                        Icons.person_outline_rounded,
                        l10n.accountSection,
                        _Group(
                          children: [
                            SettingsTile(
                              icon: Icons.delete_outline_rounded,
                              title: l10n.deleteAccount,
                              subtitle: l10n.deleteAccountSub,
                              destructive: true,
                              onTap: () => showDeleteAccountSheet(
                                context,
                                onConfirm: (password) async {
                                  final result = await sl<AuthRepository>()
                                      .deleteAccount(password: password);
                                  return result.match<String?>(
                                    (Failure f) => f.l10nKey,
                                    (_) => null,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const _AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand mark, name, version and tagline closing the page.
class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          const VelloraMark(size: 64),
          const SizedBox(height: AppSpacing.md),
          Text(AppConstants.appName, style: context.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            l10n.versionLabel(AppConstants.appVersion),
            style: context.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.splashTagline,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

/// Empties the image cache and confirms with a snackbar.
class _ClearCacheTile extends StatefulWidget {
  const _ClearCacheTile();

  @override
  State<_ClearCacheTile> createState() => _ClearCacheTileState();
}

class _ClearCacheTileState extends State<_ClearCacheTile> {
  bool _busy = false;

  Future<void> _clear() async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await clearImageCache();
      if (!mounted) return;
      Haptics.light();
      AppSnackbar.success(context, l10n.cacheCleared);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsTile(
      icon: Icons.cleaning_services_outlined,
      iconColor: context.vellora.warning,
      title: l10n.clearCache,
      subtitle: l10n.clearCacheSub,
      onTap: _busy ? null : _clear,
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => FlatTileGroup(children: children);
}

class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final cubit = context.read<ThemeCubit>();
        Widget option(ThemeMode value, IconData icon, String label) => Expanded(
          child: _ThemeOption(
            mode: value,
            icon: icon,
            label: label,
            selected: mode == value,
            onTap: () => cubit.setThemeMode(value),
          ),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            option(
              ThemeMode.system,
              Icons.brightness_auto_outlined,
              l10n.systemTheme,
            ),
            const SizedBox(width: AppSpacing.sm),
            option(ThemeMode.light, Icons.light_mode_outlined, l10n.lightTheme),
            const SizedBox(width: AppSpacing.sm),
            option(ThemeMode.dark, Icons.dark_mode_outlined, l10n.darkTheme),
          ],
        );
      },
    );
  }
}

/// One appearance choice: a miniature screen preview over its label.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primary = colors.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: () {
          if (!selected) Haptics.selection();
          onTap();
        },
        borderRadius: AppRadius.rLg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surface,
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: selected ? primary : colors.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: AppRadius.rMd,
                child: SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: switch (mode) {
                    ThemeMode.light => const _MiniScreen(dark: false),
                    ThemeMode.dark => const _MiniScreen(dark: true),
                    ThemeMode.system => const Row(
                      children: [
                        Expanded(child: _MiniScreen(dark: false)),
                        Expanded(child: _MiniScreen(dark: true)),
                      ],
                    ),
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? Icons.check_circle_rounded : icon,
                    size: 16,
                    color: selected ? primary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: selected ? primary : colors.onSurface,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny stand-in for the app screen, drawn in light or dark colours.
class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF14161F) : const Color(0xFFF3F4F8);
    final card = dark ? const Color(0xFF222633) : Colors.white;
    final bar = dark ? const Color(0xFF3A4052) : const Color(0xFFD5D8E2);
    final accent = context.colors.primary;

    Widget line(double factor, Color color) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: factor,
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );

    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            line(0.5, bar),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    line(0.8, bar),
                    const SizedBox(height: 4),
                    line(0.55, bar),
                    const Spacer(),
                    line(0.4, accent),
                  ],
                ),
              ),
            ),
          ],
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
              iconColor: context.vellora.accent,
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
