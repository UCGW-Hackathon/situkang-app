import 'package:injectable/injectable.dart';
import '../../../../core/storage/cache_manager.dart';
import '../models/user_model.dart';

/// Local data source for caching user profile data.
///
/// Uses [CacheManager] to store and retrieve profile data for
/// offline access and cache-first read strategy.
abstract class ProfileLocalDataSource {
  /// Retrieves the cached user profile, or null if not cached or expired.
  Future<UserModel?> getCachedProfile();

  /// Caches the user profile data.
  Future<void> cacheProfile(UserModel userModel);

  /// Clears the cached profile data.
  Future<void> clearCache();
}

/// Implementation of [ProfileLocalDataSource] using [CacheManager].
@LazySingleton(as: ProfileLocalDataSource)
class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  const ProfileLocalDataSourceImpl({required this.cacheManager});

  final CacheManager cacheManager;

  /// Cache key for the user profile.
  static const String _profileCacheKey = 'user_profile';

  @override
  Future<UserModel?> getCachedProfile() async {
    final cachedData = await cacheManager.get<Map<String, dynamic>>(
      _profileCacheKey,
    );

    if (cachedData == null) return null;
    return UserModel.fromJson(cachedData);
  }

  @override
  Future<void> cacheProfile(UserModel userModel) async {
    await cacheManager.put(_profileCacheKey, userModel.toJson());
  }

  @override
  Future<void> clearCache() async {
    await cacheManager.invalidate(_profileCacheKey);
  }
}
