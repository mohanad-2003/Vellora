import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/features/checkout/presentation/models/checkout_models.dart';
import 'package:vellora/features/profile/data/wallet_remote_datasource.dart';
import 'package:vellora/features/profile/presentation/cubit/addresses_cubit.dart';
import 'package:vellora/features/profile/presentation/cubit/payment_methods_cubit.dart';

/// A data source whose every call fails, to check the error paths.
class _Offline implements WalletRemoteDataSource {
  Never _fail() => throw Exception('offline');

  @override
  Future<AddressBook> getAddresses() async => _fail();
  @override
  Future<void> addAddress(ShippingAddress address) async => _fail();
  @override
  Future<void> setDefaultAddress(String id) async => _fail();
  @override
  Future<void> deleteAddress(String id) async => _fail();
  @override
  Future<Wallet> getWallet() async => _fail();
  @override
  Future<void> addCard(NewCard card) async => _fail();
  @override
  Future<void> setDefaultCard(String id) async => _fail();
  @override
  Future<void> deleteCard(String id) async => _fail();
}

void main() {
  const newAddress = ShippingAddress(
    id: 'ignored',
    label: 'Work',
    recipient: 'Test User',
    line: '99 Office Road',
    city: 'Amman',
    phone: '',
  );

  group('AddressesCubit', () {
    test('load shows the saved addresses and the default', () async {
      final cubit = AddressesCubit(MockWalletRemoteDataSource());
      await cubit.load();
      expect(cubit.state.status, AddressesStatus.loaded);
      expect(cubit.state.addresses, hasLength(1));
      expect(cubit.state.defaultId, cubit.state.addresses.first.id);
    });

    test('add, set default and remove re-read the list', () async {
      final cubit = AddressesCubit(MockWalletRemoteDataSource());
      await cubit.load();

      expect(await cubit.add(newAddress), isNull);
      expect(cubit.state.addresses, hasLength(2));

      final second = cubit.state.addresses.last;
      expect(await cubit.setDefault(second.id), isNull);
      expect(cubit.state.defaultId, second.id);

      expect(await cubit.remove(second.id), isNull);
      expect(cubit.state.addresses, hasLength(1));
      expect(cubit.state.defaultId, cubit.state.addresses.first.id,
          reason: 'deleting the default promotes another');
    });

    test('a failing server becomes an error state / a failure key', () async {
      final cubit = AddressesCubit(_Offline());
      await cubit.load();
      expect(cubit.state.status, AddressesStatus.error);
      expect(cubit.state.failureKey, isNotNull);
      expect(await cubit.add(newAddress), isNotNull);
    });
  });

  group('PaymentMethodsCubit', () {
    test('adds a card and keeps only brand, last four and expiry', () async {
      final cubit = PaymentMethodsCubit(MockWalletRemoteDataSource());
      await cubit.load();
      expect(cubit.state.methods, hasLength(1));

      final digits = '5555555555554444';
      expect(
        await cubit.add(NewCard(
          brand: NewCard.brandOf(digits),
          last4: digits.substring(digits.length - 4),
          expiry: '01/30',
        )),
        isNull,
      );
      final added = cubit.state.methods.last;
      expect(added.title, 'Mastercard •••• 4444');
      expect(added.subtitle, '01/30');
      expect(added.title.contains('5555555555'), isFalse);
    });

    test('a failing server becomes an error state', () async {
      final cubit = PaymentMethodsCubit(_Offline());
      await cubit.load();
      expect(cubit.state.status, PaymentMethodsStatus.error);
    });
  });

  test('card brand detection', () {
    expect(NewCard.brandOf('4242 4242 4242 4242'), 'Visa');
    expect(NewCard.brandOf('5555555555554444'), 'Mastercard');
    expect(NewCard.brandOf('2223003122003222'), 'Mastercard');
    expect(NewCard.brandOf('378282246310005'), 'Amex');
    expect(NewCard.brandOf('6011111111111117'), 'Card');
  });
}
