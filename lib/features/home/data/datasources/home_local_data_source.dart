import 'package:injectable/injectable.dart';
import '../../../../core/storage/cache_manager.dart';
import '../models/home_data_model.dart';

/// Local data source for caching home screen data.
///
/// Uses [CacheManager] to store and retrieve home data for
/// offline access and cache-first read strategy.
abstract class HomeLocalDataSource {
  /// Retrieves the cached home data, or null if not cached or expired.
  Future<HomeDataModel?> getCachedHomeData();

  /// Caches the home screen data.
  Future<void> cacheHomeData(HomeDataModel homeData);

  /// Clears the cached home data.
  Future<void> clearCache();
}

/// Implementation of [HomeLocalDataSource] using [CacheManager].
@LazySingleton(as: HomeLocalDataSource)
class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  const HomeLocalDataSourceImpl({required this.cacheManager});

  final CacheManager cacheManager;

  /// Cache key for the home screen data.
  static const String _homeCacheKey = 'home_data';

  @override
  Future<HomeDataModel?> getCachedHomeData() async {
    final cachedData = await cacheManager.get<dynamic>(
      _homeCacheKey,
    );

    if (cachedData == null) return null;
    try {
      final map = Map<String, dynamic>.from(cachedData as Map);
      return HomeDataModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheHomeData(HomeDataModel homeData) async {
    await cacheManager.put(_homeCacheKey, homeData.toJson());
  }

  @override
  Future<void> clearCache() async {
    await cacheManager.invalidate(_homeCacheKey);
  }
}
