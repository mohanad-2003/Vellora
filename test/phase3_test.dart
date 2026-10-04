import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vellora/core/errors/exceptions.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/core/usecases/usecase.dart';
import 'package:vellora/core/utils/card_input.dart';
import 'package:vellora/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vellora/features/cart/domain/usecases/get_cart_usecase.dart';
import 'package:vellora/features/cart/domain/usecases/remove_from_cart_usecase.dart';
import 'package:vellora/features/checkout/data/delivery_remote_datasource.dart';
import 'package:vellora/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:vellora/features/checkout/presentation/models/checkout_models.dart';
import 'package:vellora/features/orders/data/orders_remote_datasource.dart';
import 'package:vellora/features/orders/domain/order_entity.dart';
import 'package:vellora/features/orders/domain/place_order_request.dart';
import 'package:vellora/features/profile/data/wallet_remote_datasource.dart';
import 'package:vellora/features/profile/presentation/pages/payment_methods_page.dart';

class _MockGetCart extends Mock implements GetCartUseCase {}

class _MockRemove extends Mock implements RemoveFromCartUseCase {}

class _MockOrders extends Mock implements OrdersRemoteDataSource {}

class _MockWallet extends Mock implements WalletRemoteDataSource {}

class _MockDelivery extends Mock implements DeliveryRemoteDataSource {}

class _FakeRequest extends Fake implements PlaceOrderRequest {}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'id': 'o1',
        'number': '#VL-1',
        'status': 'processing',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'items': <Object>[],
        'subtotal': 10,
        'discount': 0,
        'shipping': 0,
        'total': 10,
        'address': {'recipient': 'R', 'line': 'L', 'city': 'C'},
        'payment': {'kind': 'cashOnDelivery', 'detail': ''},
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

OrderEntity _order() => OrderEntity(
      id: 'o1',
      number: '#VL-1',
      createdAt: DateTime(2026),
      status: OrderStatus.processing,
      items: const [],
      subtotal: 10,
      discount: 0,
      shipping: 0,
      total: 10,
      recipient: 'R',
      addressLine: 'L',
      city: 'C',
      paymentKind: OrderPaymentKind.cashOnDelivery,
      paymentDetail: '',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRequest());
    registerFallbackValue(const NoParams());
  });

  group('card number checks', () {
    test('Luhn accepts real test numbers and rejects typos', () {
      expect(CardInput.passesLuhn('4242424242424242'), isTrue);
      expect(CardInput.passesLuhn('5555555555554444'), isTrue);
      expect(CardInput.passesLuhn('378282246310005'), isTrue);
      expect(CardInput.passesLuhn('4242424242424241'), isFalse, reason: 'last digit wrong');
      expect(CardInput.passesLuhn('4242424242424224'), isFalse, reason: 'two digits swapped');
      expect(CardInput.passesLuhn('4242a42424242424'), isFalse);
    });

    test('a plausible number has 12-19 digits and passes Luhn', () {
      expect(CardInput.isPlausibleNumber('4242 4242 4242 4242'), isTrue);
      expect(CardInput.isPlausibleNumber('4242 4242 4242 4241'), isFalse);
      expect(CardInput.isPlausibleNumber('0000 0000 0000'), isTrue, reason: '12 zeros pass Luhn');
      expect(CardInput.isPlausibleNumber('4242'), isFalse);
      expect(CardInput.isPlausibleNumber('1' * 20), isFalse);
      expect(CardInput.isPlausibleNumber(''), isFalse);
    });

    test('expiry: format and expired-or-not', () {
      final now = DateTime(2026, 10, 4);
      expect(CardInput.isValidExpiryFormat('10/26'), isTrue);
      expect(CardInput.isValidExpiryFormat('13/26'), isFalse);
      expect(CardInput.isValidExpiryFormat('00/26'), isFalse);
      expect(CardInput.isValidExpiryFormat('1/26'), isFalse);
      expect(CardInput.isValidExpiryFormat('10/2026'), isFalse);

      expect(CardInput.isExpired('09/26', now: now), isTrue, reason: 'last month');
      expect(CardInput.isExpired('10/26', now: now), isFalse, reason: 'good through this month');
      expect(CardInput.isExpired('11/26', now: now), isFalse);
      expect(CardInput.isExpired('12/25', now: now), isTrue);
      expect(CardInput.isExpired('01/27', now: now), isFalse);
    });

    test('the formatters group digits and add the slash', () {
      TextEditingValue run(TextInputFormatter f, String from, String to) =>
          f.formatEditUpdate(
            TextEditingValue(text: from),
            TextEditingValue(text: to),
          );

      expect(
        run(CardNumberFormatter(), '', '4242424242424242').text,
        '4242 4242 4242 4242',
      );
      expect(run(CardNumberFormatter(), '', '42a4-2').text, '4242');
      expect(
        run(CardNumberFormatter(), '', '1' * 30).text.replaceAll(' ', '').length,
        CardInput.maxDigits,
      );

      expect(run(ExpiryFormatter(), '1', '12').text, '12/');
      expect(run(ExpiryFormatter(), '12/', '12/2').text, '12/2');
      expect(run(ExpiryFormatter(), '12/2', '12/28').text, '12/28');
      expect(run(ExpiryFormatter(), '12/28', '12/289').text, '12/28');
      expect(run(ExpiryFormatter(), '12/', '12').text, '12', reason: 'deleting the slash');
    });
  });

  group('add-card form', () {
    Future<List<NewCard>> pumpForm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final saved = <NewCard>[];
      await tester.pumpWidget(
        MaterialApp(
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
            body: SingleChildScrollView(child: CardForm(onSubmit: saved.add)),
          ),
        ),
      );
      return saved;
    }

    Future<void> fill(
      WidgetTester tester, {
      required String number,
      String holder = 'Sara Ahmed',
      required String expiry,
    }) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), number);
      await tester.enterText(fields.at(1), holder);
      await tester.enterText(fields.at(2), expiry);
      await tester.tap(find.text('Save Card'));
      await tester.pump();
    }

    testWidgets('a valid card saves only brand, last four and expiry', (tester) async {
      final saved = await pumpForm(tester);

      await fill(tester, number: '4242424242424242', expiry: '1228');

      expect(saved, [const NewCard(brand: 'Visa', last4: '4242', expiry: '12/28')]);
      // Nothing that could hold the full number is part of what is saved.
      expect(saved.single.toString(), isNot(contains('4242424242424242')));
      expect(saved.single.props.join(), isNot(contains('4242 4242')));
    });

    testWidgets('a mistyped number is refused', (tester) async {
      final saved = await pumpForm(tester);

      await fill(tester, number: '4242424242424241', expiry: '1228');

      expect(saved, isEmpty);
      expect(find.text('Enter a valid card number.'), findsOneWidget);
    });

    testWidgets('an expired card is refused', (tester) async {
      final saved = await pumpForm(tester);

      await fill(tester, number: '4242424242424242', expiry: '0120');

      expect(saved, isEmpty);
      expect(find.text('This card has expired.'), findsOneWidget);
    });

    testWidgets('the card number field does not feed keyboard suggestions', (tester) async {
      await pumpForm(tester);
      final number = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).first,
          matching: find.byType(EditableText),
        ),
      );
      expect(number.autocorrect, isFalse);
      expect(number.enableSuggestions, isFalse);
    });
  });

  group('placing an order is safe to retry', () {
    late _MockOrders orders;
    late _MockGetCart getCart;
    late _MockRemove remove;
    late _MockWallet wallet;
    late _MockDelivery delivery;
    late CheckoutCubit cubit;
    final requests = <PlaceOrderRequest>[];

    const item = CartItemEntity(
      id: 'p1__',
      productId: 'p1',
      name: 'Tee',
      imagePath: '',
      price: 10,
      quantity: 1,
    );
    const addressA = ShippingAddress(
      id: 'a1', label: 'Home', recipient: 'R', line: 'L', city: 'C', phone: '1');
    const addressB = ShippingAddress(
      id: 'a2', label: 'Work', recipient: 'R2', line: 'L2', city: 'C2', phone: '2');

    setUp(() async {
      requests.clear();
      orders = _MockOrders();
      getCart = _MockGetCart();
      wallet = _MockWallet();
      delivery = _MockDelivery();
      when(() => getCart(any())).thenAnswer((_) async => const Right([item]));
      when(wallet.getAddresses).thenAnswer(
        (_) async => const AddressBook(addresses: [addressA, addressB], defaultId: 'a1'),
      );
      when(wallet.getWallet).thenAnswer((_) async => const Wallet());
      when(delivery.getOptions).thenAnswer((_) async => DeliveryDefaults.options);
      when(() => orders.placeOrder(any())).thenAnswer((i) async {
        requests.add(i.positionalArguments.first as PlaceOrderRequest);
        return _order();
      });
      remove = _MockRemove();
      when(() => remove(any())).thenAnswer((_) async => const Right(unit));
      cubit = CheckoutCubit(getCart, remove, orders, wallet, delivery);
      await cubit.load(null);
    });

    tearDown(() => cubit.close());

    test('a retry after a failure carries the same key', () async {
      var calls = 0;
      when(() => orders.placeOrder(any())).thenAnswer((i) async {
        requests.add(i.positionalArguments.first as PlaceOrderRequest);
        if (calls++ == 0) throw const NetworkException(); // the reply never came
        return _order();
      });

      await cubit.placeOrder();
      expect(cubit.state.status, CheckoutStatus.ready, reason: 'failed, can retry');
      await cubit.placeOrder();

      expect(requests, hasLength(2));
      expect(requests[0].idempotencyKey, isNotEmpty);
      expect(requests[1].idempotencyKey, requests[0].idempotencyKey);
      expect(cubit.state.status, CheckoutStatus.success);
    });

    test('changing what is ordered starts a new attempt', () async {
      when(() => orders.placeOrder(any())).thenAnswer((i) async {
        requests.add(i.positionalArguments.first as PlaceOrderRequest);
        throw const NetworkException();
      });

      await cubit.placeOrder();
      cubit.selectAddress('a2');
      await cubit.placeOrder();
      cubit.selectDelivery(DeliveryDefaults.options.last.id);
      await cubit.placeOrder();
      cubit.selectPayment('pay_cod');
      await cubit.placeOrder();

      final keys = requests.map((r) => r.idempotencyKey).toList();
      expect(keys, hasLength(4));
      expect(keys.toSet(), hasLength(4), reason: 'every change is a fresh attempt');
      expect(requests[1].recipient, 'R2', reason: 'the new address was used');
    });

    test('keys are long, random and URL-safe', () async {
      final keys = <String>{};
      for (var i = 0; i < 20; i++) {
        final c = CheckoutCubit(getCart, remove, orders, wallet, delivery);
        await c.load(null);
        await c.placeOrder();
        await c.close();
      }
      keys.addAll(requests.map((r) => r.idempotencyKey));
      expect(keys.length, requests.length, reason: 'no repeats across carts');
      for (final k in keys) {
        expect(k, matches(RegExp(r'^[A-Za-z0-9_-]{16,64}$')));
      }
    });
  });

  test('the API request carries the key as an Idempotency-Key header', () async {
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    final remote = ApiOrdersRemoteDataSource(dio);

    final order = await remote.placeOrder(
      PlaceOrderRequest(
        items: const [PlaceOrderItem(productId: 'p1', quantity: 1)],
        express: false,
        recipient: 'R',
        addressLine: 'L',
        city: 'C',
        paymentKind: OrderPaymentKind.cashOnDelivery,
        preview: _order(),
        idempotencyKey: 'abcd1234abcd1234abcd1234abcd1234',
      ),
    );

    expect(order.id, 'o1');
    expect(adapter.requests.single.path, '/orders');
    expect(
      adapter.requests.single.headers['Idempotency-Key'],
      'abcd1234abcd1234abcd1234abcd1234',
    );
    // The key is metadata for the server, not part of the order itself.
    expect(jsonEncode(adapter.requests.single.data), isNot(contains('abcd1234')));
  });
}
