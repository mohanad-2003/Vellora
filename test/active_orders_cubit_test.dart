import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/features/orders/presentation/cubit/active_orders_cubit.dart';

/// The dot on Profile: orders still on their way, read sparingly.
void main() {
  late DateTime clock;
  late int reads;
  late bool signedIn;
  late int active;
  late bool fails;

  ActiveOrdersCubit make() => ActiveOrdersCubit(
    isSignedIn: () async => signedIn,
    countActive: () async {
      reads++;
      if (fails) throw StateError('offline');
      return active;
    },
    now: () => clock,
  );

  setUp(() {
    clock = DateTime(2030, 1, 1, 12);
    reads = 0;
    signedIn = true;
    active = 2;
    fails = false;
  });

  test('counts the active orders of a signed-in shopper', () async {
    final cubit = make();
    await cubit.refresh();
    expect(cubit.state, 2);
    await cubit.close();
  });

  test('a signed-out shopper has none and nothing is read', () async {
    signedIn = false;
    final cubit = make();
    await cubit.refresh();
    expect(cubit.state, 0);
    expect(reads, 0);
    await cubit.close();
  });

  test('reads are spaced out unless forced', () async {
    final cubit = make();
    await cubit.refresh();
    clock = clock.add(const Duration(seconds: 30));
    active = 5;
    await cubit.refresh();
    expect(reads, 1);
    expect(cubit.state, 2);

    await cubit.refresh(force: true);
    expect(reads, 2);
    expect(cubit.state, 5);

    clock = clock.add(const Duration(seconds: 120));
    active = 1;
    await cubit.refresh();
    expect(cubit.state, 1);
    await cubit.close();
  });

  test('a failed read keeps what is shown', () async {
    final cubit = make();
    await cubit.refresh();
    fails = true;
    await cubit.refresh(force: true);
    expect(cubit.state, 2);
    await cubit.close();
  });

  test('signing out clears the dot', () async {
    final cubit = make();
    await cubit.refresh();
    signedIn = false;
    await cubit.refresh(force: true);
    expect(cubit.state, 0);
    await cubit.close();
  });
}
