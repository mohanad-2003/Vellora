import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../domain/notification_entity.dart';
import '../cubit/notifications_cubit.dart';
import '../../../../core/widgets/failure_state_view.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsCubit>()..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBarWidget(
            title: l10n.notifications,
            actions: [
              if (state.hasUnread)
                TextButton(
                  onPressed: () =>
                      context.read<NotificationsCubit>().markAllRead(),
                  child: Text(l10n.markAllRead),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: switch (state.status) {
              NotificationsStatus.loading => const ListSkeleton(thumb: 48),
              NotificationsStatus.error => FailureStateView(
                failureKey: state.failureKey,
                onRetry: () => context.read<NotificationsCubit>().load(),
              ),
              NotificationsStatus.loaded =>
                state.items.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.notifications_none_rounded,
                        title: l10n.noNotificationsTitle,
                        message: l10n.noNotificationsBody,
                      )
                    : _Grouped(items: state.items),
            },
          ),
        );
      },
    );
  }
}

enum _Group { today, yesterday, earlier }

class _Grouped extends StatelessWidget {
  const _Grouped({required this.items});

  final List<NotificationEntity> items;

  _Group _groupOf(DateTime t, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return _Group.today;
    if (diff == 1) return _Group.yesterday;
    return _Group.earlier;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final sorted = [...items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final children = <Widget>[];
    for (final group in _Group.values) {
      final groupItems = sorted
          .where((n) => _groupOf(n.createdAt, now) == group)
          .toList();
      if (groupItems.isEmpty) continue;
      final title = switch (group) {
        _Group.today => l10n.today,
        _Group.yesterday => l10n.yesterday,
        _Group.earlier => l10n.earlier,
      };
      children.add(
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.pageGutter,
            AppSpacing.xl,
            context.pageGutter,
            AppSpacing.xs,
          ),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < groupItems.length; i++) {
        children.add(_NotificationTile(item: groupItems[i], now: now));
        if (i < groupItems.length - 1) {
          children.add(
            Divider(
              height: 1,
              indent: context.pageGutter,
              endIndent: context.pageGutter,
              color: context.colors.outlineVariant,
            ),
          );
        }
      }
    }

    return ResponsiveCenter(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: children,
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.now});

  final NotificationEntity item;
  final DateTime now;

  IconData get _icon => switch (item.kind) {
    NotificationKind.order => Icons.local_shipping_outlined,
    NotificationKind.promo => Icons.local_offer_outlined,
    NotificationKind.system => Icons.info_outline_rounded,
  };

  Color _tone(BuildContext context) => switch (item.kind) {
    NotificationKind.order => context.colors.primary,
    NotificationKind.promo => context.vellora.accent,
    NotificationKind.system => const Color(0xFF0E9F8F),
  };

  String _time(BuildContext context) {
    final l10n = context.l10n;
    final diff = now.difference(item.createdAt);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMMd(locale).format(item.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    final title = item.resolveTitle((k) => tr(context, k));
    final body = item.resolveBody((k) => tr(context, k));

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => context.read<NotificationsCubit>().dismiss(item.id),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        color: colors.error,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Semantics(
        label:
            '${item.isUnread ? '${context.l10n.unread}, ' : ''}$title. $body',
        excludeSemantics: true,
        // Same colour as the screen; unread shows as a bold title and a dot.
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            // Opens the order it is about, if any, and marks it read.
            onTap: () {
              context.read<NotificationsCubit>().markRead(item.id);
              final orderId = item.orderId;
              if (orderId != null) {
                context.pushNamed(
                  RouteNames.nOrderDetails,
                  pathParameters: {'id': orderId},
                );
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.pageGutter,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _tone(context).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, size: 22, color: _tone(context)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: text.titleSmall?.copyWith(
                                  fontWeight: item.isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (item.isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsetsDirectional.only(
                                  start: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: context.vellora.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(body, style: text.bodySmall),
                        const SizedBox(height: 6),
                        Text(_time(context), style: text.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
