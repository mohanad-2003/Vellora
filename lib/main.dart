import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'features/cart/domain/repositories/cart_repository.dart';
import 'features/product/domain/repositories/favorites_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await configureDependencies();
  // A signed-in user's wishlist and bag may have changed on another device.
  unawaited(sl<FavoritesRepository>().sync());
  unawaited(sl<CartRepository>().sync());
  runApp(const VelloraApp());
}
