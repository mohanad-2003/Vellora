import 'dart:convert';

import 'package:hive/hive.dart';

/// The last valid Home response for each language, kept on the phone.
class HomeCache {
  const HomeCache();

  static const String boxName = 'home_cache';
  static const String _legacyKey = 'home';

  String _key(String? languageCode) =>
      languageCode == null ? _legacyKey : 'home:$languageCode';

  Future<Box<String>?> _box() async {
    try {
      return Hive.isBoxOpen(boxName)
          ? Hive.box<String>(boxName)
          : await Hive.openBox<String>(boxName);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String languageCode, Map<String, dynamic> json) async {
    try {
      await (await _box())?.put(_key(languageCode), jsonEncode(json));
    } catch (_) {}
  }

  /// The saved response, or null when there is none (or it cannot be read).
  /// A null language reads the unlabelled response from older app versions.
  Future<Map<String, dynamic>?> read(String? languageCode) async {
    try {
      final text = (await _box())?.get(_key(languageCode));
      if (text == null) return null;
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await (await _box())?.clear();
    } catch (_) {}
  }
}
