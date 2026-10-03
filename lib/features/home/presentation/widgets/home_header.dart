import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/asset_paths.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/count_badge.dart';
import '../../../auth/presentation/bloc/user_session_cubit.dart';
import '../../../cart/presentation/bloc/cart_badge_cubit.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';

/// Time-of-day buckets for the greeting.
enum DayPeriod { morning, afternoon, evening }

DayPeriod dayPeriodFor(int hour) {
  if (hour >= 5 && hour < 12) return DayPeriod.morning;
  if (hour >= 12 && hour < 17) return DayPeriod.afternoon;
  return DayPeriod.evening;
}

/// Home top bar: avatar, time-aware greeting (with the user's first name when
/// signed in), notifications and cart. Theme and language controls live in
/// Settings, not here.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.now});

  /// Injectable clock for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final period = dayPeriodFor((now ?? DateTime.now()).hour);
    final greeting = switch (period) {
      DayPeriod.morning => l10n.greetingMorning,
      DayPeriod.afternoon => l10n.greetingAfternoon,
      DayPeriod.evening => l10n.greetingEvening,
    };

    return BlocBuilder<UserSessionCubit, SessionUser?>(
      builder: (context, user) {
        return Row(
          children: [
            _Avatar(user: user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.firstName ?? l10n.guest,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: Icons.notifications_none_rounded,
              semanticLabel: l10n.notifications,
              onPressed: () => context.pushNamed(RouteNames.nNotifications),
              badge: context.watch<UnreadNotificationsCubit>().state > 0
                  ? const _Dot()
                  : null,
            ),
            const SizedBox(width: 4),
            BlocBuilder<CartBadgeCubit, int>(
              builder: (context, count) => AppIconButton(
                icon: Icons.shopping_bag_outlined,
                semanticLabel: l10n.cart,
                onPressed: () => context.goNamed(RouteNames.nCart),
                badge: count > 0 ? CountBadge(count: count) : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final SessionUser? user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final avatarUrl = user?.avatarUrl;
    final initial = user?.name.trim().isNotEmpty ?? false
        ? user!.name.trim().characters.first.toUpperCase()
        : null;

    Widget child;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      child = Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(colors, initial),
      );
    } else {
      child = _fallback(colors, initial);
    }

    return Semantics(
      button: true,
      label: context.l10n.profile,
      excludeSemantics: true,
      onTap: () => context.goNamed(RouteNames.nProfile),
      child: GestureDetector(
        onTap: () => context.goNamed(RouteNames.nProfile),
        child: ClipOval(child: SizedBox.square(dimension: 44, child: child)),
      ),
    );
  }

  Widget _fallback(ColorScheme colors, String? initial) {
    if (initial == null) {
      return Image.asset(
        AssetPaths.avatarDefault,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(
          color: colors.primaryContainer,
          child: Icon(Icons.person_rounded, color: colors.primary),
        ),
      );
    }
    return ColoredBox(
      color: colors.primary,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: colors.onPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: context.vellora.accent,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.surface, width: 1.5),
      ),
    );
  }
}
