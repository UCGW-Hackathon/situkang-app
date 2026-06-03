/// Abstract cache manager interface for structured data caching.
///
/// Provides a TTL-based caching mechanism for offline viewing support.
/// Default TTL is 7 days as defined in [AppConstants.defaultCacheTtl].
abstract class CacheManager {
  /// Stores [data] under the given [key] with an optional [ttl].
  ///
  /// If [ttl] is not provided, the default TTL of 7 days is used.
  /// Overwrites any existing entry for the same key.
  Future<void> put(String key, dynamic data, {Duration? ttl});

  /// Retrieves the cached value for [key], or `null` if not found or expired.
  ///
  /// Automatically checks expiration — returns `null` for expired entries.
  Future<T?> get<T>(String key);

  /// Removes the cached entry for [key].
  ///
  /// No-op if the key does not exist.
  Future<void> invalidate(String key);

  /// Clears all cached entries across all feature domains.
  Future<void> clearAll();

  /// Returns `true` if the entry for [key] has exceeded its TTL.
  ///
  /// Returns `true` if the key does not exist (treated as expired).
  Future<bool> isExpired(String key);
}
