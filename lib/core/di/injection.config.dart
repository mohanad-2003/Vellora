// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive/hive.dart' as _i979;
import 'package:injectable/injectable.dart' as _i526;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart'
    as _i161;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/auth/data/datasources/auth_local_datasource.dart'
    as _i992;
import '../../features/auth/data/datasources/auth_remote_datasource.dart'
    as _i161;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/forgot_password_usecase.dart'
    as _i560;
import '../../features/auth/domain/usecases/get_cached_user_usecase.dart'
    as _i389;
import '../../features/auth/domain/usecases/login_usecase.dart' as _i188;
import '../../features/auth/domain/usecases/logout_usecase.dart' as _i48;
import '../../features/auth/domain/usecases/register_usecase.dart' as _i941;
import '../../features/auth/domain/usecases/reset_password_usecase.dart'
    as _i474;
import '../../features/auth/domain/usecases/update_profile_usecase.dart'
    as _i798;
import '../../features/auth/domain/usecases/verify_otp_usecase.dart' as _i503;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/auth/presentation/bloc/user_session_cubit.dart' as _i864;
import '../../features/cart/data/datasources/cart_local_datasource.dart'
    as _i339;
import '../../features/cart/data/datasources/promo_datasource.dart' as _i905;
import '../../features/cart/data/repositories/cart_repository_impl.dart'
    as _i642;
import '../../features/cart/domain/repositories/cart_repository.dart' as _i322;
import '../../features/cart/domain/usecases/add_to_cart_usecase.dart' as _i659;
import '../../features/cart/domain/usecases/apply_promo_usecase.dart' as _i759;
import '../../features/cart/domain/usecases/get_cart_usecase.dart' as _i179;
import '../../features/cart/domain/usecases/remove_from_cart_usecase.dart'
    as _i355;
import '../../features/cart/domain/usecases/update_quantity_usecase.dart'
    as _i107;
import '../../features/cart/presentation/bloc/cart_badge_cubit.dart' as _i875;
import '../../features/cart/presentation/bloc/cart_bloc.dart' as _i517;
import '../../features/catalog/data/datasources/catalog_remote_datasource.dart'
    as _i248;
import '../../features/catalog/data/recent_searches_store.dart' as _i778;
import '../../features/catalog/data/repositories/catalog_repository_impl.dart'
    as _i428;
import '../../features/catalog/domain/repositories/catalog_repository.dart'
    as _i1018;
import '../../features/catalog/domain/usecases/get_catalog_products_usecase.dart'
    as _i296;
import '../../features/catalog/presentation/cubit/catalog_cubit.dart' as _i686;
import '../../features/checkout/presentation/cubit/checkout_cubit.dart'
    as _i645;
import '../../features/explore/presentation/pages/explore_page.dart' as _i487;
import '../../features/home/data/datasources/home_remote_datasource.dart'
    as _i278;
import '../../features/home/data/repositories/home_repository_impl.dart'
    as _i76;
import '../../features/home/domain/repositories/home_repository.dart' as _i0;
import '../../features/home/domain/usecases/get_home_data_usecase.dart'
    as _i1033;
import '../../features/home/presentation/bloc/home_bloc.dart' as _i202;
import '../../features/language_select/presentation/cubit/language_select_cubit.dart'
    as _i258;
import '../../features/notifications/data/notifications_remote_datasource.dart'
    as _i31;
import '../../features/notifications/presentation/cubit/notifications_cubit.dart'
    as _i405;
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart'
    as _i807;
import '../../features/orders/data/mock_orders_store.dart' as _i52;
import '../../features/orders/data/orders_remote_datasource.dart' as _i158;
import '../../features/orders/presentation/cubit/orders_cubit.dart' as _i1028;
import '../../features/product/data/datasources/favorites_local_datasource.dart'
    as _i10;
import '../../features/product/data/datasources/product_remote_datasource.dart'
    as _i963;
import '../../features/product/data/datasources/wishlist_remote_datasource.dart'
    as _i978;
import '../../features/product/data/repositories/favorites_repository_impl.dart'
    as _i981;
import '../../features/product/data/repositories/product_repository_impl.dart'
    as _i1040;
import '../../features/product/domain/repositories/favorites_repository.dart'
    as _i843;
import '../../features/product/domain/repositories/product_repository.dart'
    as _i39;
import '../../features/product/domain/usecases/add_review_usecase.dart'
    as _i585;
import '../../features/product/domain/usecases/get_favorite_ids_usecase.dart'
    as _i946;
import '../../features/product/domain/usecases/get_product_details_usecase.dart'
    as _i133;
import '../../features/product/domain/usecases/get_related_products_usecase.dart'
    as _i511;
import '../../features/product/domain/usecases/toggle_favorite_usecase.dart'
    as _i714;
import '../../features/product/presentation/bloc/product_detail_bloc.dart'
    as _i1052;
import '../../features/profile/data/wallet_remote_datasource.dart' as _i264;
import '../../features/profile/presentation/cubit/addresses_cubit.dart'
    as _i198;
import '../../features/profile/presentation/cubit/edit_profile_cubit.dart'
    as _i990;
import '../../features/profile/presentation/cubit/payment_methods_cubit.dart'
    as _i320;
import '../../features/profile/presentation/cubit/profile_cubit.dart' as _i36;
import '../../features/profile/presentation/cubit/security_cubit.dart' as _i527;
import '../../features/settings/presentation/cubit/notification_prefs_cubit.dart'
    as _i1036;
import '../../features/splash/presentation/cubit/splash_cubit.dart' as _i125;
import '../../features/wishlist/data/repositories/wishlist_repository_impl.dart'
    as _i919;
import '../../features/wishlist/domain/repositories/wishlist_repository.dart'
    as _i4;
import '../../features/wishlist/domain/usecases/get_wishlist_products_usecase.dart'
    as _i709;
import '../../features/wishlist/domain/usecases/remove_from_wishlist_usecase.dart'
    as _i120;
import '../../features/wishlist/presentation/bloc/wishlist_bloc.dart' as _i86;
import '../localization/locale_cubit.dart' as _i960;
import '../network/dio_client.dart' as _i667;
import '../network/interceptors/auth_interceptor.dart' as _i745;
import '../network/network_info.dart' as _i932;
import '../theme/theme_cubit.dart' as _i611;
import 'register_modules.dart' as _i8;

const String _mock = 'mock';
const String _api = 'api';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i161.InternetConnection>(
      () => registerModule.internetConnection,
    );
    gh.lazySingleton<_i52.MockOrdersStore>(() => _i52.MockOrdersStore());
    gh.lazySingleton<_i31.NotificationsRemoteDataSource>(
      () => _i31.MockNotificationsRemoteDataSource(),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i978.WishlistRemoteDataSource>(
      () => _i978.MockWishlistRemoteDataSource(),
      registerFor: {_mock},
    );
    await gh.factoryAsync<_i979.Box<dynamic>>(
      () => registerModule.userBox,
      instanceName: 'user_box',
      preResolve: true,
    );
    gh.lazySingleton<_i905.PromoDataSource>(
      () => _i905.MockPromoDataSource(),
      registerFor: {_mock},
    );
    await gh.factoryAsync<_i979.Box<dynamic>>(
      () => registerModule.favoritesBox,
      instanceName: 'favorites_box',
      preResolve: true,
    );
    gh.lazySingleton<_i963.ProductRemoteDataSource>(
      () => _i963.MockProductRemoteDataSource(),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i248.CatalogRemoteDataSource>(
      () => _i248.MockCatalogRemoteDataSource(),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i161.AuthRemoteDataSource>(
      () => _i161.MockAuthRemoteDataSource(),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i745.AuthInterceptor>(
      () => _i745.AuthInterceptor(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i158.OrdersRemoteDataSource>(
      () => _i158.MockOrdersRemoteDataSource(gh<_i52.MockOrdersStore>()),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i264.WalletRemoteDataSource>(
      () => _i264.MockWalletRemoteDataSource(),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i278.HomeRemoteDataSource>(
      () => _i278.MockHomeRemoteDataSource(),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i10.FavoritesLocalDataSource>(
      () => _i10.FavoritesLocalDataSourceImpl(
        gh<_i979.Box<dynamic>>(instanceName: 'favorites_box'),
      ),
    );
    await gh.factoryAsync<_i979.Box<dynamic>>(
      () => registerModule.cartBox,
      instanceName: 'cart_box',
      preResolve: true,
    );
    gh.lazySingleton<_i864.UserSessionCubit>(
      () => _i864.UserSessionCubit(
        gh<_i979.Box<dynamic>>(instanceName: 'user_box'),
      ),
    );
    gh.factory<_i807.OnboardingCubit>(
      () => _i807.OnboardingCubit(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i1036.NotificationPrefsCubit>(
      () => _i1036.NotificationPrefsCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i960.LocaleCubit>(
      () => _i960.LocaleCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i611.ThemeCubit>(
      () => _i611.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i778.RecentSearchesStore>(
      () => _i778.RecentSearchesStore(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i992.AuthLocalDataSource>(
      () => _i992.AuthLocalDataSourceImpl(
        gh<_i979.Box<dynamic>>(instanceName: 'user_box'),
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.lazySingleton<_i339.CartLocalDataSource>(
      () => _i339.CartLocalDataSourceImpl(
        gh<_i979.Box<dynamic>>(instanceName: 'cart_box'),
      ),
    );
    gh.lazySingleton<_i667.DioClient>(
      () => _i667.DioClient(gh<_i745.AuthInterceptor>()),
    );
    gh.lazySingleton<_i875.CartBadgeCubit>(
      () => _i875.CartBadgeCubit(
        gh<_i979.Box<dynamic>>(instanceName: 'cart_box'),
      ),
    );
    gh.factory<_i125.SplashCubit>(
      () => _i125.SplashCubit(
        gh<_i460.SharedPreferences>(),
        gh<_i979.Box<dynamic>>(instanceName: 'user_box'),
      ),
    );
    gh.lazySingleton<_i932.NetworkInfo>(
      () => _i932.NetworkInfoImpl(gh<_i161.InternetConnection>()),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.dio(gh<_i667.DioClient>()),
    );
    gh.factory<_i258.LanguageSelectCubit>(
      () => _i258.LanguageSelectCubit(
        gh<_i960.LocaleCubit>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i278.HomeRemoteDataSource>(
      () => _i278.ApiHomeRemoteDataSource(gh<_i361.Dio>()),
      registerFor: {_api},
    );
    gh.lazySingleton<_i905.PromoDataSource>(
      () => _i905.ApiPromoDataSource(gh<_i361.Dio>()),
      registerFor: {_api},
    );
    gh.lazySingleton<_i161.AuthRemoteDataSource>(
      () => _i161.ApiAuthRemoteDataSource(gh<_i361.Dio>()),
      registerFor: {_api},
    );
    gh.lazySingleton<_i158.OrdersRemoteDataSource>(
      () => _i158.ApiOrdersRemoteDataSource(gh<_i361.Dio>()),
      registerFor: {_api},
    );
    gh.lazySingleton<_i264.WalletRemoteDataSource>(
      () => _i264.ApiWalletRemoteDataSource(gh<_i361.Dio>()),
      registerFor: {_api},
    );
    gh.lazySingleton<_i248.CatalogRemoteDataSource>(
      () => _i248.ApiCatalogRemoteDataSource(gh<_i361.Dio>()),
      registerFor: {_api},
    );
    gh.lazySingleton<_i963.ProductRemoteDataSource>(
      () => _i963.ApiProductRemoteDataSource(gh<_i361.Dio>()),
      registerFor: {_api},
    );
    gh.lazySingleton<_i31.NotificationsRemoteDataSource>(
      () => _i31.ApiNotificationsRemoteDataSource(gh<_i361.Dio>()),
      registerFor: {_api},
    );
    gh.lazySingleton<_i978.WishlistRemoteDataSource>(
      () => _i978.ApiWishlistRemoteDataSource(gh<_i361.Dio>()),
      registerFor: {_api},
    );
    gh.lazySingleton<_i322.CartRepository>(
      () => _i642.CartRepositoryImpl(
        gh<_i339.CartLocalDataSource>(),
        gh<_i905.PromoDataSource>(),
      ),
    );
    gh.lazySingleton<_i1018.CatalogRepository>(
      () => _i428.CatalogRepositoryImpl(gh<_i248.CatalogRemoteDataSource>()),
    );
    gh.lazySingleton<_i405.UnreadNotificationsCubit>(
      () => _i405.UnreadNotificationsCubit(
        gh<_i31.NotificationsRemoteDataSource>(),
      ),
    );
    gh.factory<_i296.GetCatalogProductsUseCase>(
      () => _i296.GetCatalogProductsUseCase(gh<_i1018.CatalogRepository>()),
    );
    gh.factory<_i198.AddressesCubit>(
      () => _i198.AddressesCubit(gh<_i264.WalletRemoteDataSource>()),
    );
    gh.factory<_i320.PaymentMethodsCubit>(
      () => _i320.PaymentMethodsCubit(gh<_i264.WalletRemoteDataSource>()),
    );
    gh.factory<_i1028.OrdersCubit>(
      () => _i1028.OrdersCubit(gh<_i158.OrdersRemoteDataSource>()),
    );
    gh.factory<_i1028.OrderDetailCubit>(
      () => _i1028.OrderDetailCubit(gh<_i158.OrdersRemoteDataSource>()),
    );
    gh.lazySingleton<_i843.FavoritesRepository>(
      () => _i981.FavoritesRepositoryImpl(
        gh<_i10.FavoritesLocalDataSource>(),
        gh<_i978.WishlistRemoteDataSource>(),
        gh<_i992.AuthLocalDataSource>(),
      ),
    );
    gh.factory<_i946.GetFavoriteIdsUseCase>(
      () => _i946.GetFavoriteIdsUseCase(gh<_i843.FavoritesRepository>()),
    );
    gh.factory<_i714.ToggleFavoriteUseCase>(
      () => _i714.ToggleFavoriteUseCase(gh<_i843.FavoritesRepository>()),
    );
    gh.factory<_i659.AddToCartUseCase>(
      () => _i659.AddToCartUseCase(gh<_i322.CartRepository>()),
    );
    gh.factory<_i759.ApplyPromoUseCase>(
      () => _i759.ApplyPromoUseCase(gh<_i322.CartRepository>()),
    );
    gh.factory<_i179.GetCartUseCase>(
      () => _i179.GetCartUseCase(gh<_i322.CartRepository>()),
    );
    gh.factory<_i355.RemoveFromCartUseCase>(
      () => _i355.RemoveFromCartUseCase(gh<_i322.CartRepository>()),
    );
    gh.factory<_i107.UpdateQuantityUseCase>(
      () => _i107.UpdateQuantityUseCase(gh<_i322.CartRepository>()),
    );
    gh.factory<_i405.NotificationsCubit>(
      () => _i405.NotificationsCubit(
        gh<_i31.NotificationsRemoteDataSource>(),
        gh<_i405.UnreadNotificationsCubit>(),
      ),
    );
    gh.factory<_i686.CatalogCubit>(
      () => _i686.CatalogCubit(
        gh<_i296.GetCatalogProductsUseCase>(),
        gh<_i946.GetFavoriteIdsUseCase>(),
        gh<_i714.ToggleFavoriteUseCase>(),
        gh<_i659.AddToCartUseCase>(),
      ),
    );
    gh.factory<_i645.CheckoutCubit>(
      () => _i645.CheckoutCubit(
        gh<_i179.GetCartUseCase>(),
        gh<_i355.RemoveFromCartUseCase>(),
        gh<_i158.OrdersRemoteDataSource>(),
        gh<_i264.WalletRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i4.WishlistRepository>(
      () => _i919.WishlistRepositoryImpl(
        gh<_i843.FavoritesRepository>(),
        gh<_i1018.CatalogRepository>(),
      ),
    );
    gh.lazySingleton<_i39.ProductRepository>(
      () => _i1040.ProductRepositoryImpl(
        gh<_i963.ProductRemoteDataSource>(),
        gh<_i843.FavoritesRepository>(),
      ),
    );
    gh.factory<_i585.AddReviewUseCase>(
      () => _i585.AddReviewUseCase(gh<_i39.ProductRepository>()),
    );
    gh.factory<_i133.GetProductDetailsUseCase>(
      () => _i133.GetProductDetailsUseCase(gh<_i39.ProductRepository>()),
    );
    gh.factory<_i511.GetRelatedProductsUseCase>(
      () => _i511.GetRelatedProductsUseCase(gh<_i39.ProductRepository>()),
    );
    gh.factory<_i709.GetWishlistProductsUseCase>(
      () => _i709.GetWishlistProductsUseCase(gh<_i4.WishlistRepository>()),
    );
    gh.factory<_i120.RemoveFromWishlistUseCase>(
      () => _i120.RemoveFromWishlistUseCase(gh<_i4.WishlistRepository>()),
    );
    gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(
        gh<_i161.AuthRemoteDataSource>(),
        gh<_i992.AuthLocalDataSource>(),
        gh<_i843.FavoritesRepository>(),
      ),
    );
    gh.lazySingleton<_i0.HomeRepository>(
      () => _i76.HomeRepositoryImpl(
        gh<_i278.HomeRemoteDataSource>(),
        gh<_i843.FavoritesRepository>(),
      ),
    );
    gh.factory<_i517.CartBloc>(
      () => _i517.CartBloc(
        gh<_i179.GetCartUseCase>(),
        gh<_i107.UpdateQuantityUseCase>(),
        gh<_i355.RemoveFromCartUseCase>(),
        gh<_i759.ApplyPromoUseCase>(),
        gh<_i659.AddToCartUseCase>(),
      ),
    );
    gh.factory<_i1033.GetHomeDataUseCase>(
      () => _i1033.GetHomeDataUseCase(gh<_i0.HomeRepository>()),
    );
    gh.factory<_i560.ForgotPasswordUseCase>(
      () => _i560.ForgotPasswordUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i389.GetCachedUserUseCase>(
      () => _i389.GetCachedUserUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i188.LoginUseCase>(
      () => _i188.LoginUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i48.LogoutUseCase>(
      () => _i48.LogoutUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i941.RegisterUseCase>(
      () => _i941.RegisterUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i474.ResetPasswordUseCase>(
      () => _i474.ResetPasswordUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i798.UpdateProfileUseCase>(
      () => _i798.UpdateProfileUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i503.VerifyOtpUseCase>(
      () => _i503.VerifyOtpUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i86.WishlistBloc>(
      () => _i86.WishlistBloc(
        gh<_i709.GetWishlistProductsUseCase>(),
        gh<_i120.RemoveFromWishlistUseCase>(),
      ),
    );
    gh.factory<_i990.EditProfileCubit>(
      () => _i990.EditProfileCubit(gh<_i798.UpdateProfileUseCase>()),
    );
    gh.factory<_i797.AuthBloc>(
      () => _i797.AuthBloc(
        gh<_i188.LoginUseCase>(),
        gh<_i941.RegisterUseCase>(),
        gh<_i560.ForgotPasswordUseCase>(),
        gh<_i503.VerifyOtpUseCase>(),
        gh<_i474.ResetPasswordUseCase>(),
        gh<_i389.GetCachedUserUseCase>(),
        gh<_i48.LogoutUseCase>(),
      ),
    );
    gh.factory<_i202.HomeBloc>(
      () => _i202.HomeBloc(
        gh<_i1033.GetHomeDataUseCase>(),
        gh<_i714.ToggleFavoriteUseCase>(),
        gh<_i659.AddToCartUseCase>(),
        gh<_i946.GetFavoriteIdsUseCase>(),
      ),
    );
    gh.factory<_i527.SecurityCubit>(
      () => _i527.SecurityCubit(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i1052.ProductDetailBloc>(
      () => _i1052.ProductDetailBloc(
        gh<_i133.GetProductDetailsUseCase>(),
        gh<_i511.GetRelatedProductsUseCase>(),
        gh<_i714.ToggleFavoriteUseCase>(),
        gh<_i659.AddToCartUseCase>(),
        gh<_i585.AddReviewUseCase>(),
      ),
    );
    gh.factory<_i487.ExploreCubit>(
      () => _i487.ExploreCubit(gh<_i1033.GetHomeDataUseCase>()),
    );
    gh.factory<_i36.ProfileCubit>(
      () => _i36.ProfileCubit(
        gh<_i389.GetCachedUserUseCase>(),
        gh<_i48.LogoutUseCase>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i8.RegisterModule {}
