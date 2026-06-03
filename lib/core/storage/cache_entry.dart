/// A cache entry that wraps stored data with metadata for TTL management.
///
/// Each entry records when it was cached and how long it should remain valid.
class CacheEntry {
  CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.ttlMs,
  });

  /// Deserializes a [CacheEntry] from a Map retrieved from Hive.
  factory CacheEntry.fromMap(Map<dynamic, dynamic> map) {
    return CacheEntry(
      data: map['data'],
      cachedAt: map['cachedAt'] as int,
      ttlMs: map['ttlMs'] as int,
    );
  }

  /// The cached data payload.
  final dynamic data;

  /// Timestamp (milliseconds since epoch) when the entry was stored.
  final int cachedAt;

  /// Time-to-live in milliseconds for this entry.
  final int ttlMs;

  /// Whether this entry has exceeded its TTL based on the current time.
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - cachedAt > ttlMs;
  }

  /// The expiration timestamp in milliseconds since epoch.
  int get expiresAt => cachedAt + ttlMs;

  /// Serializes this entry to a Map for Hive storage.
  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'cachedAt': cachedAt,
      'ttlMs': ttlMs,
    };
  }
}
