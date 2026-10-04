import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/cart_item_model.dart';

/// Hive `cart_box` is the single source of truth for the cart. Reads are
/// wrapped in [Future] so the UI can show shimmer while "loading".
abstract class CartLocalDataSource {
  Future<List<CartItemModel>> getItems();

  /// Same as [getItems] without the loading-skeleton delay (for syncing).
  Future<List<CartItemModel>> readAll();
  Future<void> addItem(CartItemModel item);
  Future<void> updateQuantity(String itemId, int quantity);
  Future<void> removeItem(String itemId);

  /// Overwrites the whole cart (used after syncing with the account).
  Future<void> replaceAll(List<CartItemModel> items);
  Future<void> clear();
}

@LazySingleton(as: CartLocalDataSource)
class CartLocalDataSourceImpl implements CartLocalDataSource {
  CartLocalDataSourceImpl(@Named(AppConstants.cartBox) this._box);

  final Box _box;

  @override
  Future<List<CartItemModel>> getItems() async {
    // Local storage is instant; the brief delay only lets the skeleton show.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return readAll();
  }

  @override
  Future<List<CartItemModel>> readAll() async {
    try {
      return _box.values
          .map((raw) =>
              CartItemModel.fromJson(jsonDecode(raw as String) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const CacheException('Failed to read cart');
    }
  }

  @override
  Future<void> addItem(CartItemModel item) async {
    try {
      final existingRaw = _box.get(item.id);
      if (existingRaw is String) {
        final existing = CartItemModel.fromJson(
            jsonDecode(existingRaw) as Map<String, dynamic>);
        final merged =
            existing.copyWith(quantity: existing.quantity + item.quantity);
        await _box.put(item.id, jsonEncode(merged.toJson()));
      } else {
        await _box.put(item.id, jsonEncode(item.toJson()));
      }
    } catch (_) {
      throw const CacheException('Failed to add item to cart');
    }
  }

  @override
  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      final raw = _box.get(itemId);
      if (raw is! String) return;
      final item =
          CartItemModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (quantity <= 0) {
        await _box.delete(itemId);
      } else {
        await _box.put(itemId, jsonEncode(item.copyWith(quantity: quantity).toJson()));
      }
    } catch (_) {
      throw const CacheException('Failed to update quantity');
    }
  }

  @override
  Future<void> removeItem(String itemId) async {
    try {
      await _box.delete(itemId);
    } catch (_) {
      throw const CacheException('Failed to remove item');
    }
  }

  @override
  Future<void> replaceAll(List<CartItemModel> items) async {
    try {
      await _box.clear();
      for (final item in items) {
        await _box.put(item.id, jsonEncode(item.toJson()));
      }
    } catch (_) {
      throw const CacheException('Failed to save cart');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _box.clear();
    } catch (_) {
      throw const CacheException('Failed to clear cart');
    }
  }
}
