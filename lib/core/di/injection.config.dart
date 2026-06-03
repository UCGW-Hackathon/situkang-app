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
import 'package:injectable/injectable.dart' as _i526;
import 'package:situkang_app/core/di/app_module.dart' as _i369;
import 'package:situkang_app/core/network/api_client.dart' as _i743;
import 'package:situkang_app/core/network/connectivity_manager.dart' as _i239;
import 'package:situkang_app/core/network/dio_api_client.dart' as _i36;
import 'package:situkang_app/core/network/offline_action_queue.dart' as _i148;
import 'package:situkang_app/core/network/websocket_manager.dart' as _i238;
import 'package:situkang_app/core/services/push_notification_service.dart'
    as _i557;
import 'package:situkang_app/core/storage/cache_manager.dart' as _i601;
import 'package:situkang_app/core/storage/hive_cache_manager_impl.dart' as _i68;
import 'package:situkang_app/core/storage/secure_token_storage_impl.dart'
    as _i783;
import 'package:situkang_app/core/storage/token_storage.dart' as _i1049;
import 'package:situkang_app/features/auth/data/datasources/auth_local_data_source.dart'
    as _i1025;
import 'package:situkang_app/features/auth/data/datasources/auth_remote_data_source.dart'
    as _i984;
import 'package:situkang_app/features/auth/data/repositories/auth_repository_impl.dart'
    as _i984;
import 'package:situkang_app/features/auth/domain/repositories/auth_repository.dart'
    as _i746;
import 'package:situkang_app/features/auth/domain/usecases/forgot_password_use_case.dart'
    as _i822;
import 'package:situkang_app/features/auth/domain/usecases/login_use_case.dart'
    as _i127;
import 'package:situkang_app/features/auth/domain/usecases/logout_use_case.dart'
    as _i1010;
import 'package:situkang_app/features/auth/domain/usecases/refresh_token_use_case.dart'
    as _i250;
import 'package:situkang_app/features/auth/domain/usecases/register_use_case.dart'
    as _i697;
import 'package:situkang_app/features/auth/domain/usecases/reset_password_use_case.dart'
    as _i629;
import 'package:situkang_app/features/auth/presentation/bloc/auth_bloc.dart'
    as _i870;
import 'package:situkang_app/features/categories/data/datasources/category_remote_data_source.dart'
    as _i713;
import 'package:situkang_app/features/categories/data/repositories/category_repository_impl.dart'
    as _i39;
import 'package:situkang_app/features/categories/domain/repositories/category_repository.dart'
    as _i873;
import 'package:situkang_app/features/categories/presentation/bloc/categories_bloc.dart'
    as _i741;
import 'package:situkang_app/features/chat/data/datasources/chat_local_data_source.dart'
    as _i963;
import 'package:situkang_app/features/chat/data/datasources/chat_remote_data_source.dart'
    as _i737;
import 'package:situkang_app/features/chat/data/datasources/chat_websocket_data_source.dart'
    as _i576;
import 'package:situkang_app/features/chat/data/repositories/chat_repository_impl.dart'
    as _i515;
import 'package:situkang_app/features/chat/domain/repositories/chat_repository.dart'
    as _i641;
import 'package:situkang_app/features/chat/presentation/bloc/chat_bloc.dart'
    as _i374;
import 'package:situkang_app/features/home/data/datasources/home_local_data_source.dart'
    as _i26;
import 'package:situkang_app/features/home/data/datasources/home_remote_data_source.dart'
    as _i1062;
import 'package:situkang_app/features/home/data/repositories/home_repository_impl.dart'
    as _i477;
import 'package:situkang_app/features/home/domain/repositories/home_repository.dart'
    as _i359;
import 'package:situkang_app/features/home/presentation/bloc/home_bloc.dart'
    as _i487;
import 'package:situkang_app/features/invoice/data/datasources/invoice_remote_data_source.dart'
    as _i56;
import 'package:situkang_app/features/invoice/data/repositories/invoice_repository_impl.dart'
    as _i545;
import 'package:situkang_app/features/invoice/domain/repositories/invoice_repository.dart'
    as _i388;
import 'package:situkang_app/features/invoice/presentation/bloc/invoice_bloc.dart'
    as _i310;
import 'package:situkang_app/features/knowledge/data/datasources/knowledge_remote_data_source.dart'
    as _i632;
import 'package:situkang_app/features/knowledge/data/repositories/knowledge_repository_impl.dart'
    as _i677;
import 'package:situkang_app/features/knowledge/domain/repositories/knowledge_repository.dart'
    as _i494;
import 'package:situkang_app/features/knowledge/presentation/bloc/faq_bloc.dart'
    as _i198;
import 'package:situkang_app/features/knowledge/presentation/bloc/knowledge_bloc.dart'
    as _i574;
import 'package:situkang_app/features/notifications/data/datasources/notification_remote_data_source.dart'
    as _i167;
import 'package:situkang_app/features/notifications/data/repositories/notification_repository_impl.dart'
    as _i385;
import 'package:situkang_app/features/notifications/domain/repositories/notification_repository.dart'
    as _i247;
import 'package:situkang_app/features/notifications/presentation/bloc/notification_bloc.dart'
    as _i354;
import 'package:situkang_app/features/orders/data/datasources/order_local_data_source.dart'
    as _i525;
import 'package:situkang_app/features/orders/data/datasources/order_remote_data_source.dart'
    as _i954;
import 'package:situkang_app/features/orders/data/repositories/order_repository_impl.dart'
    as _i540;
import 'package:situkang_app/features/orders/domain/repositories/order_repository.dart'
    as _i441;
import 'package:situkang_app/features/orders/presentation/bloc/order_bloc.dart'
    as _i932;
import 'package:situkang_app/features/profile/data/datasources/profile_local_data_source.dart'
    as _i217;
import 'package:situkang_app/features/profile/data/datasources/profile_remote_data_source.dart'
    as _i577;
import 'package:situkang_app/features/profile/data/repositories/profile_repository_impl.dart'
    as _i707;
import 'package:situkang_app/features/profile/domain/repositories/profile_repository.dart'
    as _i772;
import 'package:situkang_app/features/profile/presentation/bloc/profile_bloc.dart'
    as _i753;
import 'package:situkang_app/features/purchases/data/datasources/purchase_remote_data_source.dart'
    as _i688;
import 'package:situkang_app/features/purchases/data/datasources/worker_purchase_remote_data_source.dart'
    as _i1031;
import 'package:situkang_app/features/purchases/data/repositories/purchase_repository_impl.dart'
    as _i691;
import 'package:situkang_app/features/purchases/data/repositories/worker_purchase_repository_impl.dart'
    as _i688;
import 'package:situkang_app/features/purchases/domain/repositories/purchase_repository.dart'
    as _i593;
import 'package:situkang_app/features/purchases/domain/repositories/worker_purchase_repository.dart'
    as _i1063;
import 'package:situkang_app/features/purchases/presentation/bloc/purchase_bloc.dart'
    as _i939;
import 'package:situkang_app/features/purchases/presentation/bloc/worker_purchase_bloc.dart'
    as _i991;
import 'package:situkang_app/features/rating/data/datasources/rating_remote_data_source.dart'
    as _i324;
import 'package:situkang_app/features/rating/data/datasources/worker_rating_remote_data_source.dart'
    as _i964;
import 'package:situkang_app/features/rating/data/repositories/rating_repository_impl.dart'
    as _i297;
import 'package:situkang_app/features/rating/data/repositories/worker_rating_repository_impl.dart'
    as _i129;
import 'package:situkang_app/features/rating/domain/repositories/rating_repository.dart'
    as _i565;
import 'package:situkang_app/features/rating/domain/repositories/worker_rating_repository.dart'
    as _i358;
import 'package:situkang_app/features/rating/presentation/bloc/rating_bloc.dart'
    as _i100;
import 'package:situkang_app/features/rating/presentation/bloc/worker_rating_bloc.dart'
    as _i378;
import 'package:situkang_app/features/tracking/data/datasources/location_sharing_remote_data_source.dart'
    as _i441;
import 'package:situkang_app/features/tracking/data/datasources/tracking_remote_data_source.dart'
    as _i1033;
import 'package:situkang_app/features/tracking/data/datasources/tracking_websocket_data_source.dart'
    as _i871;
import 'package:situkang_app/features/tracking/data/repositories/location_sharing_repository_impl.dart'
    as _i38;
import 'package:situkang_app/features/tracking/data/repositories/tracking_repository_impl.dart'
    as _i471;
import 'package:situkang_app/features/tracking/domain/repositories/location_sharing_repository.dart'
    as _i931;
import 'package:situkang_app/features/tracking/domain/repositories/tracking_repository.dart'
    as _i504;
import 'package:situkang_app/features/tracking/presentation/bloc/tracking_bloc.dart'
    as _i255;
import 'package:situkang_app/features/wallet/data/datasources/wallet_remote_data_source.dart'
    as _i926;
import 'package:situkang_app/features/wallet/data/repositories/wallet_repository_impl.dart'
    as _i268;
import 'package:situkang_app/features/wallet/domain/repositories/wallet_repository.dart'
    as _i412;
import 'package:situkang_app/features/wallet/presentation/bloc/wallet_bloc.dart'
    as _i772;
import 'package:situkang_app/features/worker_history/data/datasources/worker_history_remote_data_source.dart'
    as _i887;
import 'package:situkang_app/features/worker_history/data/repositories/worker_history_repository_impl.dart'
    as _i720;
import 'package:situkang_app/features/worker_history/domain/repositories/worker_history_repository.dart'
    as _i755;
import 'package:situkang_app/features/worker_history/presentation/bloc/worker_history_bloc.dart'
    as _i4;
import 'package:situkang_app/features/worker_history/presentation/bloc/worker_statistics_bloc.dart'
    as _i998;
import 'package:situkang_app/features/worker_home/data/datasources/worker_home_remote_data_source.dart'
    as _i390;
import 'package:situkang_app/features/worker_home/data/repositories/worker_home_repository_impl.dart'
    as _i955;
import 'package:situkang_app/features/worker_home/domain/repositories/worker_home_repository.dart'
    as _i854;
import 'package:situkang_app/features/worker_home/presentation/bloc/worker_home_bloc.dart'
    as _i924;
import 'package:situkang_app/features/worker_orders/data/datasources/incoming_order_remote_data_source.dart'
    as _i54;
import 'package:situkang_app/features/worker_orders/data/datasources/worker_order_remote_data_source.dart'
    as _i607;
import 'package:situkang_app/features/worker_orders/data/repositories/incoming_order_repository_impl.dart'
    as _i197;
import 'package:situkang_app/features/worker_orders/data/repositories/worker_order_repository_impl.dart'
    as _i638;
import 'package:situkang_app/features/worker_orders/domain/repositories/incoming_order_repository.dart'
    as _i673;
import 'package:situkang_app/features/worker_orders/domain/repositories/worker_order_repository.dart'
    as _i744;
import 'package:situkang_app/features/worker_orders/presentation/bloc/incoming_order_bloc.dart'
    as _i977;
import 'package:situkang_app/features/worker_orders/presentation/bloc/worker_order_bloc.dart'
    as _i913;
import 'package:situkang_app/features/worker_profile/data/datasources/worker_profile_remote_data_source.dart'
    as _i795;
import 'package:situkang_app/features/worker_profile/data/repositories/worker_profile_repository_impl.dart'
    as _i625;
import 'package:situkang_app/features/worker_profile/domain/repositories/worker_profile_repository.dart'
    as _i366;
import 'package:situkang_app/features/worker_profile/presentation/bloc/worker_profile_bloc.dart'
    as _i217;
import 'package:situkang_app/features/workers/data/datasources/worker_local_data_source.dart'
    as _i637;
import 'package:situkang_app/features/workers/data/datasources/worker_remote_data_source.dart'
    as _i1029;
import 'package:situkang_app/features/workers/data/repositories/worker_repository_impl.dart'
    as _i712;
import 'package:situkang_app/features/workers/domain/repositories/worker_repository.dart'
    as _i121;
import 'package:situkang_app/features/workers/presentation/bloc/worker_detail_bloc.dart'
    as _i84;
import 'package:situkang_app/features/workers/presentation/bloc/worker_list_bloc.dart'
    as _i747;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.singleton<_i361.Dio>(() => appModule.dio);
    gh.singleton<_i558.FlutterSecureStorage>(() => appModule.secureStorage);
    gh.lazySingleton<_i557.PushNotificationService>(
      () => _i557.PushNotificationService(),
    );
    gh.lazySingleton<_i1049.TokenStorage>(
      () => _i783.SecureTokenStorageImpl(
        storage: gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.lazySingleton<_i601.CacheManager>(() => _i68.HiveCacheManagerImpl());
    gh.lazySingleton<_i26.HomeLocalDataSource>(
      () =>
          _i26.HomeLocalDataSourceImpl(cacheManager: gh<_i601.CacheManager>()),
    );
    gh.lazySingleton<_i963.ChatLocalDataSource>(
      () =>
          _i963.ChatLocalDataSourceImpl(cacheManager: gh<_i601.CacheManager>()),
    );
    gh.lazySingleton<_i239.ConnectivityManager>(
      () => _i239.ConnectivityManagerImpl.create(),
    );
    gh.lazySingleton<_i238.WebSocketManager>(
      () => _i238.WebSocketManagerImpl.create(),
    );
    gh.lazySingleton<_i1025.AuthLocalDataSource>(
      () => _i1025.AuthLocalDataSourceImpl(
        tokenStorage: gh<_i1049.TokenStorage>(),
      ),
    );
    gh.lazySingleton<_i871.TrackingWebSocketDataSource>(
      () => _i871.TrackingWebSocketDataSourceImpl(gh<_i238.WebSocketManager>()),
    );
    gh.lazySingleton<_i576.ChatWebSocketDataSource>(
      () => _i576.ChatWebSocketDataSourceImpl(
        webSocketManager: gh<_i238.WebSocketManager>(),
      ),
    );
    gh.lazySingleton<_i217.ProfileLocalDataSource>(
      () => _i217.ProfileLocalDataSourceImpl(
        cacheManager: gh<_i601.CacheManager>(),
      ),
    );
    gh.lazySingleton<_i637.WorkerLocalDataSource>(
      () => _i637.WorkerLocalDataSourceImpl(
        cacheManager: gh<_i601.CacheManager>(),
      ),
    );
    gh.lazySingleton<_i525.OrderLocalDataSource>(
      () => _i525.OrderLocalDataSourceImpl(
        cacheManager: gh<_i601.CacheManager>(),
      ),
    );
    gh.lazySingleton<_i743.ApiClient>(
      () => _i36.DioApiClient(
        tokenStorage: gh<_i1049.TokenStorage>(),
        connectivityManager: gh<_i239.ConnectivityManager>(),
        dio: gh<_i361.Dio>(),
      ),
    );
    gh.lazySingleton<_i441.LocationSharingRemoteDataSource>(
      () => _i441.LocationSharingRemoteDataSourceImpl(
        gh<_i743.ApiClient>(),
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.lazySingleton<_i632.KnowledgeRemoteDataSource>(
      () => _i632.KnowledgeRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i926.WalletRemoteDataSource>(
      () => _i926.WalletRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i1031.WorkerPurchaseRemoteDataSource>(
      () => _i1031.WorkerPurchaseRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i1029.WorkerRemoteDataSource>(
      () => _i1029.WorkerRemoteDataSourceImpl(apiClient: gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i1033.TrackingRemoteDataSource>(
      () => _i1033.TrackingRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i887.WorkerHistoryRemoteDataSource>(
      () => _i887.WorkerHistoryRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i324.RatingRemoteDataSource>(
      () => _i324.RatingRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i1063.WorkerPurchaseRepository>(
      () => _i688.WorkerPurchaseRepositoryImpl(
        gh<_i1031.WorkerPurchaseRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i577.ProfileRemoteDataSource>(
      () => _i577.ProfileRemoteDataSourceImpl(apiClient: gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i931.LocationSharingRepository>(
      () => _i38.LocationSharingRepositoryImpl(
        gh<_i441.LocationSharingRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i755.WorkerHistoryRepository>(
      () => _i720.WorkerHistoryRepositoryImpl(
        gh<_i887.WorkerHistoryRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i56.InvoiceRemoteDataSource>(
      () => _i56.InvoiceRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i984.AuthRemoteDataSource>(
      () => _i984.AuthRemoteDataSourceImpl(apiClient: gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i713.CategoryRemoteDataSource>(
      () =>
          _i713.CategoryRemoteDataSourceImpl(apiClient: gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i167.NotificationRemoteDataSource>(
      () => _i167.NotificationRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i964.WorkerRatingRemoteDataSource>(
      () => _i964.WorkerRatingRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i358.WorkerRatingRepository>(
      () => _i129.WorkerRatingRepositoryImpl(
        gh<_i964.WorkerRatingRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i607.WorkerOrderRemoteDataSource>(
      () => _i607.WorkerOrderRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i737.ChatRemoteDataSource>(
      () => _i737.ChatRemoteDataSourceImpl(apiClient: gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i873.CategoryRepository>(
      () => _i39.CategoryRepositoryImpl(
        remoteDataSource: gh<_i713.CategoryRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i795.WorkerProfileRemoteDataSource>(
      () => _i795.WorkerProfileRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i148.OfflineActionQueue>(
      () => _i148.HiveOfflineActionQueueImpl.create(
        gh<_i743.ApiClient>(),
        gh<_i239.ConnectivityManager>(),
      ),
    );
    gh.lazySingleton<_i390.WorkerHomeRemoteDataSource>(
      () => _i390.WorkerHomeRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.factory<_i378.WorkerRatingBloc>(
      () => _i378.WorkerRatingBloc(gh<_i358.WorkerRatingRepository>()),
    );
    gh.lazySingleton<_i954.OrderRemoteDataSource>(
      () => _i954.OrderRemoteDataSourceImpl(apiClient: gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i1062.HomeRemoteDataSource>(
      () => _i1062.HomeRemoteDataSourceImpl(apiClient: gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i688.PurchaseRemoteDataSource>(
      () =>
          _i688.PurchaseRemoteDataSourceImpl(apiClient: gh<_i743.ApiClient>()),
    );
    gh.lazySingleton<_i54.IncomingOrderRemoteDataSource>(
      () => _i54.IncomingOrderRemoteDataSourceImpl(gh<_i743.ApiClient>()),
    );
    gh.factory<_i741.CategoriesBloc>(
      () => _i741.CategoriesBloc(
        categoryRepository: gh<_i873.CategoryRepository>(),
      ),
    );
    gh.lazySingleton<_i121.WorkerRepository>(
      () => _i712.WorkerRepositoryImpl(
        remoteDataSource: gh<_i1029.WorkerRemoteDataSource>(),
        localDataSource: gh<_i637.WorkerLocalDataSource>(),
      ),
    );
    gh.factory<_i4.WorkerHistoryBloc>(
      () => _i4.WorkerHistoryBloc(gh<_i755.WorkerHistoryRepository>()),
    );
    gh.factory<_i998.WorkerStatisticsBloc>(
      () => _i998.WorkerStatisticsBloc(gh<_i755.WorkerHistoryRepository>()),
    );
    gh.factory<_i84.WorkerDetailBloc>(
      () =>
          _i84.WorkerDetailBloc(workerRepository: gh<_i121.WorkerRepository>()),
    );
    gh.factory<_i747.WorkerListBloc>(
      () =>
          _i747.WorkerListBloc(workerRepository: gh<_i121.WorkerRepository>()),
    );
    gh.lazySingleton<_i412.WalletRepository>(
      () => _i268.WalletRepositoryImpl(gh<_i926.WalletRemoteDataSource>()),
    );
    gh.lazySingleton<_i388.InvoiceRepository>(
      () => _i545.InvoiceRepositoryImpl(gh<_i56.InvoiceRemoteDataSource>()),
    );
    gh.lazySingleton<_i441.OrderRepository>(
      () => _i540.OrderRepositoryImpl(
        remoteDataSource: gh<_i954.OrderRemoteDataSource>(),
        localDataSource: gh<_i525.OrderLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i641.ChatRepository>(
      () => _i515.ChatRepositoryImpl(
        remoteDataSource: gh<_i737.ChatRemoteDataSource>(),
        webSocketDataSource: gh<_i576.ChatWebSocketDataSource>(),
        localDataSource: gh<_i963.ChatLocalDataSource>(),
        tokenStorage: gh<_i1049.TokenStorage>(),
        connectivityManager: gh<_i239.ConnectivityManager>(),
      ),
    );
    gh.lazySingleton<_i565.RatingRepository>(
      () => _i297.RatingRepositoryImpl(gh<_i324.RatingRemoteDataSource>()),
    );
    gh.lazySingleton<_i494.KnowledgeRepository>(
      () =>
          _i677.KnowledgeRepositoryImpl(gh<_i632.KnowledgeRemoteDataSource>()),
    );
    gh.lazySingleton<_i504.TrackingRepository>(
      () => _i471.TrackingRepositoryImpl(
        remoteDataSource: gh<_i1033.TrackingRemoteDataSource>(),
        webSocketDataSource: gh<_i871.TrackingWebSocketDataSource>(),
        webSocketManager: gh<_i238.WebSocketManager>(),
        tokenStorage: gh<_i1049.TokenStorage>(),
        connectivityManager: gh<_i239.ConnectivityManager>(),
      ),
    );
    gh.lazySingleton<_i854.WorkerHomeRepository>(
      () => _i955.WorkerHomeRepositoryImpl(
        gh<_i390.WorkerHomeRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i772.ProfileRepository>(
      () => _i707.ProfileRepositoryImpl(
        remoteDataSource: gh<_i577.ProfileRemoteDataSource>(),
        localDataSource: gh<_i217.ProfileLocalDataSource>(),
      ),
    );
    gh.factory<_i991.WorkerPurchaseBloc>(
      () => _i991.WorkerPurchaseBloc(gh<_i1063.WorkerPurchaseRepository>()),
    );
    gh.factory<_i753.ProfileBloc>(
      () => _i753.ProfileBloc(profileRepository: gh<_i772.ProfileRepository>()),
    );
    gh.lazySingleton<_i593.PurchaseRepository>(
      () => _i691.PurchaseRepositoryImpl(
        remoteDataSource: gh<_i688.PurchaseRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i746.AuthRepository>(
      () => _i984.AuthRepositoryImpl(
        remoteDataSource: gh<_i984.AuthRemoteDataSource>(),
        localDataSource: gh<_i1025.AuthLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i366.WorkerProfileRepository>(
      () => _i625.WorkerProfileRepositoryImpl(
        gh<_i795.WorkerProfileRemoteDataSource>(),
      ),
    );
    gh.factory<_i924.WorkerHomeBloc>(
      () => _i924.WorkerHomeBloc(gh<_i854.WorkerHomeRepository>()),
    );
    gh.factory<_i217.WorkerProfileBloc>(
      () => _i217.WorkerProfileBloc(gh<_i366.WorkerProfileRepository>()),
    );
    gh.lazySingleton<_i822.ForgotPasswordUseCase>(
      () => _i822.ForgotPasswordUseCase(gh<_i746.AuthRepository>()),
    );
    gh.lazySingleton<_i127.LoginUseCase>(
      () => _i127.LoginUseCase(gh<_i746.AuthRepository>()),
    );
    gh.lazySingleton<_i1010.LogoutUseCase>(
      () => _i1010.LogoutUseCase(gh<_i746.AuthRepository>()),
    );
    gh.lazySingleton<_i250.RefreshTokenUseCase>(
      () => _i250.RefreshTokenUseCase(gh<_i746.AuthRepository>()),
    );
    gh.lazySingleton<_i697.RegisterUseCase>(
      () => _i697.RegisterUseCase(gh<_i746.AuthRepository>()),
    );
    gh.lazySingleton<_i629.ResetPasswordUseCase>(
      () => _i629.ResetPasswordUseCase(gh<_i746.AuthRepository>()),
    );
    gh.lazySingleton<_i744.WorkerOrderRepository>(
      () => _i638.WorkerOrderRepositoryImpl(
        gh<_i607.WorkerOrderRemoteDataSource>(),
      ),
    );
    gh.factory<_i100.RatingBloc>(
      () => _i100.RatingBloc(gh<_i565.RatingRepository>()),
    );
    gh.factory<_i374.ChatBloc>(
      () => _i374.ChatBloc(chatRepository: gh<_i641.ChatRepository>()),
    );
    gh.lazySingleton<_i247.NotificationRepository>(
      () => _i385.NotificationRepositoryImpl(
        gh<_i167.NotificationRemoteDataSource>(),
      ),
    );
    gh.factory<_i772.WalletBloc>(
      () => _i772.WalletBloc(gh<_i412.WalletRepository>()),
    );
    gh.factory<_i913.WorkerOrderBloc>(
      () => _i913.WorkerOrderBloc(gh<_i744.WorkerOrderRepository>()),
    );
    gh.factory<_i932.OrderBloc>(
      () => _i932.OrderBloc(orderRepository: gh<_i441.OrderRepository>()),
    );
    gh.factory<_i198.FaqBloc>(
      () => _i198.FaqBloc(gh<_i494.KnowledgeRepository>()),
    );
    gh.factory<_i574.KnowledgeBloc>(
      () => _i574.KnowledgeBloc(gh<_i494.KnowledgeRepository>()),
    );
    gh.lazySingleton<_i359.HomeRepository>(
      () => _i477.HomeRepositoryImpl(
        remoteDataSource: gh<_i1062.HomeRemoteDataSource>(),
        localDataSource: gh<_i26.HomeLocalDataSource>(),
      ),
    );
    gh.factory<_i255.TrackingBloc>(
      () => _i255.TrackingBloc(
        trackingRepository: gh<_i504.TrackingRepository>(),
      ),
    );
    gh.factory<_i487.HomeBloc>(
      () => _i487.HomeBloc(homeRepository: gh<_i359.HomeRepository>()),
    );
    gh.lazySingleton<_i673.IncomingOrderRepository>(
      () => _i197.IncomingOrderRepositoryImpl(
        gh<_i54.IncomingOrderRemoteDataSource>(),
      ),
    );
    gh.factory<_i310.InvoiceBloc>(
      () => _i310.InvoiceBloc(gh<_i388.InvoiceRepository>()),
    );
    gh.factory<_i870.AuthBloc>(
      () => _i870.AuthBloc(
        loginUseCase: gh<_i127.LoginUseCase>(),
        registerUseCase: gh<_i697.RegisterUseCase>(),
        logoutUseCase: gh<_i1010.LogoutUseCase>(),
        refreshTokenUseCase: gh<_i250.RefreshTokenUseCase>(),
        forgotPasswordUseCase: gh<_i822.ForgotPasswordUseCase>(),
        resetPasswordUseCase: gh<_i629.ResetPasswordUseCase>(),
      ),
    );
    gh.factory<_i939.PurchaseBloc>(
      () => _i939.PurchaseBloc(
        purchaseRepository: gh<_i593.PurchaseRepository>(),
        webSocketManager: gh<_i238.WebSocketManager>(),
      ),
    );
    gh.factory<_i354.NotificationBloc>(
      () => _i354.NotificationBloc(
        gh<_i247.NotificationRepository>(),
        gh<_i238.WebSocketManager>(),
      ),
    );
    gh.factory<_i977.IncomingOrderBloc>(
      () => _i977.IncomingOrderBloc(gh<_i673.IncomingOrderRepository>()),
    );
    return this;
  }
}

class _$AppModule extends _i369.AppModule {}
