import 'package:flutter_bloc/flutter_bloc.dart';

/// Ignores [emit] once the cubit is closed. A request that finishes after the
/// user left the screen would otherwise throw "Cannot emit new states after
/// calling close".
mixin SafeEmit<S> on BlocBase<S> {
  @override
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }
}
