import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../orders/domain/order_entity.dart';

/// Shown after an order is placed: animated confirmation, order number and
/// the next steps (track the order, keep shopping).
class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key, required this.order});

  final OrderEntity order;

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.elasticOut),
  );
  late final Animation<double> _content = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 1, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _home() => context.goNamed(RouteNames.nHome);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final colors = context.colors;
    final success = context.vellora.success;
    final order = widget.order;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && !_controller.isCompleted) _controller.value = 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: context.pageGutter),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: ResponsiveCenter(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          width: 132,
                          height: 132,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: success.withValues(alpha: 0.12),
                          ),
                          child: Container(
                            width: 92,
                            height: 92,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: success,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 52,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      FadeTransition(
                        opacity: _content,
                        child: Column(
                          children: [
                            Semantics(
                              header: true,
                              liveRegion: true,
                              child: Text(
                                l10n.orderPlacedTitle,
                                textAlign: TextAlign.center,
                                style: text.displaySmall,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.orderPlacedBody,
                              textAlign: TextAlign.center,
                              style: text.bodyLarge?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                borderRadius: AppRadius.rLg,
                              ),
                              child: Column(
                                children: [
                                  _row(
                                    context,
                                    l10n.orderNumber,
                                    order.number,
                                    emphasize: true,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _row(
                                    context,
                                    l10n.estimatedDelivery,
                                    l10n.deliveryWindow,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _row(
                                    context,
                                    l10n.total,
                                    order.total.toPrice(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            AppButton(
                              label: l10n.trackOrder,
                              icon: Icons.local_shipping_outlined,
                              onPressed: () => context.pushNamed(
                                RouteNames.nOrderDetails,
                                pathParameters: {'id': order.id},
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: l10n.continueShopping,
                              variant: AppButtonVariant.outline,
                              icon: Icons.storefront_outlined,
                              onPressed: _home,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    final text = context.textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: text.bodyMedium)),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: (emphasize ? text.titleMedium : text.titleSmall)?.copyWith(
              color: emphasize ? context.colors.primary : null,
            ),
          ),
        ),
      ],
    );
  }
}
