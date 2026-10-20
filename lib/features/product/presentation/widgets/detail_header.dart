import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/widgets/app_icon_button.dart';
import 'package:vellora/core/widgets/count_badge.dart';
import 'package:vellora/core/widgets/favorite_button.dart';
import 'package:vellora/features/cart/presentation/bloc/cart_badge_cubit.dart';
import 'package:vellora/features/product/presentation/bloc/product_detail_bloc.dart';
import 'package:vellora/features/product/presentation/widgets/share_product_sheet.dart';

class DetailBackButton extends StatelessWidget {
  const DetailBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.arrow_back_ios_new_rounded,
      iconSize: 18,
      semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(RouteNames.nHome);
        }
      },
    );
  }
}

/// Favorite, share (opens the share sheet) and cart shortcuts.
class DetailHeaderActions extends StatelessWidget {
  const DetailHeaderActions({super.key, required this.state});

  final ProductDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final product = state.detail!.product;
    final bloc = context.read<ProductDetailBloc>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FavoriteButton(
          isFavorite: product.isFavorite,
          onToggle: () => bloc.add(const ProductFavoriteToggled()),
          size: 40,
          discColor: context.colors.surfaceContainerHighest,
        ),
        AppIconButton(
          icon: Icons.ios_share_rounded,
          semanticLabel: l10n.shareProduct,
          onPressed: () => showShareProductSheet(context, product),
        ),
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
  }
}
