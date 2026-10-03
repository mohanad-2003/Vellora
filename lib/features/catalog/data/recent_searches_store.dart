import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's recent search terms locally (newest first, de-duplicated
/// case-insensitively, capped at [maxItems]).
@lazySingleton
class RecentSearchesStore {
  RecentSearchesStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'pref_recent_searches';
  static const int maxItems = 8;

  List<String> read() => _prefs.getStringList(_key) ?? const [];

  Future<List<String>> add(String term) async {
    final t = term.trim();
    if (t.isEmpty) return read();
    final next = [
      t,
      ...read().where((e) => e.toLowerCase() != t.toLowerCase()),
    ].take(maxItems).toList();
    await _prefs.setStringList(_key, next);
    return next;
  }

  Future<List<String>> remove(String term) async {
    final next = read().where((e) => e != term).toList();
    await _prefs.setStringList(_key, next);
    return next;
  }

  Future<void> clear() => _prefs.remove(_key);
}
