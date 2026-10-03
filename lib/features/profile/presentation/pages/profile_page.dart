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
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_avatar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileCubit>()..loadUser(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status &&
              curr.status == ProfileStatus.loggedOut,
          listener: (context, state) => context.go(RouteNames.login),
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state.status == ProfileStatus.initial ||
                  state.status == ProfileStatus.loading) {
                return const ListSkeleton(itemCount: 4, thumb: 64);
              }
              return ResponsiveCenter(
                maxWidth: 720,
                child: _ProfileContent(user: state.user),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user});

  final UserEntity? user;

  Future<void> _openEditProfile(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final changed = await context.pushNamed<bool>(
      RouteNames.nEditProfile,
      extra: user,
    );
    if (changed == true) cubit.loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final signedIn = user != null;

    Widget group(List<Widget> children) => _TileGroup(children: children);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: context.textTheme.titleSmall),
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.pageGutter,
        AppSpacing.lg,
        context.pageGutter,
        AppSpacing.xxl,
      ),
      children: [
        _ProfileHeader(
          user: user,
          onEdit: signedIn ? () => _openEditProfile(context) : null,
        ),
        label(l10n.myShopping),
        group([
          SettingsTile(
            icon: Icons.receipt_long_outlined,
            title: l10n.myOrders,
            onTap: () => context.pushNamed(RouteNames.nOrders),
          ),
          SettingsTile(
            icon: Icons.favorite_border_rounded,
            title: l10n.wishlist,
            onTap: () => context.goNamed(RouteNames.nWishlist),
          ),
          SettingsTile(
            icon: Icons.location_on_outlined,
            title: l10n.savedAddresses,
            onTap: () => context.pushNamed(RouteNames.nSavedAddresses),
          ),
          SettingsTile(
            icon: Icons.credit_card_rounded,
            title: l10n.paymentMethods,
            onTap: () => context.pushNamed(RouteNames.nPaymentMethods),
          ),
        ]),
        label(l10n.account),
        group([
          SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: l10n.notifications,
            onTap: () => context.pushNamed(RouteNames.nNotifications),
          ),
          SettingsTile(
            icon: Icons.shield_outlined,
            title: l10n.security,
            onTap: () => context.pushNamed(RouteNames.nSecurity),
          ),
          SettingsTile(
            icon: Icons.settings_outlined,
            title: l10n.settings,
            onTap: () => context.pushNamed(RouteNames.nSettings),
          ),
        ]),
        label(l10n.preferences),
        group([
          BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) => SettingsTile(
              icon: Icons.translate_rounded,
              title: l10n.language,
              trailing: Text(
                locale.languageCode == 'ar' ? 'العربية' : 'English',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.primary,
                ),
              ),
              onTap: () => AppBottomSheet.show(
                context,
                title: l10n.language,
                child: const LanguagePicker(),
              ),
            ),
          ),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) => SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: l10n.theme,
              trailing: Text(
                switch (mode) {
                  ThemeMode.light => l10n.lightTheme,
                  ThemeMode.dark => l10n.darkTheme,
                  ThemeMode.system => l10n.systemTheme,
                },
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.primary,
                ),
              ),
              onTap: () => AppBottomSheet.show(
                context,
                title: l10n.theme,
                child: const ThemePicker(),
              ),
            ),
          ),
        ]),
        label(l10n.support),
        group([
          SettingsTile(
            icon: Icons.help_outline_rounded,
            title: l10n.helpSupport,
            onTap: () => _showHelp(context),
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),
        if (signedIn)
          group([
            SettingsTile(
              icon: Icons.logout_rounded,
              title: l10n.logout,
              destructive: true,
              onTap: () => _confirmLogout(context),
            ),
          ]),
      ],
    );
  }

  void _showHelp(BuildContext context) {
    final l10n = context.l10n;
    AppBottomSheet.show(
      context,
      title: l10n.helpSupport,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.helpBody, style: context.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.mail_outline_rounded, color: context.colors.primary),
              const SizedBox(width: AppSpacing.md),
              // Email addresses read left-to-right in every locale.
              Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(
                  AppConstants.supportEmail,
                  style: context.textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final l10n = context.l10n;
    AppBottomSheet.show(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.logoutConfirmTitle,
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.logoutConfirmBody,
            style: context.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: l10n.logout,
            icon: Icons.logout_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              cubit.logout();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onEdit});

  final UserEntity? user;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final name = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name
        : l10n.guest;
    final email = (user?.email.trim().isNotEmpty ?? false)
        ? user!.email
        : l10n.guestPrompt;

    return Row(
      children: [
        ProfileAvatar(name: name, avatarUrl: user?.avatarUrl, size: 72),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  name,
                  style: text.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                email,
                style: text.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (onEdit != null)
                AppButton(
                  label: l10n.editProfile,
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.outline,
                  expand: false,
                  onPressed: onEdit,
                )
              else
                AppButton(
                  label: l10n.login,
                  expand: false,
                  onPressed: () => context.goNamed(RouteNames.nLogin),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.children});

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
            if (i > 0)
              Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
                color: context.colors.outlineVariant,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
