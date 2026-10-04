import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exception_mapper.dart';
import '../../../checkout/presentation/models/checkout_models.dart';
import '../../data/wallet_remote_datasource.dart';
import '../../../../core/utils/safe_emit.dart';

enum PaymentMethodsStatus { loading, loaded, error }

class PaymentMethodsState extends Equatable {
  const PaymentMethodsState({
    this.status = PaymentMethodsStatus.loading,
    this.methods = const [],
    this.defaultId,
    this.failureKey,
  });

  final PaymentMethodsStatus status;
  final List<PaymentMethodOption> methods;
  final String? defaultId;
  final String? failureKey;

  @override
  List<Object?> get props => [status, methods, defaultId, failureKey];
}

/// The signed-in user's saved cards, kept on the server (brand, last four
/// digits and expiry only). Mutations return a failure key, null on success.
@injectable
class PaymentMethodsCubit extends Cubit<PaymentMethodsState> with SafeEmit<PaymentMethodsState> {
  PaymentMethodsCubit(this._remote) : super(const PaymentMethodsState());

  final WalletRemoteDataSource _remote;

  Future<void> load() async {
    emit(const PaymentMethodsState());
    try {
      final wallet = await _remote.getWallet();
      emit(
        PaymentMethodsState(
          status: PaymentMethodsStatus.loaded,
          methods: wallet.methods,
          defaultId: wallet.defaultId,
        ),
      );
    } catch (e) {
      emit(
        PaymentMethodsState(
          status: PaymentMethodsStatus.error,
          failureKey: mapExceptionToFailure(e).l10nKey,
        ),
      );
    }
  }

  Future<String?> add(NewCard card) => _change(() => _remote.addCard(card));

  Future<String?> setDefault(String id) =>
      _change(() => _remote.setDefaultCard(id));

  Future<String?> remove(String id) => _change(() => _remote.deleteCard(id));

  Future<String?> _change(Future<void> Function() action) async {
    try {
      await action();
      final wallet = await _remote.getWallet();
      emit(
        PaymentMethodsState(
          status: PaymentMethodsStatus.loaded,
          methods: wallet.methods,
          defaultId: wallet.defaultId,
        ),
      );
    } catch (e) {
      return mapExceptionToFailure(e).l10nKey;
    }
    return null;
  }
}
