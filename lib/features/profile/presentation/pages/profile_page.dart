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
import '../../../../core/widgets/favorites_listener.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../cart/presentation/bloc/cart_badge_cubit.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_avatar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileCubit>()..loadUser(),
      child: Builder(
        builder: (context) => FavoritesListener(
          onChanged: () => context.read<ProfileCubit>().refreshWishlist(),
          child: const _ProfileView(),
        ),
      ),
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
                child: _ProfileContent(state: state),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.state});

  final ProfileState state;

  UserEntity? get user => state.user;

  Future<void> _openEditProfile(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final changed = await context.pushNamed<bool>(
      RouteNames.nEditProfile,
      extra: user,
    );
    if (changed == true) cubit.loadUser();
  }

  Future<void> _openOrders(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    await context.pushNamed(RouteNames.nOrders);
    cubit.refreshOrders();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final signedIn = user != null;

    Widget group(List<Widget> children) => _TileGroup(children: children);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xxl,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
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
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Semantics(
            header: true,
            child: Text(l10n.profile, style: context.textTheme.displaySmall),
          ),
        ),
        _ProfileHeader(
          user: user,
          onEdit: signedIn ? () => _openEditProfile(context) : null,
          stats: _ProfileStats(
            ordersCount: state.ordersCount,
            wishlistCount: state.wishlistCount,
            onOrders: () => _openOrders(context),
          ),
        ),
        if (signedIn && state.activeOrdersCount > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          _ActiveOrdersBanner(
            count: state.activeOrdersCount,
            onTap: () => _openOrders(context),
          ),
        ],
        label(l10n.quickActions),
        _QuickActions(
          actions: [
            _QuickAction(
              icon: Icons.receipt_long_outlined,
              label: l10n.ordersLabel,
              color: context.colors.primary,
              onTap: () => _openOrders(context),
            ),
            _QuickAction(
              icon: Icons.location_on_outlined,
              label: l10n.addresses,
              color: const Color(0xFF0E9F8F),
              onTap: () => context.pushNamed(RouteNames.nSavedAddresses),
            ),
            _QuickAction(
              icon: Icons.credit_card_rounded,
              label: l10n.payments,
              color: const Color(0xFFE08A1E),
              onTap: () => context.pushNamed(RouteNames.nPaymentMethods),
            ),
            _QuickAction(
              icon: Icons.notifications_none_rounded,
              label: l10n.alerts,
              color: context.vellora.accent,
              onTap: () => context.pushNamed(RouteNames.nNotifications),
            ),
          ],
        ),
        label(l10n.account),
        group([
          SettingsTile(
            icon: Icons.favorite_border_rounded,
            title: l10n.wishlist,
            onTap: () => context.goNamed(RouteNames.nWishlist),
          ),
          SettingsTile(
            icon: Icons.shield_outlined,
            title: l10n.security,
            onTap: () => context.pushNamed(RouteNames.nSecurity),
          ),
        ]),
        label(l10n.preferences),
        group([
          BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) => SettingsTile(
              icon: Icons.translate_rounded,
              title: l10n.language,
              trailing: _TrailingValue(
                locale.languageCode == 'ar' ? 'العربية' : 'English',
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
              trailing: _TrailingValue(switch (mode) {
                ThemeMode.light => l10n.lightTheme,
                ThemeMode.dark => l10n.darkTheme,
                ThemeMode.system => l10n.systemTheme,
              }),
              onTap: () => AppBottomSheet.show(
                context,
                title: l10n.theme,
                child: const ThemePicker(),
              ),
            ),
          ),
          SettingsTile(
            icon: Icons.settings_outlined,
            title: l10n.settings,
            onTap: () => context.pushNamed(RouteNames.nSettings),
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
        if (signedIn) ...[
          const SizedBox(height: AppSpacing.xxl),
          group([
            SettingsTile(
              icon: Icons.logout_rounded,
              title: l10n.logout,
              destructive: true,
              onTap: () => _confirmLogout(context),
            ),
          ]),
        ],
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: Text(l10n.madeWithCare, style: context.textTheme.labelMedium),
        ),
        const SizedBox(height: 2),
        Center(
          child: Text(
            l10n.versionLabel(AppConstants.appVersion),
            style: context.textTheme.labelSmall,
          ),
        ),
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

/// Gradient identity card: avatar, name, email, an edit (or sign-in) action
/// and the stats row.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.onEdit,
    required this.stats,
  });

  final UserEntity? user;
  final VoidCallback? onEdit;
  final Widget stats;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B1F5E), Color(0xFF4553D8), Color(0xFF7B5CE0)],
    stops: [0, 0.65, 1],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final signedIn = user != null;
    final name = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name
        : l10n.guestCardTitle;
    final email = (user?.email.trim().isNotEmpty ?? false)
        ? user!.email
        : l10n.guestCardBody;
    const onCard = Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: AppRadius.rXl,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4553D8).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Soft decorative circles.
          PositionedDirectional(
            top: -40,
            end: -30,
            child: _Glow(size: 150, opacity: 0.10),
          ),
          PositionedDirectional(
            bottom: -60,
            start: -40,
            child: _Glow(size: 170, opacity: 0.07),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: signedIn
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: onCard.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: signedIn
                          ? ProfileAvatar(
                              name: name,
                              avatarUrl: user?.avatarUrl,
                              size: 64,
                            )
                          : CircleAvatar(
                              radius: 32,
                              backgroundColor: onCard.withValues(alpha: 0.18),
                              child: const Icon(
                                Icons.person_rounded,
                                color: onCard,
                                size: 32,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: text.titleLarge?.copyWith(
                              color: onCard,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: text.bodySmall?.copyWith(
                              color: onCard.withValues(alpha: 0.8),
                            ),
                            maxLines: signedIn ? 1 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (onEdit != null)
                      IconButton(
                        onPressed: onEdit,
                        tooltip: l10n.editProfile,
                        style: IconButton.styleFrom(
                          backgroundColor: onCard.withValues(alpha: 0.16),
                          foregroundColor: onCard,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                  ],
                ),
                if (!signedIn) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => context.goNamed(RouteNames.nLogin),
                          style: FilledButton.styleFrom(
                            backgroundColor: onCard,
                            foregroundColor: const Color(0xFF1B1F5E),
                            minimumSize: const Size.fromHeight(46),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.rMd,
                            ),
                          ),
                          child: Text(
                            l10n.login,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              context.goNamed(RouteNames.nRegister),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: onCard,
                            side: BorderSide(
                              color: onCard.withValues(alpha: 0.6),
                            ),
                            minimumSize: const Size.fromHeight(46),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.rMd,
                            ),
                          ),
                          child: Text(
                            l10n.register,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                stats,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

/// Orders · Wishlist · Cart counters on a frosted panel. Each one opens its
/// screen.
class _ProfileStats extends StatelessWidget {
  const _ProfileStats({
    required this.ordersCount,
    required this.wishlistCount,
    required this.onOrders,
  });

  final int? ordersCount;
  final int wishlistCount;
  final VoidCallback onOrders;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final divider = Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.25),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AppRadius.rLg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            _Stat(
              value: ordersCount?.toString() ?? '–',
              label: l10n.ordersLabel,
              onTap: onOrders,
            ),
            divider,
            _Stat(
              value: '$wishlistCount',
              label: l10n.wishlist,
              onTap: () => context.goNamed(RouteNames.nWishlist),
            ),
            divider,
            // Read the app-wide badge directly so the page also works where
            // no provider sits above it.
            BlocBuilder<CartBadgeCubit, int>(
              bloc: sl<CartBadgeCubit>(),
              builder: (context, count) => _Stat(
                value: '$count',
                label: l10n.cart,
                onTap: () => context.goNamed(RouteNames.nCart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.onTap});

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Expanded(
      child: Semantics(
        button: true,
        label: '$label: $value',
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  style: text.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
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

class _ActiveOrdersBanner extends StatelessWidget {
  const _ActiveOrdersBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final success = context.vellora.success;
    return Material(
      color: success.withValues(alpha: context.isDark ? 0.16 : 0.1),
      borderRadius: AppRadius.rLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: success.withValues(alpha: 0.18),
                  borderRadius: AppRadius.rMd,
                ),
                child: Icon(Icons.local_shipping_outlined, color: success),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.activeOrders(count),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                    Text(
                      l10n.activeOrdersBody,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: success),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

/// Four shortcut tiles in one row.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final a in actions)
            Expanded(
              child: Semantics(
                button: true,
                label: a.label,
                excludeSemantics: true,
                onTap: a.onTap,
                child: InkWell(
                  onTap: a.onTap,
                  borderRadius: AppRadius.rMd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: 2,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: a.color.withValues(alpha: 0.12),
                            borderRadius: AppRadius.rLg,
                          ),
                          child: Icon(a.icon, color: a.color, size: 22),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          a.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrailingValue extends StatelessWidget {
  const _TrailingValue(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          size: 22,
          color: context.colors.outline,
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
