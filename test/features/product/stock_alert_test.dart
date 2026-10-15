import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vellora/core/errors/failures.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/network/api_mappers.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:vellora/features/home/domain/entities/product_entity.dart';
import 'package:vellora/features/product/domain/entities/product_detail_entity.dart';
import 'package:vellora/features/product/domain/entities/product_variant_entity.dart';
import 'package:vellora/features/product/domain/usecases/add_review_usecase.dart';
import 'package:vellora/features/product/domain/usecases/get_product_details_usecase.dart';
import 'package:vellora/features/product/domain/usecases/get_related_products_usecase.dart';
import 'package:vellora/features/product/domain/usecases/set_stock_alert_usecase.dart';
import 'package:vellora/features/product/domain/usecases/toggle_favorite_usecase.dart';
import 'package:vellora/features/product/presentation/bloc/product_detail_bloc.dart';
import 'package:vellora/features/product/presentation/widgets/product_actions_bar.dart';

class _GetDetails extends Mock implements GetProductDetailsUseCase {}

class _GetRelated extends Mock implements GetRelatedProductsUseCase {}

class _Favorite extends Mock implements ToggleFavoriteUseCase {}

class _AddToCart extends Mock implements AddToCartUseCase {}

class _AddReview extends Mock implements AddReviewUseCase {}

class _SetAlert extends Mock implements SetStockAlertUseCase {}

const _product = ProductEntity(
  id: 'p1',
  name: 'Sold-out lamp',
  brand: 'Vellora',
  imagePath: '',
  price: 20,
);

ProductDetailEntity _detail({bool alert = false}) => ProductDetailEntity(
      product: _product,
      gallery: const [],
      description: '',
      variant: const ProductVariantEntity(colors: [], sizes: []),
      reviews: const [],
      inStock: false,
      stockAlert: alert,
    );

Widget _bar({required bool alert, VoidCallback? onAlert}) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        bottomNavigationBar: ProductActionsBar(
          inStock: false,
          onAddToCart: () {},
          onBuyNow: () {},
          stockAlert: alert,
          onStockAlert: onAlert,
        ),
      ),
    );

void main() {
  late _SetAlert setAlert;

  ProductDetailBloc build() => ProductDetailBloc(
        _GetDetails(),
        _GetRelated(),
        _Favorite(),
        _AddToCart(),
        _AddReview(),
        setAlert,
      );

  setUpAll(() => registerFallbackValue(const SetStockAlertParams('x', enabled: true)));
  setUp(() => setAlert = _SetAlert());

  group('ProductDetailBloc stock alert', () {
    blocTest<ProductDetailBloc, ProductDetailState>(
      'asking shows at once and is sent to the server',
      setUp: () => when(() => setAlert(any())).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => ProductDetailState(status: ProductDetailStatus.loaded, detail: _detail()),
      act: (b) => b.add(const ProductStockAlertToggled()),
      expect: () => [
        ProductDetailState(status: ProductDetailStatus.loaded, detail: _detail(alert: true)),
      ],
      verify: (_) {
        final sent = verify(() => setAlert(captureAny())).captured.single as SetStockAlertParams;
        expect(sent.productId, 'p1');
        expect(sent.enabled, isTrue);
      },
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'a request the server refuses is taken back',
      setUp: () => when(() => setAlert(any())).thenAnswer((_) async => Left(Failure.server(message: 'boom'))),
      build: build,
      seed: () => ProductDetailState(status: ProductDetailStatus.loaded, detail: _detail()),
      act: (b) => b.add(const ProductStockAlertToggled()),
      expect: () => [
        ProductDetailState(status: ProductDetailStatus.loaded, detail: _detail(alert: true)),
        isA<ProductDetailState>().having((s) => s.detail!.stockAlert, 'stockAlert', isFalse),
      ],
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'asking again cancels the request',
      setUp: () => when(() => setAlert(any())).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => ProductDetailState(status: ProductDetailStatus.loaded, detail: _detail(alert: true)),
      act: (b) => b.add(const ProductStockAlertToggled()),
      verify: (_) {
        final sent = verify(() => setAlert(captureAny())).captured.single as SetStockAlertParams;
        expect(sent.enabled, isFalse);
      },
    );
  });

  group('ProductActionsBar for a sold-out product', () {
    testWidgets('offers to notify instead of buy, and to cancel once asked', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_bar(alert: false, onAlert: () => taps++));
      expect(find.text('Notify me when available'), findsOneWidget);
      expect(find.text('Buy Now'), findsNothing);
      await tester.tap(find.text('Notify me when available'));
      expect(taps, 1);

      await tester.pumpWidget(_bar(alert: true, onAlert: () => taps++));
      expect(find.text('Cancel notification'), findsOneWidget);
    });

    testWidgets('keeps the disabled purchase buttons when no alert is wired', (tester) async {
      await tester.pumpWidget(_bar(alert: false));
      expect(find.text('Buy Now'), findsOneWidget);
      expect(find.text('Notify me when available'), findsNothing);
    });
  });

  test('a notification remembers the product it is about', () {
    final n = ApiMappers.notification({
      'id': 'n1',
      'kind': 'promo',
      'title': 'Back in stock',
      'body': 'Sold-out lamp is available again.',
      'isUnread': true,
      'createdAt': '2026-10-15T10:00:00.000Z',
      'orderId': null,
      'productId': 'p1',
    });
    expect(n.productId, 'p1');
    expect(n.orderId, isNull);
    expect(n.markRead().productId, 'p1');
  });
}
