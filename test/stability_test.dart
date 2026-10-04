import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vellora/core/constants/app_constants.dart';
import 'package:vellora/core/errors/failures.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/usecases/usecase.dart';
import 'package:vellora/core/widgets/quantity_selector.dart';
import 'package:vellora/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:vellora/features/cart/data/models/cart_item_model.dart';
import 'package:vellora/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vellora/features/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:vellora/features/cart/domain/usecases/apply_promo_usecase.dart';
import 'package:vellora/features/cart/domain/usecases/get_cart_usecase.dart';
import 'package:vellora/features/cart/domain/usecases/remove_from_cart_usecase.dart';
import 'package:vellora/features/cart/domain/usecases/update_quantity_usecase.dart';
import 'package:vellora/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:vellora/features/catalog/domain/usecases/get_catalog_products_usecase.dart';
import 'package:vellora/features/catalog/presentation/cubit/catalog_cubit.dart';
import 'package:vellora/features/explore/presentation/pages/explore_page.dart';
import 'package:vellora/features/home/domain/entities/home_data_entity.dart';
import 'package:vellora/features/home/domain/entities/product_entity.dart';
import 'package:vellora/features/home/domain/usecases/get_home_data_usecase.dart';
import 'package:vellora/features/product/domain/usecases/get_favorite_ids_usecase.dart';
import 'package:vellora/features/product/domain/usecases/toggle_favorite_usecase.dart';

class _MockHome extends Mock implements GetHomeDataUseCase {}

class _MockCatalog extends Mock implements GetCatalogProductsUseCase {}

class _MockFavIds extends Mock implements GetFavoriteIdsUseCase {}

class _MockToggle extends Mock implements ToggleFavoriteUseCase {}

class _MockAdd extends Mock implements AddToCartUseCase {}

class _MockGetCart extends Mock implements GetCartUseCase {}

class _MockUpdateQty extends Mock implements UpdateQuantityUseCase {}

class _MockRemove extends Mock implements RemoveFromCartUseCase {}

class _MockPromo extends Mock implements ApplyPromoUseCase {}

class _FakeQuery extends Fake implements CatalogQuery {}

ProductEntity _product(String id) =>
    ProductEntity(id: id, name: id, brand: 'b', imagePath: '', price: 10);

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(_FakeQuery());
    registerFallbackValue(const UpdateQuantityParams(itemId: '', quantity: 0));
  });

  group('Explore: a result that arrives after leaving the tab', () {
    test('does not throw "emit after close"', () async {
      final useCase = _MockHome();
      final reply = Completer<Either<Failure, HomeDataEntity>>();
      when(() => useCase(any())).thenAnswer((_) => reply.future);
      final cubit = ExploreCubit(useCase);

      final loading = cubit.load();
      await cubit.close(); // the user switched tab before the reply
      reply.complete(
        const Right(
          HomeDataEntity(
            banners: [],
            categories: [],
            featured: [],
            flashSale: [],
            newArrivals: [],
            bestSellers: [],
            recommended: [],
          ),
        ),
      );

      await expectLater(loading, completes);
    });
  });

  group('Search: only the latest request may show its result', () {
    late _MockCatalog getProducts;
    late _MockAdd addToCart;
    late CatalogCubit cubit;
    final replies = <String?, Completer<Either<Failure, List<ProductEntity>>>>{};

    setUp(() {
      getProducts = _MockCatalog();
      addToCart = _MockAdd();
      replies.clear();
      when(() => getProducts(any())).thenAnswer((i) {
        final q = (i.positionalArguments.first as CatalogQuery).query;
        return (replies[q] = Completer()).future;
      });
      final favIds = _MockFavIds();
      when(favIds.call).thenReturn(const Right(<String>{}));
      cubit = CatalogCubit(getProducts, favIds, _MockToggle(), addToCart);
    });

    tearDown(() => cubit.close());

    test('a slow older query does not overwrite a newer one', () async {
      final slow = cubit.load(query: 'sh');
      final fast = cubit.load(query: 'shoes');
      await Future<void>.delayed(Duration.zero);

      replies['shoes']!.complete(Right([_product('shoes-1')]));
      await fast;
      replies['sh']!.complete(Right([_product('shirt-1'), _product('shorts-1')]));
      await slow;

      expect(cubit.state.products.map((p) => p.id), ['shoes-1']);
      expect(cubit.state.query, 'shoes');
    });

    test('a reply that arrives after reset() is ignored', () async {
      final pending = cubit.load(query: 'nike');
      await Future<void>.delayed(Duration.zero);
      cubit.reset();

      replies['nike']!.complete(Right([_product('nike-1')]));
      await pending;

      expect(cubit.state.products, isEmpty);
      expect(cubit.state.status, CatalogStatus.initial);
    });

    test('the normal case still works', () async {
      final load = cubit.load(query: 'watch');
      await Future<void>.delayed(Duration.zero);
      replies['watch']!.complete(Right([_product('w1')]));
      await load;

      expect(cubit.state.status, CatalogStatus.loaded);
      expect(cubit.state.products.single.id, 'w1');
    });
  });

  group('Cart: quick taps on the quantity stepper', () {
    test('are written in order and the last one wins', () async {
      var stored = 1;
      final writes = <int>[];
      final getCart = _MockGetCart();
      final updateQty = _MockUpdateQty();
      when(() => getCart(any())).thenAnswer(
        (_) async => Right([
          CartItemEntity(
            id: 'p1__',
            productId: 'p1',
            name: 'Tee',
            imagePath: '',
            price: 10,
            quantity: stored,
          ),
        ]),
      );
      var call = 0;
      when(() => updateQty(any())).thenAnswer((i) async {
        final q = (i.positionalArguments.first as UpdateQuantityParams).quantity;
        // The first write is slow: without ordering it would land last and win.
        if (call++ == 0) await Future<void>.delayed(const Duration(milliseconds: 80));
        stored = q;
        writes.add(q);
        return const Right(unit);
      });
      final bloc = CartBloc(
        getCart,
        updateQty,
        _MockRemove(),
        _MockPromo(),
        _MockAdd(),
      );

      bloc.add(const CartStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc
        ..add(const CartQuantityChanged('p1__', 2))
        ..add(const CartQuantityChanged('p1__', 3));
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(writes, [2, 3], reason: 'storage sees the taps in order');
      expect(bloc.state.items.single.quantity, 3);
      expect(stored, 3);
      await bloc.close();
    });
  });

  group('Cart storage', () {
    late Directory dir;
    late Box box;
    late CartLocalDataSourceImpl local;

    CartItemModel item(String id, int qty) => CartItemModel(
          id: id,
          productId: id,
          name: id,
          imagePath: '',
          price: 5,
          quantity: qty,
        );

    setUpAll(() async {
      dir = await Directory.systemTemp.createTemp('cart_stability');
      Hive.init(dir.path);
      box = await Hive.openBox('cart_stability_box');
      local = CartLocalDataSourceImpl(box);
    });

    tearDownAll(() async {
      await Hive.close();
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });

    setUp(() => box.clear());

    test('replaceAll touches only what changed, so listeners never see an empty bag',
        () async {
      await local.replaceAll([item('a', 1), item('b', 2), item('c', 3)]);
      final events = <BoxEvent>[];
      final sub = box.watch().listen(events.add);

      await local.replaceAll([item('a', 1), item('b', 5), item('d', 1)]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      final changes = {for (final e in events) e.key: e.deleted};
      expect(changes, {'b': false, 'c': true, 'd': false},
          reason: 'a was untouched, nothing was cleared');
      expect(box.length, 3);
      expect(box.containsKey('a'), isTrue);
      expect(
        CartItemModel.fromJson(
          jsonDecode(box.get('b') as String) as Map<String, dynamic>,
        ).quantity,
        5,
      );
    });

    test('replaceAll with an identical bag writes nothing', () async {
      await local.replaceAll([item('a', 1), item('b', 2)]);
      final events = <BoxEvent>[];
      final sub = box.watch().listen(events.add);

      await local.replaceAll([item('a', 1), item('b', 2)]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(events, isEmpty);
    });

    test('one line never holds more than the API allows', () async {
      const max = AppConstants.maxLineQuantity;
      await local.addItem(item('a', max - 2));
      await local.addItem(item('a', 5));
      expect((await local.readAll()).single.quantity, max);

      await local.updateQuantity('a', 99);
      expect((await local.readAll()).single.quantity, max);

      await local.addItem(item('big', 99));
      expect(
        (await local.readAll()).firstWhere((i) => i.id == 'big').quantity,
        max,
      );
    });
  });

  group('Quantity stepper', () {
    testWidgets('stops at the limit it is given', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: QuantitySelector(
              quantity: AppConstants.maxLineQuantity,
              max: AppConstants.maxLineQuantity,
              onChanged: changes.add,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(changes, isEmpty);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(changes, [AppConstants.maxLineQuantity - 1]);
    });
  });
}
