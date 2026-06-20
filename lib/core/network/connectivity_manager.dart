/// Connectivity management for the SITUKANG app.
///
/// Provides real-time connectivity status monitoring via a stream,
/// detecting network changes within 3 seconds as required by the spec.
///
/// Requirements: 26.1, 26.3
library;

import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';

/// Represents the current network connectivity status.
enum ConnectivityStatus {
  /// Device has network connectivity.
  online,

  /// Device has no network connectivity.
  offline,
}

/// Abstract interface for monitoring network connectivity.
///
/// Exposes a [statusStream] that emits [ConnectivityStatus] changes,
/// a [currentStatus] getter for the last known status, and an [isOnline]
/// convenience getter.
abstract class ConnectivityManager {
  /// A stream that emits [ConnectivityStatus] whenever connectivity changes.
  ///
  /// Only emits when the status actually changes (no duplicate emissions).
  Stream<ConnectivityStatus> get statusStream;

  /// The current (last known) connectivity status.
  ConnectivityStatus get currentStatus;

  /// Convenience getter that returns `true` if [currentStatus] is [ConnectivityStatus.online].
  bool get isOnline;

  /// Manually triggers a connectivity check and updates the status.
  ///
  /// Returns the detected [ConnectivityStatus].
  Future<ConnectivityStatus> checkConnectivity();

  /// Reports a network error detected externally (e.g., from an interceptor).
  ///
  /// This allows the [ConnectivityInterceptor] to immediately notify the
  /// manager of a connectivity issue without waiting for the next periodic check.
  void reportConnectivityError();

  /// Reports a successful network operation detected externally.
  ///
  /// This allows interceptors or other components to immediately notify the
  /// manager that connectivity has been restored.
  void reportConnectivitySuccess();

  /// Disposes resources (timers, stream controllers).
  void dispose();
}

/// Implementation of [ConnectivityManager] using periodic connectivity checks.
///
/// Performs lightweight DNS lookups to detect connectivity changes.
/// The check interval is set to 3 seconds to meet the requirement of
/// detecting connectivity changes within 3 seconds (Requirement 26.1).
///
/// Additionally, external components (like interceptors) can report
/// connectivity errors/successes for immediate status updates without
/// waiting for the next periodic check.
@LazySingleton(as: ConnectivityManager)
class ConnectivityManagerImpl implements ConnectivityManager {
  /// Creates a [ConnectivityManagerImpl].
  ///
  /// [checkInterval] controls how often periodic checks run (default: 3 seconds).
  /// [lookupHost] is the hostname used for DNS lookups.
  ConnectivityManagerImpl({
    Duration checkInterval = const Duration(seconds: 3),
    String lookupHost = 'situkang-api-20260616.eastasia.azurecontainer.io',
  }) : _checkInterval = checkInterval,
       _lookupHost = lookupHost {
    _startPeriodicCheck();
  }

  @factoryMethod
  // ignore: prefer_constructors_over_static_methods
  static ConnectivityManagerImpl create() => ConnectivityManagerImpl();

  final Duration _checkInterval;
  final String _lookupHost;

  ConnectivityStatus _currentStatus = ConnectivityStatus.online;
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();
  Timer? _periodicTimer;

  @override
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  @override
  ConnectivityStatus get currentStatus => _currentStatus;

  @override
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    final status = await _performCheck();
    _updateStatus(status);
    return status;
  }

  @override
  void reportConnectivityError() {
    _updateStatus(ConnectivityStatus.offline);
  }

  @override
  void reportConnectivitySuccess() {
    _updateStatus(ConnectivityStatus.online);
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _statusController.close();
  }

  /// Starts the periodic connectivity check timer.
  void _startPeriodicCheck() {
    // Perform an initial check immediately.
    checkConnectivity();

    _periodicTimer = Timer.periodic(_checkInterval, (_) {
      checkConnectivity();
    });
  }

  /// Performs a lightweight DNS lookup to determine connectivity.
  ///
  /// Uses [InternetAddress.lookup] which is fast and doesn't require
  /// a full HTTP connection. Falls back to offline on [SocketException]
  /// or any other error.
  Future<ConnectivityStatus> _performCheck() async {
    try {
      final result = await InternetAddress.lookup(
        _lookupHost,
      ).timeout(const Duration(seconds: 2));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return ConnectivityStatus.online;
      }
      return ConnectivityStatus.offline;
    } on SocketException {
      return ConnectivityStatus.offline;
    } on TimeoutException {
      return ConnectivityStatus.offline;
    } on Object {
      return ConnectivityStatus.offline;
    }
  }

  /// Updates the current status and emits to the stream if changed.
  ///
  /// Only emits when the status actually changes to avoid duplicate events.
  void _updateStatus(ConnectivityStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      if (!_statusController.isClosed) {
        _statusController.add(newStatus);
      }
    }
  }
}
