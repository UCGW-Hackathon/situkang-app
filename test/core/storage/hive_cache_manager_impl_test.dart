import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:situkang_app/core/storage/cache_entry.dart';
import 'package:situkang_app/core/storage/hive_cache_manager_impl.dart';

void main() {
  late HiveCacheManagerImpl cacheManager;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    cacheManager = HiveCacheManagerImpl();
    await cacheManager.init(path: tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CacheManager - put and get', () {
    test('should store and retrieve a string value', () async {
      await cacheManager.put('test_key', 'test_value');
      final result = await cacheManager.get<String>('test_key');
      expect(result, equals('test_value'));
    });

    test('should store and retrieve a Map value', () async {
      final data = {'name': 'John', 'age': 30};
      await cacheManager.put('user_data', data);
      final result = await cacheManager.get<Map>('user_data');
      expect(result, equals(data));
    });

    test('should store and retrieve a List value', () async {
      final data = [1, 2, 3, 4, 5];
      await cacheManager.put('numbers', data);
      final result = await cacheManager.get<List>('numbers');
      expect(result, equals(data));
    });

    test('should overwrite existing entry with same key', () async {
      await cacheManager.put('key', 'value1');
      await cacheManager.put('key', 'value2');
      final result = await cacheManager.get<String>('key');
      expect(result, equals('value2'));
    });

    test('should return null for non-existent key', () async {
      final result = await cacheManager.get<String>('non_existent');
      expect(result, isNull);
    });
  });

  group('CacheManager - TTL and expiration', () {
    test('should use default TTL of 7 days when not specified', () async {
      await cacheManager.put('key', 'value');
      final isExp = await cacheManager.isExpired('key');
      expect(isExp, isFalse);
    });

    test('should return null for expired entries', () async {
      // Store with a TTL of 0 milliseconds (immediately expired)
      await cacheManager.put('expired_key', 'value', ttl: Duration.zero);

      // Wait a tiny bit to ensure expiration
      await Future.delayed(const Duration(milliseconds: 2));

      final result = await cacheManager.get<String>('expired_key');
      expect(result, isNull);
    });

    test('should report expired for entries past TTL', () async {
      await cacheManager.put('expired_key', 'value', ttl: Duration.zero);
      await Future.delayed(const Duration(milliseconds: 2));

      final isExp = await cacheManager.isExpired('expired_key');
      expect(isExp, isTrue);
    });

    test('should report not expired for entries within TTL', () async {
      await cacheManager.put('fresh_key', 'value',
          ttl: const Duration(hours: 1));
      final isExp = await cacheManager.isExpired('fresh_key');
      expect(isExp, isFalse);
    });

    test('should report expired for non-existent key', () async {
      final isExp = await cacheManager.isExpired('does_not_exist');
      expect(isExp, isTrue);
    });

    test('should respect custom TTL', () async {
      await cacheManager.put('custom_ttl', 'value',
          ttl: const Duration(days: 1));
      final result = await cacheManager.get<String>('custom_ttl');
      expect(result, equals('value'));
    });
  });

  group('CacheManager - invalidate', () {
    test('should remove entry for given key', () async {
      await cacheManager.put('to_remove', 'value');
      await cacheManager.invalidate('to_remove');
      final result = await cacheManager.get<String>('to_remove');
      expect(result, isNull);
    });

    test('should not throw when invalidating non-existent key', () async {
      await expectLater(
        cacheManager.invalidate('non_existent'),
        completes,
      );
    });
  });

  group('CacheManager - clearAll', () {
    test('should remove all entries from main cache', () async {
      await cacheManager.put('key1', 'value1');
      await cacheManager.put('key2', 'value2');
      await cacheManager.put('key3', 'value3');

      await cacheManager.clearAll();

      expect(await cacheManager.get<String>('key1'), isNull);
      expect(await cacheManager.get<String>('key2'), isNull);
      expect(await cacheManager.get<String>('key3'), isNull);
    });
  });

  group('CacheManager - feature box operations', () {
    test('should store and retrieve from feature-specific box', () async {
      await cacheManager.putInBox(
          'cache_workers', 'worker_1', {'name': 'Budi'});
      final result =
          await cacheManager.getFromBox<Map>('cache_workers', 'worker_1');
      expect(result, equals({'name': 'Budi'}));
    });

    test('should return null for expired entry in feature box', () async {
      await cacheManager.putInBox(
        'cache_orders',
        'order_1',
        {'status': 'pending'},
        ttl: Duration.zero,
      );
      await Future.delayed(const Duration(milliseconds: 2));

      final result =
          await cacheManager.getFromBox<Map>('cache_orders', 'order_1');
      expect(result, isNull);
    });

    test('should invalidate entry in feature box', () async {
      await cacheManager.putInBox('cache_chat', 'msg_1', 'hello');
      await cacheManager.invalidateInBox('cache_chat', 'msg_1');
      final result =
          await cacheManager.getFromBox<String>('cache_chat', 'msg_1');
      expect(result, isNull);
    });

    test('should clear all entries in a specific feature box', () async {
      await cacheManager.putInBox('cache_profile', 'key1', 'val1');
      await cacheManager.putInBox('cache_profile', 'key2', 'val2');

      await cacheManager.clearBox('cache_profile');

      expect(
          await cacheManager.getFromBox<String>('cache_profile', 'key1'), isNull);
      expect(
          await cacheManager.getFromBox<String>('cache_profile', 'key2'), isNull);
    });

    test('clearAll should also clear feature boxes', () async {
      await cacheManager.putInBox('cache_workers', 'w1', 'data');
      await cacheManager.put('main_key', 'main_data');

      await cacheManager.clearAll();

      expect(await cacheManager.get<String>('main_key'), isNull);
      expect(
          await cacheManager.getFromBox<String>('cache_workers', 'w1'), isNull);
    });
  });

  group('CacheEntry', () {
    test('should serialize and deserialize correctly', () {
      final entry = CacheEntry(
        data: {'key': 'value'},
        cachedAt: 1000000,
        ttlMs: 604800000, // 7 days
      );

      final map = entry.toMap();
      final restored = CacheEntry.fromMap(map);

      expect(restored.data, equals({'key': 'value'}));
      expect(restored.cachedAt, equals(1000000));
      expect(restored.ttlMs, equals(604800000));
    });

    test('expiresAt should be cachedAt + ttlMs', () {
      final entry = CacheEntry(
        data: 'test',
        cachedAt: 1000,
        ttlMs: 5000,
      );
      expect(entry.expiresAt, equals(6000));
    });

    test('isExpired should return true when past TTL', () {
      final entry = CacheEntry(
        data: 'test',
        cachedAt: 0, // epoch start
        ttlMs: 1, // 1ms TTL — definitely expired
      );
      expect(entry.isExpired, isTrue);
    });

    test('isExpired should return false when within TTL', () {
      final entry = CacheEntry(
        data: 'test',
        cachedAt: DateTime.now().millisecondsSinceEpoch,
        ttlMs: 3600000, // 1 hour
      );
      expect(entry.isExpired, isFalse);
    });
  });
}
