import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../domain/order_entity.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/order_widgets.dart';
import '../../../../core/widgets/failure_state_view.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrdersCubit>()..load(),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  /// `null` = all.
  static const _tabs = <OrderStatus?>[
    null,
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  String _label(BuildContext context, OrderStatus? s) =>
      s == null ? context.l10n.ordersAll : orderStatusLabel(context, s);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBarWidget(
          title: l10n.myOrders,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: context.colors.outlineVariant,
            tabs: [for (final t in _tabs) Tab(text: _label(context, t))],
          ),
        ),
        body: SafeArea(
          top: false,
          child: BlocBuilder<OrdersCubit, OrdersState>(
            builder: (context, state) {
              switch (state.status) {
                case OrdersStatus.loading:
                  return const ListSkeleton(thumb: 64);
                case OrdersStatus.error:
                  return FailureStateView(
                    failureKey: state.failureKey,
                    onRetry: () => context.read<OrdersCubit>().load(),
                  );
                case OrdersStatus.loaded:
                  return TabBarView(
                    children: [
                      for (final t in _tabs)
                        _OrdersList(orders: state.withStatus(t)),
                    ],
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders});

  final List<OrderEntity> orders;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (orders.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        title: l10n.noOrdersTitle,
        message: l10n.noOrdersBody,
        actionLabel: l10n.startShopping,
        onAction: () => context.goNamed(RouteNames.nExplore),
      );
    }
    // Newest first, with a heading whenever the month changes.
    final rows = <Object>[];
    DateTime? month;
    for (final order in orders) {
      final m = DateTime(order.createdAt.year, order.createdAt.month);
      if (m != month) {
        rows.add(m);
        month = m;
      }
      rows.add(order);
    }

    Future<void> open(OrderEntity order) async {
      final cubit = context.read<OrdersCubit>();
      await context.pushNamed(
        RouteNames.nOrderDetails,
        pathParameters: {'id': order.id},
      );
      // The order may have been cancelled over there.
      await cubit.refresh();
    }

    return ResponsiveCenter(
      maxWidth: 720,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final row = rows[i];
          if (row is DateTime) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                context.pageGutter,
                AppSpacing.xl,
                context.pageGutter,
                AppSpacing.xs,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  formatOrderMonth(context, row),
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          final order = row as OrderEntity;
          // A divider under each order, except the last one of its month.
          final isLastOfMonth = i == rows.length - 1 || rows[i + 1] is DateTime;
          return Column(
            children: [
              OrderCard(order: order, onTap: () => open(order)),
              if (!isLastOfMonth)
                Divider(
                  height: 1,
                  indent: context.pageGutter,
                  endIndent: context.pageGutter,
                  color: context.colors.outlineVariant,
                ),
            ],
          );
        },
      ),
    );
  }
}
