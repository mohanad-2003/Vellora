import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../cart/domain/entities/promo_code_entity.dart';
import '../../../cart/presentation/widgets/price_summary_card.dart';
import '../cubit/checkout_cubit.dart';
import '../widgets/checkout_tiles.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key, this.promo});

  /// Discount carried over from the cart, if one was applied.
  final PromoCodeEntity? promo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CheckoutCubit>()..load(promo),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBarWidget(title: l10n.checkoutTitle),
      body: BlocConsumer<CheckoutCubit, CheckoutState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == CheckoutStatus.success && state.order != null) {
            Haptics.success();
            context.pushReplacementNamed(
              RouteNames.nOrderSuccess,
              extra: state.order,
            );
          } else if (state.status == CheckoutStatus.ready &&
              state.failureKey != null) {
            // Placing the order failed; the cart is untouched.
            AppSnackbar.error(context, tr(context, state.failureKey!));
          }
        },
        builder: (context, state) {
          return switch (state.status) {
            CheckoutStatus.loading => const ListSkeleton(),
            CheckoutStatus.error => ErrorStateWidget(
                message: state.failureKey != null
                    ? tr(context, state.failureKey!)
                    : l10n.somethingWentWrong,
                onRetry: () => context.read<CheckoutCubit>().load(null),
              ),
            _ => _CheckoutBody(state: state),
          };
        },
      ),
    );
  }
}

class _CheckoutBody extends StatelessWidget {
  const _CheckoutBody({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();
    final address = state.selectedAddress;
    final isPlacing = state.status == CheckoutStatus.placing;
    final gutter = context.pageGutter;

    Widget section(int step, String title, Widget child, {Widget? action}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$step',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: context.textTheme.titleLarge),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ResponsiveCenter(
            maxWidth: 720,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.lg,
                gutter,
                AppSpacing.lg,
              ),
              children: [
                section(
                  1,
                  l10n.shippingAddress,
                  address == null
                      ? const SizedBox.shrink()
                      : AddressTile(address: address, selected: false),
                  action: state.addresses.length > 1
                      ? TextButton(
                          onPressed: () => _pickAddress(context, cubit),
                          child: Text(l10n.change),
                        )
                      : null,
                ),
                section(
                  2,
                  l10n.deliveryMethod,
                  Column(
                    children: [
                      for (final d in state.deliveryOptions)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: DeliveryTile(
                            option: d,
                            selected: d.id == state.selectedDeliveryId,
                            shippingFee: cubit.shippingFor(d),
                            onTap: () => cubit.selectDelivery(d.id),
                          ),
                        ),
                    ],
                  ),
                ),
                section(
                  3,
                  l10n.paymentMethod,
                  Column(
                    children: [
                      for (final m in state.paymentMethods)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: PaymentTile(
                            method: m,
                            selected: m.id == state.selectedPaymentId,
                            onTap: () => cubit.selectPayment(m.id),
                          ),
                        ),
                    ],
                  ),
                ),
                section(
                  4,
                  l10n.orderSummary,
                  Column(
                    children: [
                      for (final item in state.items)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: OrderItemRow(item: item),
                        ),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      if (state.summary != null)
                        PriceSummaryCard(summary: state.summary!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _PlaceOrderBar(
          total: state.summary?.total ?? 0,
          isPlacing: isPlacing,
          onPlaceOrder: cubit.placeOrder,
        ),
      ],
    );
  }

  void _pickAddress(BuildContext context, CheckoutCubit cubit) {
    AppBottomSheet.show(
      context,
      title: context.l10n.shippingAddress,
      child: Column(
        children: [
          for (final a in state.addresses)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AddressTile(
                address: a,
                showRadio: true,
                selected: a.id == state.selectedAddressId,
                onTap: () {
                  cubit.selectAddress(a.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({
    required this.total,
    required this.isPlacing,
    required this.onPlaceOrder,
  });

  final double total;
  final bool isPlacing;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.total, style: text.bodySmall),
                  Text(
                    total.toPrice(),
                    style: text.titleLarge?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: AppButton(
                  label: l10n.placeOrder,
                  icon: Icons.lock_outline_rounded,
                  isLoading: isPlacing,
                  haptic: true,
                  onPressed: onPlaceOrder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
