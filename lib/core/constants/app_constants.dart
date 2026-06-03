/// Core application constants for the SITUKANG app.
///
/// Contains base URLs, timeouts, pagination defaults, and other
/// app-wide configuration values.
class AppConstants {
  AppConstants._();

  // ─── Base URLs ───────────────────────────────────────────────────────────────

  /// Base URL for REST API calls.
  /// Override via environment config for staging/dev.
  static const String baseUrl = 'https://xryz-gcw-situkang.hf.space/v1';

  /// WebSocket base URL for real-time features (tracking, chat).
  static const String webSocketUrl = 'wss://xryz-gcw-situkang.hf.space/v1/ws';

  // ─── Timeouts ────────────────────────────────────────────────────────────────

  /// HTTP connection timeout in milliseconds.
  static const Duration connectTimeout = Duration(seconds: 30);

  /// HTTP receive (response) timeout in milliseconds.
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Buffer time before token expiry to trigger a proactive refresh.
  static const Duration tokenRefreshBuffer = Duration(seconds: 60);

  // ─── Retry ───────────────────────────────────────────────────────────────────

  /// Maximum number of automatic retries for failed network requests.
  static const int maxRetries = 3;

  // ─── Pagination ──────────────────────────────────────────────────────────────

  /// Default page size for list endpoints (orders, workers, etc.).
  static const int defaultPageSize = 10;

  /// Page size for chat message history.
  static const int chatPageSize = 50;

  /// Maximum number of chat messages to load.
  static const int chatMaxMessages = 100;

  // ─── WebSocket ───────────────────────────────────────────────────────────────

  /// Initial reconnection delay for WebSocket.
  static const Duration wsReconnectInitialDelay = Duration(seconds: 1);

  /// Maximum reconnection delay (cap) for WebSocket exponential backoff.
  static const Duration wsReconnectMaxDelay = Duration(seconds: 60);

  /// Maximum number of WebSocket reconnection attempts.
  static const int wsMaxReconnectAttempts = 10;

  /// WebSocket heartbeat/ping interval.
  static const Duration wsHeartbeatInterval = Duration(seconds: 30);

  // ─── Polling ─────────────────────────────────────────────────────────────────

  /// Fallback polling interval when WebSocket is disconnected.
  static const Duration trackingPollInterval = Duration(seconds: 10);

  // ─── File Upload ─────────────────────────────────────────────────────────────

  /// Maximum avatar file size in bytes (5 MB).
  static const int maxAvatarFileSize = 5 * 1024 * 1024;

  /// Maximum photo file size in bytes (5 MB).
  static const int maxPhotoFileSize = 5 * 1024 * 1024;

  /// Maximum receipt/cover photo file size in bytes (10 MB).
  static const int maxReceiptFileSize = 10 * 1024 * 1024;

  /// Maximum chat image file size in bytes (10 MB).
  static const int maxChatImageFileSize = 10 * 1024 * 1024;

  /// Maximum number of photos per order.
  static const int maxOrderPhotos = 5;

  /// Maximum number of certificate files for verification.
  static const int maxCertificateFiles = 5;

  /// Allowed image file extensions.
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];

  // ─── Cache ───────────────────────────────────────────────────────────────────

  /// Default cache TTL for offline viewing.
  static const Duration defaultCacheTtl = Duration(days: 7);

  // ─── Offline Queue ───────────────────────────────────────────────────────────

  /// Maximum number of queued offline actions.
  static const int maxOfflineQueueSize = 50;

  /// Maximum retries per offline action.
  static const int maxOfflineActionRetries = 3;

  // ─── Booking ─────────────────────────────────────────────────────────────────

  /// Fixed booking fee in Rupiah.
  static const int bookingFee = 2000;

  // ─── Worker Location ─────────────────────────────────────────────────────────

  /// Worker location update interval while en route.
  static const Duration locationUpdateInterval = Duration(seconds: 5);

  /// Default search radius in kilometers for nearby workers.
  static const double defaultSearchRadiusKm = 10.0;

  // ─── Order ───────────────────────────────────────────────────────────────────

  /// Countdown timer duration for incoming order auto-rejection (seconds).
  static const Duration incomingOrderCountdown = Duration(seconds: 30);
}
