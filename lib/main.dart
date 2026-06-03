import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/network/offline_action_queue.dart';
import 'core/services/push_notification_service.dart';
import 'core/storage/cache_manager.dart';
import 'core/storage/hive_cache_manager_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Initialize dependency injection
  await configureDependencies();
  
  // Initialize CacheManager
  final cacheManager = getIt<CacheManager>();
  if (cacheManager is HiveCacheManagerImpl) {
    await cacheManager.init();
  }

  final offlineQueue = getIt<OfflineActionQueue>();
  if (offlineQueue is HiveOfflineActionQueueImpl) {
    await offlineQueue.init();
  }
  
  try {
    await getIt<PushNotificationService>().initialize();
  } catch (_) {
    // Ignore initialization errors for PushNotificationService when running without firebase config
  }
  
  // Initialize date formatting for ID locale
  await initializeDateFormatting('id_ID', null);
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SitukangApp());
}
