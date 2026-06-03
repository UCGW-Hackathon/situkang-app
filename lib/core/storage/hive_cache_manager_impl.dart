import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_constants.dart';
import 'cache_entry.dart';
import 'cache_manager.dart';

/// Hive-based implementation of [CacheManager].
///
/// Uses separate Hive boxes for each feature domain to keep data organized
/// and allow selective clearing. All entries are stored as Maps containing
/// the data payload plus metadata (timestamp, TTL) for expiration checks.
@LazySingleton(as: CacheManager)
class HiveCacheManagerImpl implements CacheManager {
  /// The main cache box name used for general caching.
  static const String _cacheBoxName = 'situkang_cache';

  /// Feature-specific box names for domain isolation.
  static const List<String> featureBoxNames = [
    'cache_auth',
    'cache_home',
    'cache_categories',
    'cache_workers',
    'cache_orders',
    'cache_tracking',
    'cache_purchases',
    'cache_chat',
    'cache_invoice',
    'cache_rating',
    'cache_notifications',
    'cache_profile',
    'cache_worker_home',
    'cache_worker_orders',
    'cache_worker_profile',
    'cache_wallet',
  ];

  late Box<Map<dynamic, dynamic>> _cacheBox;

  /// Initializes Hive and opens all required boxes.
  ///
  /// Must be called once during app startup before using any cache operations.
  /// If [path] is provided, Hive is initialized with that directory path
  /// (useful for testing). Otherwise, uses `Hive.initFlutter()` for
  /// platform-appropriate initialization.
  Future<void> init({String? path}) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    _cacheBox = await Hive.openBox<Map<dynamic, dynamic>>(_cacheBoxName);

    // Open feature-specific boxes for domain isolation
    for (final boxName in featureBoxNames) {
      await Hive.openBox<Map<dynamic, dynamic>>(boxName);
    }
  }

  @override
  Future<void> put(String key, dynamic data, {Duration? ttl}) async {
    final effectiveTtl = ttl ?? AppConstants.defaultCacheTtl;
    final entry = CacheEntry(
      data: data,
      cachedAt: DateTime.now().millisecondsSinceEpoch,
      ttlMs: effectiveTtl.inMilliseconds,
    );
    await _cacheBox.put(key, entry.toMap());
  }

  @override
  Future<T?> get<T>(String key) async {
    final raw = _cacheBox.get(key);
    if (raw == null) return null;

    final entry = CacheEntry.fromMap(raw);
    if (entry.isExpired) {
      // Auto-invalidate expired entries on access
      await _cacheBox.delete(key);
      return null;
    }

    return entry.data as T?;
  }

  @override
  Future<void> invalidate(String key) async {
    await _cacheBox.delete(key);
  }

  @override
  Future<void> clearAll() async {
    await _cacheBox.clear();

    // Also clear all feature-specific boxes
    for (final boxName in featureBoxNames) {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box<Map<dynamic, dynamic>>(boxName);
        await box.clear();
      }
    }
  }

  @override
  Future<bool> isExpired(String key) async {
    final raw = _cacheBox.get(key);
    if (raw == null) return true;

    final entry = CacheEntry.fromMap(raw);
    return entry.isExpired;
  }

  /// Stores data in a feature-specific box.
  ///
  /// Use this for domain-isolated caching (e.g., caching worker data
  /// separately from order data).
  Future<void> putInBox(
    String boxName,
    String key,
    dynamic data, {
    Duration? ttl,
  }) async {
    final effectiveTtl = ttl ?? AppConstants.defaultCacheTtl;
    final entry = CacheEntry(
      data: data,
      cachedAt: DateTime.now().millisecondsSinceEpoch,
      ttlMs: effectiveTtl.inMilliseconds,
    );

    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Map<dynamic, dynamic>>(boxName);
    }
    final box = Hive.box<Map<dynamic, dynamic>>(boxName);
    await box.put(key, entry.toMap());
  }

  /// Retrieves data from a feature-specific box.
  ///
  /// Returns `null` if the key doesn't exist or the entry is expired.
  Future<T?> getFromBox<T>(String boxName, String key) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Map<dynamic, dynamic>>(boxName);
    }
    final box = Hive.box<Map<dynamic, dynamic>>(boxName);
    final raw = box.get(key);
    if (raw == null) return null;

    final entry = CacheEntry.fromMap(raw);
    if (entry.isExpired) {
      await box.delete(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Invalidates a key in a feature-specific box.
  Future<void> invalidateInBox(String boxName, String key) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Map<dynamic, dynamic>>(boxName);
    }
    final box = Hive.box<Map<dynamic, dynamic>>(boxName);
    await box.delete(key);
  }

  /// Clears all entries in a specific feature box.
  Future<void> clearBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Map<dynamic, dynamic>>(boxName);
    }
    final box = Hive.box<Map<dynamic, dynamic>>(boxName);
    await box.clear();
  }
}
