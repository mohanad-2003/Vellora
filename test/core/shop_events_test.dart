import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vellora/core/analytics/event_tracker.dart';
import 'package:vellora/core/errors/failures.dart';
import 'package:vellora/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vellora/features/cart/domain/repositories/cart_repository.dart';
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

class _Cart extends Mock implements CartRepository {}

class _GetDetails extends Mock implements GetProductDetailsUseCase {}

class _GetRelated extends Mock implements GetRelatedProductsUseCase {}

class _Favorite extends Mock implements ToggleFavoriteUseCase {}

class _AddToCart extends Mock implements AddToCartUseCase {}

class _AddReview extends Mock implements AddReviewUseCase {}

class _SetAlert extends Mock implements SetStockAlertUseCase {}

const _item = CartItemEntity(
  id: 'p7__',
  productId: 'p7',
  name: 'Tee',
  imagePath: '',
  price: 20,
  quantity: 1,
);

/// What the funnel in the back office counts: these must reach the tracker.
void main() {
  final sent = <Map<String, dynamic>>[];
  List<String> kinds() => [
        for (final b in sent)
          for (final e in b['events'] as List) (e as Map)['kind'] as String,
      ];

  setUpAll(() => registerFallbackValue(_item));

  setUp(() {
    sent.clear();
    EventTracker.sender = (body) async => sent.add(body);
  });
  tearDown(() => EventTracker.sender = null);

  group('adding to the bag', () {
    test('is reported once the item is really in the bag', () async {
      final repo = _Cart();
      when(() => repo.addItem(any())).thenAnswer((_) async => const Right(unit));

      final result = await AddToCartUseCase(repo)(_item);
      await Future<void>.delayed(Duration.zero);

      expect(result.isRight(), isTrue);
      expect(kinds(), ['add_to_cart']);
      expect(((sent.single['events'] as List).single as Map)['productId'], 'p7');
    });

    test('is not reported when it failed', () async {
      final repo = _Cart();
      when(() => repo.addItem(any()))
          .thenAnswer((_) async => Left(Failure.server(message: 'boom')));

      final result = await AddToCartUseCase(repo)(_item);
      await Future<void>.delayed(Duration.zero);

      expect(result.isLeft(), isTrue);
      expect(sent, isEmpty);
    });
  });

  group('opening a product', () {
    ProductDetailBloc bloc(GetProductDetailsUseCase getDetails) => ProductDetailBloc(
          getDetails,
          _GetRelated(),
          _Favorite(),
          _AddToCart(),
          _AddReview(),
          _SetAlert(),
        );

    test('is reported when the product loaded, with its id', () async {
      final getDetails = _GetDetails();
      final related = _GetRelated();
      when(() => related(any())).thenAnswer((_) async => const Right(<ProductEntity>[]));
      when(() => getDetails(any())).thenAnswer(
        (_) async => const Right(
          ProductDetailEntity(
            product: ProductEntity(id: 'p7', name: 'Tee', brand: 'V', imagePath: '', price: 20),
            gallery: [],
            description: '',
            variant: ProductVariantEntity(colors: [], sizes: []),
            reviews: [],
          ),
        ),
      );
      final b = ProductDetailBloc(getDetails, related, _Favorite(), _AddToCart(), _AddReview(), _SetAlert());

      b.add(const ProductDetailRequested('p7'));
      await b.stream.firstWhere((s) => s.status == ProductDetailStatus.loaded);
      await Future<void>.delayed(Duration.zero);

      expect(kinds(), ['view_product']);
      expect(((sent.single['events'] as List).single as Map)['productId'], 'p7');
      await b.close();
    });

    test('is not reported when the product failed to load', () async {
      final getDetails = _GetDetails();
      when(() => getDetails(any())).thenAnswer((_) async => Left(Failure.server(message: 'boom')));
      final b = bloc(getDetails);

      b.add(const ProductDetailRequested('p7'));
      await b.stream.firstWhere((s) => s.status == ProductDetailStatus.error);
      await Future<void>.delayed(Duration.zero);

      expect(sent, isEmpty);
      await b.close();
    });
  });
}
