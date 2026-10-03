import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:vellora/features/auth/data/models/user_model.dart';
import 'package:vellora/features/orders/data/mock_orders_store.dart';
import 'package:vellora/features/orders/data/orders_remote_datasource.dart';
import 'package:vellora/features/orders/domain/order_entity.dart';
import 'package:vellora/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:vellora/features/product/data/datasources/favorites_local_datasource.dart';
import 'package:vellora/features/product/data/datasources/wishlist_remote_datasource.dart';
import 'package:vellora/features/product/data/repositories/favorites_repository_impl.dart';

class _MemoryFavorites implements FavoritesLocalDataSource {
  final Set<String> ids = {};

  @override
  Set<String> getFavoriteIds() => Set.of(ids);

  @override
  bool isFavorite(String id) => ids.contains(id);

  @override
  Future<bool> toggle(String id) async => ids.add(id) ? true : !ids.remove(id);

  @override
  Future<void> addAll(Set<String> more) async => ids.addAll(more);

  @override
  Future<void> clear() async => ids.clear();
}

class _Session implements AuthLocalDataSource {
  _Session({required this.signedIn});

  final bool signedIn;

  @override
  Future<UserModel?> getCachedUser() async => signedIn
      ? const UserModel(id: 'u', name: 'Sara', email: 's@x.com', token: 'tok')
      : null;

  @override
  Future<void> cacheUser(UserModel user) async {}

  @override
  Future<void> clear() async {}
}

OrderEntity _order(String id, OrderStatus status) => OrderEntity(
      id: id,
      number: '#VL-$id',
      createdAt: DateTime(2026, 1, 1),
      status: status,
      items: const [],
      subtotal: 10,
      discount: 0,
      shipping: 0,
      total: 10,
      recipient: 'Sara',
      addressLine: '12 Main Street',
      city: 'Amman',
      paymentKind: OrderPaymentKind.cashOnDelivery,
      paymentDetail: '',
    );

void main() {
  group('favourites sync', () {
    late _MemoryFavorites local;
    late MockWishlistRemoteDataSource remote;

    FavoritesRepositoryImpl repo({required bool signedIn}) =>
        FavoritesRepositoryImpl(local, remote, _Session(signedIn: signedIn));

    setUp(() {
      local = _MemoryFavorites();
      remote = MockWishlistRemoteDataSource();
    });

    test('signing in merges the device and the account, losing neither', () async {
      local.ids.addAll({'guest-1', 'both'});
      await remote.add('both');
      await remote.add('account-1');

      await repo(signedIn: true).sync();

      const all = {'guest-1', 'both', 'account-1'};
      expect(local.ids, all, reason: 'the device gets the account favourites');
      expect(await remote.getIds(), all, reason: 'the account gets the guest ones');
    });

    test('a guest sync does nothing', () async {
      local.ids.add('a');
      await remote.add('b');

      await repo(signedIn: false).sync();

      expect(local.ids, {'a'});
      expect(await remote.getIds(), {'b'});
    });

    test('toggling while signed in is mirrored to the account', () async {
      final r = repo(signedIn: true);
      await r.toggle('p1');
      await Future<void>.delayed(Duration.zero);
      expect(await remote.getIds(), {'p1'});

      await r.toggle('p1');
      await Future<void>.delayed(Duration.zero);
      expect(await remote.getIds(), isEmpty);
    });

    test('toggling as a guest stays on the device', () async {
      await repo(signedIn: false).toggle('p1');
      await Future<void>.delayed(Duration.zero);
      expect(local.ids, {'p1'});
      expect(await remote.getIds(), isEmpty);
    });

    test('clear forgets the device favourites', () async {
      local.ids.addAll({'a', 'b'});
      await repo(signedIn: true).clear();
      expect(local.ids, isEmpty);
    });
  });

  group('cancelling an order', () {
    late MockOrdersStore store;

    setUp(() {
      store = MockOrdersStore()
        ..add(_order('1', OrderStatus.processing))
        ..add(_order('2', OrderStatus.shipped));
    });

    Future<OrderDetailCubit> open(String id) async {
      final cubit = OrderDetailCubit(MockOrdersRemoteDataSource(store));
      await cubit.load(id);
      return cubit;
    }

    test('a processing order becomes cancelled', () async {
      final cubit = await open('1');
      expect(await cubit.cancel(), isNull);
      expect(cubit.state.order!.status, OrderStatus.cancelled);
    });

    test('a shipped order cannot be cancelled', () async {
      final cubit = await open('2');
      expect(await cubit.cancel(), 'orderNotCancellable');
      expect(cubit.state.order!.status, OrderStatus.shipped);
    });
  });
}
