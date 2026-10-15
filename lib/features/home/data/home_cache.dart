import 'dart:convert';

import 'package:hive/hive.dart';

/// The last Home response that arrived, kept on the phone, so Home can still
/// show something when the shop cannot be reached (no signal, or a sleeping
/// server). Every failure here is swallowed: a broken cache only means no
/// fallback, never a broken Home.
class HomeCache {
  const HomeCache();

  static const String boxName = 'home_cache';
  static const String _key = 'home';

  Future<Box<String>?> _box() async {
    try {
      return Hive.isBoxOpen(boxName)
          ? Hive.box<String>(boxName)
          : await Hive.openBox<String>(boxName);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> json) async {
    try {
      await (await _box())?.put(_key, jsonEncode(json));
    } catch (_) {}
  }

  /// The saved response, or null when there is none (or it cannot be read).
  Future<Map<String, dynamic>?> read() async {
    try {
      final text = (await _box())?.get(_key);
      if (text == null) return null;
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await (await _box())?.delete(_key);
    } catch (_) {}
  }
}
