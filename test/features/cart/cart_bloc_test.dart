import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vellora/core/errors/failures.dart';
import 'package:vellora/core/usecases/usecase.dart';
import 'package:vellora/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vellora/features/cart/domain/entities/cart_summary_entity.dart';
import 'package:vellora/features/cart/domain/entities/promo_code_entity.dart';
import 'package:vellora/features/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:vellora/features/cart/domain/usecases/apply_promo_usecase.dart';
import 'package:vellora/features/cart/domain/usecases/get_cart_usecase.dart';
import 'package:vellora/features/cart/domain/usecases/remove_from_cart_usecase.dart';
import 'package:vellora/features/cart/domain/usecases/update_quantity_usecase.dart';
import 'package:vellora/features/cart/presentation/bloc/cart_bloc.dart';

class _MockGetCart extends Mock implements GetCartUseCase {}

class _MockUpdateQty extends Mock implements UpdateQuantityUseCase {}

class _MockRemove extends Mock implements RemoveFromCartUseCase {}

class _MockApplyPromo extends Mock implements ApplyPromoUseCase {}

class _MockAddToCart extends Mock implements AddToCartUseCase {}

void main() {
  late _MockGetCart getCart;
  late _MockUpdateQty updateQty;
  late _MockRemove remove;
  late _MockApplyPromo applyPromo;
  late _MockAddToCart addToCart;

  const item = CartItemEntity(
    id: 'p1__M',
    productId: 'p1',
    name: 'Tee',
    imagePath: 'assets/images/products/product_hoodie_black.png',
    price: 20,
    quantity: 2,
  );

  setUpAll(() {
    registerFallbackValue(
        const UpdateQuantityParams(itemId: '', quantity: 0));
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    getCart = _MockGetCart();
    updateQty = _MockUpdateQty();
    remove = _MockRemove();
    applyPromo = _MockApplyPromo();
    addToCart = _MockAddToCart();
  });

  CartBloc build() => CartBloc(getCart, updateQty, remove, applyPromo, addToCart);

  blocTest<CartBloc, CartState>(
    'emits [loading, loaded] with items',
    build: () {
      when(() => getCart(any()))
          .thenAnswer((_) async => const Right([item]));
      return build();
    },
    act: (bloc) => bloc.add(const CartStarted()),
    expect: () => [
      predicate<CartState>((s) => s.status == CartStatus.loading),
      predicate<CartState>(
          (s) => s.status == CartStatus.loaded && s.items.length == 1),
    ],
  );

  blocTest<CartBloc, CartState>(
    'emits [loading, empty] with no items',
    build: () {
      when(() => getCart(any())).thenAnswer((_) async => const Right([]));
      return build();
    },
    act: (bloc) => bloc.add(const CartStarted()),
    expect: () => [
      predicate<CartState>((s) => s.status == CartStatus.loading),
      predicate<CartState>((s) => s.status == CartStatus.empty),
    ],
  );

  blocTest<CartBloc, CartState>(
    'sets promoError when promo validation fails',
    build: () {
      when(() => getCart(any()))
          .thenAnswer((_) async => const Right([item]));
      when(() => applyPromo(any())).thenAnswer(
        (_) async => const Left(Failure.validation(message: 'bad')),
      );
      return build();
    },
    seed: () => const CartState(status: CartStatus.loaded, items: [item]),
    act: (bloc) => bloc.add(const CartPromoApplied('WRONG')),
    expect: () => [
      predicate<CartState>((s) => s.applyingPromo),
      predicate<CartState>((s) => s.promoError),
    ],
  );

  group('CartSummaryEntity', () {
    test('computes subtotal, discount and free shipping over \$100', () {
      const items = [
        CartItemEntity(
          id: 'a',
          productId: 'a',
          name: 'A',
          imagePath: '',
          price: 60,
          quantity: 2,
        ),
      ];
      const promo = PromoCodeEntity(code: 'SAVE10', discountPercent: 10);
      final summary = CartSummaryEntity.from(items, promo);
      expect(summary.subtotal, 120);
      expect(summary.discount, 12);
      expect(summary.shipping, 0);
      expect(summary.total, 108);
      expect(summary.itemCount, 2);
    });
  });
}
