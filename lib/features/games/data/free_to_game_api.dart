import 'package:dio/dio.dart';

class FreeToGameApi {
  FreeToGameApi()
    : _client = Dio(
        BaseOptions(
          baseUrl: 'https://www.freetogame.com/api',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

  static final source = Uri.https('www.freetogame.com', '/');
  final Dio _client;

  Future<List<FreeGame>> loadGames() async {
    final response = await _client.get<List<dynamic>>(
      '/games',
      queryParameters: {'sort-by': 'popularity'},
    );
    final games = response.data;
    if (games == null) throw const FormatException('Missing games list');
    return games
        .map((game) => FreeGame.fromJson(game as Map<String, dynamic>))
        .toList(growable: false);
  }

  void close() => _client.close(force: true);
}

class FreeGame {
  FreeGame.fromJson(Map<String, dynamic> json)
    : title = json['title'] as String,
      thumbnail = json['thumbnail'] as String? ?? '',
      description = json['short_description'] as String? ?? '',
      genre = json['genre'] as String? ?? '',
      platform = json['platform'] as String? ?? '',
      link = _website(json['game_url']);

  final String title;
  final String thumbnail;
  final String description;
  final String genre;
  final String platform;
  final Uri? link;

  bool matches(String query) =>
      title.toLowerCase().contains(query) ||
      genre.toLowerCase().contains(query) ||
      platform.toLowerCase().contains(query);

  static Uri? _website(Object? value) {
    final uri = value is String ? Uri.tryParse(value) : null;
    if (uri == null || uri.host.isEmpty) return null;
    return uri.isScheme('https') || uri.isScheme('http') ? uri : null;
  }
}
