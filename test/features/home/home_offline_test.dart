import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vellora/core/errors/exceptions.dart';
import 'package:vellora/core/network/interceptors/error_interceptor.dart';
import 'package:vellora/features/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:vellora/features/home/data/datasources/home_remote_datasource.dart';
import 'package:vellora/features/home/data/home_cache.dart';
import 'package:vellora/features/home/data/repositories/home_repository_impl.dart';
import 'package:vellora/features/home/domain/usecases/get_home_data_usecase.dart';
import 'package:vellora/features/home/presentation/bloc/home_bloc.dart';
import 'package:vellora/features/product/domain/repositories/favorites_repository.dart';
import 'package:vellora/features/product/domain/usecases/get_favorite_ids_usecase.dart';
import 'package:vellora/features/product/domain/usecases/toggle_favorite_usecase.dart';

class _Favorites extends Mock implements FavoritesRepository {}

class _AddToCart extends Mock implements AddToCartUseCase {}

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
    {
      'id': 'men',
      'name': 'Men',
      'imageUrl': 'https://img/men.png',
      'productCount': 1,
    },
  ],
  'featured': [_product(id)],
  'flashSale': <dynamic>[],
  'newArrivals': [_product(id)],
  'bestSellers': <dynamic>[],
  'recommended': <dynamic>[],
  'promoCodes': <dynamic>[],
};

/// A shop that answers with [reply]: a JSON map, or an error type.
Dio _shop(FutureOr<Object> Function() reply) {
  final dio = Dio();
  dio.interceptors
    ..add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final r = await reply();
          if (r is Map<String, dynamic>) {
            handler.resolve(
              Response(requestOptions: options, data: r, statusCode: 200),
            );
          } else if (r is int) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: r,
                  data: <String, dynamic>{},
                ),
              ),
              true,
            );
          } else {
            handler.reject(
              DioException(
                requestOptions: options,
                type: r as DioExceptionType,
              ),
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

  test(
    'Home displays the saved feed before a pending request completes',
    () async {
      final fresh = Completer<Object>();
      FutureOr<Object> answer = _home('saved');
      final source = ApiHomeRemoteDataSource(_shop(() => answer));
      await source.getHomeData(languageCode: 'ar');
      answer = fresh.future;

      final favorites = _Favorites();
      when(favorites.getFavoriteIds).thenReturn(const Right({'saved'}));
      final bloc = HomeBloc(
        GetHomeDataUseCase(HomeRepositoryImpl(source, favorites)),
        ToggleFavoriteUseCase(favorites),
        _AddToCart(),
        GetFavoriteIdsUseCase(favorites),
      );
      addTearDown(bloc.close);

      final cached = bloc.stream.firstWhere(
        (state) => state.status == HomeStatus.loaded,
      );
      bloc.add(const HomeStarted('ar'));
      final cachedProduct = (await cached).data!.featured.single;
      expect(cachedProduct.id, 'saved');
      expect(cachedProduct.isFavorite, isTrue);
      expect(fresh.isCompleted, isFalse);

      final updated = bloc.stream.firstWhere(
        (state) => state.data?.featured.single.id == 'fresh',
      );
      fresh.complete(_home('fresh'));
      expect((await updated).status, HomeStatus.loaded);
    },
  );

  test(
    'saved feeds are isolated by language and older replies cannot replace them',
    () async {
      final old = Completer<Object>();
      final source = ApiHomeRemoteDataSource(_shop(() => _home('english')));
      await source.getHomeData(languageCode: 'en');
      expect(await source.getCachedHomeData('ar'), isNull);

      final started = Completer<void>();
      final replies = ApiHomeRemoteDataSource(
        _shop(() {
          if (!started.isCompleted) {
            started.complete();
            return old.future;
          }
          return _home('arabic-new');
        }),
      );
      final slow = replies.getHomeData(languageCode: 'ar');
      await started.future;
      await replies.getHomeData(languageCode: 'ar');
      old.complete(_home('arabic-old'));
      await slow;

      expect(
        (await source.getCachedHomeData('en'))!.featured.single.id,
        'english',
      );
      expect(
        (await source.getCachedHomeData('ar'))!.featured.single.id,
        'arabic-new',
      );
    },
  );

  test('the older unlabelled cache still works as an offline fallback', () async {
    final box = await Hive.openBox<String>(HomeCache.boxName);
    await box.put('home', jsonEncode(_home('legacy')));
    final source = ApiHomeRemoteDataSource(
      _shop(() => DioExceptionType.connectionError),
    );

    expect(await source.getCachedHomeData('ar'), isNull);
    final result = await source.getHomeData(languageCode: 'ar');
    expect(result.featured.single.id, 'legacy');
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
