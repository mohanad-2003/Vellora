import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exception_mapper.dart';
import '../../../checkout/presentation/models/checkout_models.dart';
import '../../data/wallet_remote_datasource.dart';
import '../../../../core/utils/safe_emit.dart';

enum AddressesStatus { loading, loaded, error }

class AddressesState extends Equatable {
  const AddressesState({
    this.status = AddressesStatus.loading,
    this.addresses = const [],
    this.defaultId,
    this.failureKey,
  });

  final AddressesStatus status;
  final List<ShippingAddress> addresses;
  final String? defaultId;
  final String? failureKey;

  @override
  List<Object?> get props => [status, addresses, defaultId, failureKey];
}

/// The signed-in user's address book, kept on the server. Every change is sent
/// first and the list is then re-read, so the screen always shows what the
/// server holds. Mutations return a failure key (null on success) so the page
/// can show a message.
@injectable
class AddressesCubit extends Cubit<AddressesState> with SafeEmit<AddressesState> {
  AddressesCubit(this._remote) : super(const AddressesState());

  final WalletRemoteDataSource _remote;

  Future<void> load() async {
    emit(const AddressesState());
    try {
      final book = await _remote.getAddresses();
      emit(
        AddressesState(
          status: AddressesStatus.loaded,
          addresses: book.addresses,
          defaultId: book.defaultId,
        ),
      );
    } catch (e) {
      emit(
        AddressesState(
          status: AddressesStatus.error,
          failureKey: mapExceptionToFailure(e).l10nKey,
        ),
      );
    }
  }

  Future<String?> add(ShippingAddress address) =>
      _change(() => _remote.addAddress(address));

  Future<String?> setDefault(String id) =>
      _change(() => _remote.setDefaultAddress(id));

  Future<String?> remove(String id) => _change(() => _remote.deleteAddress(id));

  Future<String?> _change(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      return mapExceptionToFailure(e).l10nKey;
    }
    try {
      final book = await _remote.getAddresses();
      emit(
        AddressesState(
          status: AddressesStatus.loaded,
          addresses: book.addresses,
          defaultId: book.defaultId,
        ),
      );
    } catch (e) {
      return mapExceptionToFailure(e).l10nKey;
    }
    return null;
  }
}
