import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:vellora/core/errors/exceptions.dart';
import 'package:vellora/core/network/interceptors/error_interceptor.dart';
import 'package:vellora/features/home/data/datasources/home_remote_datasource.dart';

Map<String, dynamic> _product(String id) => {
      'id': id,
      'name': 'Product $id',
      'brand': 'Vellora',
      'imageUrl': 'https://img/$id.png',
      'price': 20,
      'rating': 4.5,
      'reviewCount': 3,
      'category': 'men',
    };

Map<String, dynamic> _home(String id) => {
      'banners': <dynamic>[],
      'categories': [
        {'id': 'men', 'name': 'Men', 'imageUrl': 'https://img/men.png', 'productCount': 1},
      ],
      'featured': [_product(id)],
      'flashSale': <dynamic>[],
      'newArrivals': [_product(id)],
      'bestSellers': <dynamic>[],
      'recommended': <dynamic>[],
      'promoCodes': <dynamic>[],
    };

/// A shop that answers with [reply]: a JSON map, or an error type.
Dio _shop(Object Function() reply) {
  final dio = Dio();
  dio.interceptors
    ..add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final r = reply();
          if (r is Map<String, dynamic>) {
            handler.resolve(Response(requestOptions: options, data: r, statusCode: 200));
          } else if (r is int) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(requestOptions: options, statusCode: r, data: <String, dynamic>{}),
              ),
              true,
            );
          } else {
            handler.reject(
              DioException(requestOptions: options, type: r as DioExceptionType),
              true,
            );
          }
        },
      ),
    )
    ..add(ErrorInterceptor());
  return dio;
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vellora_home_cache');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('when the shop cannot be reached Home shows what it saw last time', () async {
    Object answer = _home('p1');
    final source = ApiHomeRemoteDataSource(_shop(() => answer));

    final online = await source.getHomeData();
    expect(online.featured.single.id, 'p1');

    for (final failure in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.unknown,
      503,
    ]) {
      answer = failure;
      final offline = await source.getHomeData();
      expect(offline.featured.single.id, 'p1', reason: '$failure');
      expect(offline.categories.single.name, 'Men');
    }
  });

  test('the newest response replaces the saved one', () async {
    Object answer = _home('old');
    final source = ApiHomeRemoteDataSource(_shop(() => answer));
    await source.getHomeData();
    answer = _home('new');
    await source.getHomeData();

    answer = DioExceptionType.connectionError;
    expect((await source.getHomeData()).featured.single.id, 'new');
  });

  test('with nothing saved the failure is passed on', () async {
    final source = ApiHomeRemoteDataSource(_shop(() => DioExceptionType.connectionError));

    await expectLater(
      source.getHomeData(),
      throwsA(isA<DioException>().having((e) => e.error, 'cause', isA<NetworkException>())),
    );
  });

  test('a refusal that is not about reaching the shop is not hidden by the saved copy', () async {
    Object answer = _home('p1');
    final source = ApiHomeRemoteDataSource(_shop(() => answer));
    await source.getHomeData();

    answer = 404;
    await expectLater(
      source.getHomeData(),
      throwsA(isA<DioException>().having((e) => e.error, 'cause', isA<NotFoundException>())),
    );
  });
}
