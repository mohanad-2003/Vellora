import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/di/environments.dart';
import '../../../core/network/api_endpoints.dart';
import '../../checkout/presentation/models/checkout_models.dart';

/// The user's saved shipping addresses and which one is the default.
class AddressBook extends Equatable {
  const AddressBook({this.addresses = const [], this.defaultId});

  final List<ShippingAddress> addresses;
  final String? defaultId;

  @override
  List<Object?> get props => [addresses, defaultId];
}

/// The user's saved cards and which one is the default.
class Wallet extends Equatable {
  const Wallet({this.methods = const [], this.defaultId});

  final List<PaymentMethodOption> methods;
  final String? defaultId;

  @override
  List<Object?> get props => [methods, defaultId];
}

/// What the app keeps of a card: the number itself never leaves the device.
class NewCard extends Equatable {
  const NewCard({
    required this.brand,
    required this.last4,
    required this.expiry,
  });

  final String brand;
  final String last4;

  /// `MM/YY`.
  final String expiry;

  /// Card brand from the leading digits of [number], or `Card` when unknown.
  static String brandOf(String number) {
    final d = number.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('4')) return 'Visa';
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(d)) return 'Mastercard';
    if (RegExp(r'^3[47]').hasMatch(d)) return 'Amex';
    return 'Card';
  }

  @override
  List<Object?> get props => [brand, last4, expiry];
}

/// Saved addresses and payment methods. Needs a signed-in user against the API.
abstract class WalletRemoteDataSource {
  Future<AddressBook> getAddresses();
  Future<void> addAddress(ShippingAddress address);
  Future<void> setDefaultAddress(String id);
  Future<void> deleteAddress(String id);

  Future<Wallet> getWallet();
  Future<void> addCard(NewCard card);
  Future<void> setDefaultCard(String id);
  Future<void> deleteCard(String id);
}

@mockOnly
@LazySingleton(as: WalletRemoteDataSource)
class MockWalletRemoteDataSource implements WalletRemoteDataSource {
  final List<ShippingAddress> _addresses = [
    const ShippingAddress(
      id: 'a1',
      label: 'Home',
      recipient: 'Test User',
      line: '12 Main Street',
      city: 'Amman',
      phone: '+962700000',
    ),
  ];
  final List<PaymentMethodOption> _cards = [
    const PaymentMethodOption(
      id: 'c1',
      kind: PaymentKind.card,
      title: 'Visa •••• 4242',
      subtitle: '08/28',
    ),
  ];
  String? _defaultAddress = 'a1';
  String? _defaultCard = 'c1';

  @override
  Future<AddressBook> getAddresses() async =>
      AddressBook(addresses: List.of(_addresses), defaultId: _defaultAddress);

  @override
  Future<void> addAddress(ShippingAddress address) async {
    _addresses.add(address);
    _defaultAddress ??= address.id;
  }

  @override
  Future<void> setDefaultAddress(String id) async => _defaultAddress = id;

  @override
  Future<void> deleteAddress(String id) async {
    _addresses.removeWhere((a) => a.id == id);
    if (_defaultAddress == id) {
      _defaultAddress = _addresses.isEmpty ? null : _addresses.first.id;
    }
  }

  @override
  Future<Wallet> getWallet() async =>
      Wallet(methods: List.of(_cards), defaultId: _defaultCard);

  @override
  Future<void> addCard(NewCard card) async {
    final id = 'c${_cards.length + 1}';
    _cards.add(
      PaymentMethodOption(
        id: id,
        kind: PaymentKind.card,
        title: '${card.brand} •••• ${card.last4}',
        subtitle: card.expiry,
      ),
    );
    _defaultCard ??= id;
  }

  @override
  Future<void> setDefaultCard(String id) async => _defaultCard = id;

  @override
  Future<void> deleteCard(String id) async {
    _cards.removeWhere((c) => c.id == id);
    if (_defaultCard == id) {
      _defaultCard = _cards.isEmpty ? null : _cards.first.id;
    }
  }
}

@apiOnly
@LazySingleton(as: WalletRemoteDataSource)
class ApiWalletRemoteDataSource implements WalletRemoteDataSource {
  ApiWalletRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<AddressBook> getAddresses() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.addresses);
    String? defaultId;
    final addresses = <ShippingAddress>[];
    for (final raw in res.data!) {
      final j = raw as Map<String, dynamic>;
      final id = j['id'] as String;
      if (j['isDefault'] == true) defaultId = id;
      addresses.add(
        ShippingAddress(
          id: id,
          label: j['label'] as String,
          recipient: j['recipient'] as String,
          line: j['line'] as String,
          city: j['city'] as String,
          phone: j['phone'] as String? ?? '',
        ),
      );
    }
    return AddressBook(addresses: addresses, defaultId: defaultId);
  }

  @override
  Future<void> addAddress(ShippingAddress a) async {
    await _dio.post<void>(
      ApiEndpoints.addresses,
      data: {
        'label': a.label,
        'recipient': a.recipient,
        if (a.phone.isNotEmpty) 'phone': a.phone,
        'line': a.line,
        'city': a.city,
      },
    );
  }

  @override
  Future<void> setDefaultAddress(String id) async {
    await _dio.put<void>(ApiEndpoints.addressDefault(id));
  }

  @override
  Future<void> deleteAddress(String id) async {
    await _dio.delete<void>(ApiEndpoints.address(id));
  }

  @override
  Future<Wallet> getWallet() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.paymentMethods);
    String? defaultId;
    final methods = <PaymentMethodOption>[];
    for (final raw in res.data!) {
      final j = raw as Map<String, dynamic>;
      final id = j['id'] as String;
      if (j['isDefault'] == true) defaultId = id;
      methods.add(
        PaymentMethodOption(
          id: id,
          kind: PaymentKind.card,
          title: '${j['brand'] ?? 'Card'} •••• ${j['last4']}',
          subtitle: j['expiry'] as String? ?? '',
        ),
      );
    }
    return Wallet(methods: methods, defaultId: defaultId);
  }

  @override
  Future<void> addCard(NewCard card) async {
    await _dio.post<void>(
      ApiEndpoints.paymentMethods,
      data: {'brand': card.brand, 'last4': card.last4, 'expiry': card.expiry},
    );
  }

  @override
  Future<void> setDefaultCard(String id) async {
    await _dio.put<void>(ApiEndpoints.paymentMethodDefault(id));
  }

  @override
  Future<void> deleteCard(String id) async {
    await _dio.delete<void>(ApiEndpoints.paymentMethod(id));
  }
}
