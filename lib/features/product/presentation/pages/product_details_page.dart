import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/responsive/responsive.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/widgets/app_bar_widget.dart';
import 'package:vellora/core/widgets/cart_flight.dart';
import 'package:vellora/core/widgets/custom_snackbar.dart';
import 'package:vellora/core/widgets/failure_state_view.dart';
import 'package:vellora/core/widgets/section_header.dart';
import 'package:vellora/features/home/domain/entities/product_entity.dart';
import 'package:vellora/features/product/presentation/bloc/product_detail_bloc.dart';
import 'package:vellora/features/product/presentation/widgets/product_actions_bar.dart';
import 'package:vellora/features/product/presentation/widgets/product_gallery.dart';
import 'package:vellora/features/product/presentation/widgets/related_products_list.dart';
import 'package:vellora/features/product/presentation/widgets/detail_header.dart';
import 'package:vellora/features/product/presentation/widgets/detail_info_section.dart';
import 'package:vellora/features/product/presentation/widgets/detail_skeleton.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key, required this.productId, this.heroTag});

  final String productId;

  /// Tag of the card photo this page was opened from, for the shared-element
  /// transition. Null on deep links.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ProductDetailBloc>()..add(ProductDetailRequested(productId)),
      child: _ProductDetailView(productId: productId, heroTag: heroTag),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  const _ProductDetailView({required this.productId, this.heroTag});

  final String productId;
  final Object? heroTag;

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  // Where the picture starts and lands when the product is added to the cart.
  final _imageKey = GlobalKey(debugLabel: 'productImage');
  final _addKey = GlobalKey(debugLabel: 'productAdd');

  String get productId => widget.productId;
  Object? get heroTag => widget.heroTag;

  /// The product's picture flies into the Add to Cart button, and the message
  /// shows once it has landed. Without a visible picture (scrolled away) it
  /// starts from the middle of the screen.
  Future<void> _added(BuildContext context, ProductDetailState state) async {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final target = CartFlight.rectOf(_addKey);
    final image = CartFlight.rectOf(_imageKey);
    final screen = MediaQuery.sizeOf(context);
    final visible =
        image != null && image.bottom > 120 && image.top < screen.height - 120;
    final from = visible
        ? Rect.fromCenter(center: image.center, width: 56, height: 56)
        : Rect.fromCenter(
            center: Offset(screen.width / 2, screen.height * 0.4),
            width: 56,
            height: 56,
          );
    final path = state.detail?.product.imagePath;
    if (target != null && path != null) {
      await CartFlight.fly(context, from: from, to: target, imagePath: path);
    }
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      message: l10n.addedToCart,
      type: SnackType.success,
      actionLabel: l10n.viewCart,
      onAction: () => router.goNamed(RouteNames.nCart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: BlocConsumer<ProductDetailBloc, ProductDetailState>(
        listenWhen: (prev, curr) =>
            prev.addedToCartTick != curr.addedToCartTick ||
            prev.buyNowTick != curr.buyNowTick,
        listener: (context, state) {
          // Both ticks start at 0 and only ever increase on success.
          if (state.buyNowTick > 0 &&
              state.buyNowTick >= state.addedToCartTick) {
            context.pushNamed(RouteNames.nCheckout);
          } else if (state.addedToCartTick > 0) {
            _added(context, state);
          }
        },
        builder: (context, state) {
          return switch (state.status) {
            ProductDetailStatus.loading ||
            ProductDetailStatus.initial => const DetailSkeleton(),
            ProductDetailStatus.error => Column(
              children: [
                AppBarWidget(title: l10n.productDetails),
                Expanded(
                  child: FailureStateView(
                    failureKey: state.failureKey,
                    onRetry: () => context.read<ProductDetailBloc>().add(
                      ProductDetailRequested(productId),
                    ),
                  ),
                ),
              ],
            ),
            ProductDetailStatus.loaded => _LoadedView(
              state: state,
              heroTag: heroTag,
              imageKey: _imageKey,
              addKey: _addKey,
            ),
          };
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.state,
    required this.imageKey,
    required this.addKey,
    this.heroTag,
  });

  final ProductDetailState state;
  final Object? heroTag;
  final GlobalKey imageKey;
  final GlobalKey addKey;

  void _openRelated(BuildContext context, ProductEntity p, String tag) {
    context.pushReplacementNamed(
      RouteNames.nProduct,
      pathParameters: {'id': p.id},
      extra: tag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = state.detail!;
    final bloc = context.read<ProductDetailBloc>();

    final product = detail.product;
    final actions = ProductActionsBar(
      inStock: detail.inStock,
      price: product.price * state.quantity,
      originalPrice: product.hasDiscount
          ? product.originalPrice! * state.quantity
          : null,
      addKey: addKey,
      onAddToCart: () => bloc.add(const ProductAddToCartRequested()),
      onBuyNow: () => bloc.add(const ProductBuyNowRequested()),
      stockAlert: detail.stockAlert,
      onStockAlert: () {
        if (!detail.stockAlert) {
          AppSnackbar.show(context, message: context.l10n.stockAlertOn);
        }
        bloc.add(const ProductStockAlertToggled());
      },
    );

    final wide = context.screenWidth >= Breakpoints.medium;
    if (wide) {
      return Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: KeyedSubtree(
                          key: imageKey,
                          child: ProductGallery(
                            images: detail.gallery,
                            heroTag: heroTag,
                            semanticLabel: detail.product.name,
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: DetailBackButton(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: SafeArea(
                    left: false,
                    bottom: false,
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl,
                          ).copyWith(
                            top: AppSpacing.lg,
                            bottom: ProductActionsBar.clearance,
                          ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: DetailHeaderActions(state: state),
                          ),
                          DetailInfoSection(state: state),
                          const SizedBox(height: AppSpacing.xxl),
                          _RelatedSection(
                            state: state,
                            onOpen: (p, t) => _openRelated(context, p, t),
                            horizontalPadding: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: actions),
        ],
      );
    }

    final width = context.screenWidth;
    final galleryHeight = (width * 1.02).clamp(280.0, 460.0);
    final gutter = context.pageGutter;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: galleryHeight,
                backgroundColor: context.colors.surface,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                leadingWidth: 64,
                leading: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12),
                  child: DetailBackButton(),
                ),
                actions: [
                  DetailHeaderActions(state: state),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: KeyedSubtree(
                    key: imageKey,
                    child: ProductGallery(
                      images: detail.gallery,
                      heroTag: heroTag,
                      semanticLabel: detail.product.name,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.xl,
                    gutter,
                    0,
                  ),
                  child: DetailInfoSection(state: state),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xxl,
                    bottom: AppSpacing.xxl,
                  ),
                  child: _RelatedSection(
                    state: state,
                    onOpen: (p, t) => _openRelated(context, p, t),
                    horizontalPadding: gutter,
                  ),
                ),
              ),
              // The purchase bar floats over the foot of the page.
              const SliverToBoxAdapter(
                child: SizedBox(height: ProductActionsBar.clearance),
              ),
            ],
          ),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: actions),
      ],
    );
  }
}

class _RelatedSection extends StatelessWidget {
  const _RelatedSection({
    required this.state,
    required this.onOpen,
    required this.horizontalPadding,
  });

  final ProductDetailState state;
  final void Function(ProductEntity product, String heroTag) onOpen;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (state.related.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.relatedProducts,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        ),
        const SizedBox(height: AppSpacing.md),
        RelatedProductsList(
          products: state.related,
          onTap: onOpen,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        ),
      ],
    );
  }
}
