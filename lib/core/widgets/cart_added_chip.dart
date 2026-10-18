import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/extensions/num_extensions.dart';
import 'package:vellora/core/theme/app_colors.dart';
import 'package:vellora/core/utils/haptics.dart';
import 'package:vellora/features/cart/presentation/bloc/cart_badge_cubit.dart';

import 'cart_flight.dart';
import 'glass_panel.dart';
import 'product_image.dart';

/// A small glass chip that rises over the bottom bar after something is added to
/// the cart: the picture, what the cart now holds, and "View cart". It goes away
/// by itself, or when the cart is open.
class CartAddedChip extends StatefulWidget {
  const CartAddedChip({
    super.key,
    required this.onViewCart,
    this.hidden = false,
  });

  final VoidCallback onViewCart;

  /// True while the cart itself is showing: the chip would only repeat it.
  final bool hidden;

  static const Duration stays = Duration(seconds: 4);

  @override
  State<CartAddedChip> createState() => _CartAddedChipState();
}

class _CartAddedChipState extends State<CartAddedChip> {
  Timer? _timer;
  CartAdded? _shown;

  @override
  void initState() {
    super.initState();
    CartFlight.added.addListener(_onAdded);
  }

  @override
  void dispose() {
    CartFlight.added.removeListener(_onAdded);
    _timer?.cancel();
    super.dispose();
  }

  void _onAdded() {
    final next = CartFlight.added.value;
    if (next == null) return;
    setState(() => _shown = next);
    _timer?.cancel();
    _timer = Timer(CartAddedChip.stays, _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    if (mounted) setState(() => _shown = null);
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.hidden ? null : _shown;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: shown == null
          ? const SizedBox(key: ValueKey('none'))
          : _Chip(
              key: ValueKey(shown),
              added: shown,
              onViewCart: () {
                Haptics.light();
                _dismiss();
                widget.onViewCart();
              },
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.added, required this.onViewCart});

  final CartAdded added;
  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final cart = context.read<CartBadgeCubit>();
    return BlocBuilder<CartBadgeCubit, int>(
      builder: (context, count) {
        return Semantics(
          liveRegion: true,
          label: '${l10n.addedToCart}, ${l10n.cartItemsCount(count)}',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GlassPanel(
                  radius: 30,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: 44,
                          child: ClipOval(
                            child: ProductImage(path: added.imagePath),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.addedToCart,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelLarge?.copyWith(
                                  color: GlassPanel.ink(context),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${l10n.cartItemsCount(count)} · '
                                '${cart.total.toPrice()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelSmall?.copyWith(
                                  color: GlassPanel.inkMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: kBrandGold,
                          shape: const StadiumBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onViewCart,
                            child: SizedBox(
                              height: 44,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      l10n.viewCart,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: text.labelLarge?.copyWith(
                                        color: kBrandNavy,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
