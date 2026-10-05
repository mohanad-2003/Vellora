import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/localization/l10n_lookup.dart';
import 'package:vellora/core/responsive/responsive.dart';
import 'package:vellora/core/widgets/shimmer_widgets.dart';
import 'package:vellora/core/widgets/tab_page_header.dart';
import 'package:vellora/features/cart/presentation/bloc/cart_badge_cubit.dart';
import 'package:vellora/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:vellora/core/extensions/num_extensions.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/widgets/app_button.dart';
import 'package:vellora/core/widgets/custom_snackbar.dart';
import 'package:vellora/core/widgets/empty_state_widget.dart';
import 'package:vellora/core/widgets/error_state_widget.dart';
import 'package:vellora/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vellora/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:vellora/features/cart/presentation/widgets/free_shipping_progress.dart';
import 'package:vellora/features/cart/presentation/widgets/price_summary_card.dart';
import 'package:vellora/features/cart/presentation/widgets/promo_code_input.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CartBloc>()..add(const CartStarted()),
      // The cart tab stays alive in the shell, so listen for changes made
      // elsewhere (Home quick-add, product page) and reload when stale.
      child: BlocListener<CartBadgeCubit, int>(
        listener: (context, count) =>
            context.read<CartBloc>().add(CartSynced(count)),
        child: const _CartView(),
      ),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gutter = context.pageGutter;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          maxWidth: 720,
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              final count = state.summary?.itemCount ?? 0;
              final Widget body = switch (state.status) {
                CartStatus.loading => const ListSkeleton(),
                CartStatus.error => ErrorStateWidget(
                  message: state.failureKey != null
                      ? tr(context, state.failureKey!)
                      : l10n.somethingWentWrong,
                  onRetry: () =>
                      context.read<CartBloc>().add(const CartStarted()),
                ),
                CartStatus.empty => EmptyStateWidget(
                  title: l10n.emptyCartTitle,
                  message: l10n.emptyCartBody,
                  icon: Icons.shopping_bag_outlined,
                  actionLabel: l10n.startShopping,
                  onAction: () => context.goNamed(RouteNames.nExplore),
                ),
                CartStatus.loaded => _LoadedCart(state: state),
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabPageHeader(
                    title: l10n.myCart,
                    subtitle: l10n.cartSubtitle,
                    count: state.status == CartStatus.loaded
                        ? l10n.cartItemsCount(count)
                        : null,
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      AppSpacing.lg,
                      gutter,
                      AppSpacing.md,
                    ),
                  ),
                  Expanded(child: body),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadedCart extends StatelessWidget {
  const _LoadedCart({required this.state});

  final CartState state;

  void _remove(BuildContext context, CartItemEntity item) {
    final bloc = context.read<CartBloc>();
    final l10n = context.l10n;
    bloc.add(CartItemRemoved(item.id));
    AppSnackbar.show(
      context,
      message: l10n.itemRemoved,
      actionLabel: l10n.undo,
      onAction: () => bloc.add(CartItemRestored(item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CartBloc>();
    final summary = state.summary;
    final gutter = context.pageGutter;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.sm,
              gutter,
              AppSpacing.xl,
            ),
            children: [
              if (summary != null) ...[
                FreeShippingProgress(subtotal: summary.subtotal),
                const SizedBox(height: AppSpacing.lg),
              ],
              for (final item in state.items) ...[
                CartItemTile(
                  item: item,
                  onTap: () => context.pushNamed(
                    RouteNames.nProduct,
                    pathParameters: {'id': item.productId},
                  ),
                  onQuantityChanged: (q) =>
                      bloc.add(CartQuantityChanged(item.id, q)),
                  onRemoved: () => _remove(context, item),
                ),
                Divider(height: 1, color: context.colors.outlineVariant),
              ],
              const SizedBox(height: AppSpacing.md),
              PromoCodeInput(
                applied: state.promo,
                isApplying: state.applyingPromo,
                hasError: state.promoError,
                onApply: (code) => bloc.add(CartPromoApplied(code)),
                onRemove: () => bloc.add(const CartPromoRemoved()),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (summary != null) PriceSummaryCard(summary: summary),
            ],
          ),
        ),
        _CheckoutBar(
          total: summary?.total ?? 0,
          onCheckout: () =>
              context.pushNamed(RouteNames.nCheckout, extra: state.promo),
        ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total, required this.onCheckout});

  final double total;
  final VoidCallback onCheckout;

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
                  label: l10n.checkout,
                  trailingIcon: Icons.arrow_forward_rounded,
                  haptic: true,
                  onPressed: onCheckout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
