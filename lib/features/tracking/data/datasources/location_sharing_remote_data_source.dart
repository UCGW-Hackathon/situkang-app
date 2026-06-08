import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/worker_location_model.dart';

abstract class LocationSharingRemoteDataSource {
  Future<void> startSharing(String orderId);
  Future<void> stopSharing();
  Future<void> sendLocationUpdate(WorkerLocationModel location);
}

@LazySingleton(as: LocationSharingRemoteDataSource)
class LocationSharingRemoteDataSourceImpl implements LocationSharingRemoteDataSource {
  LocationSharingRemoteDataSourceImpl(this.apiClient, this.secureStorage);

  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;
  
  WebSocketChannel? _channel;
  String? _currentOrderId;
  
  // Note: in a real app, URL should come from env
  final String _wsBaseUrl = '${AppConstants.webSocketUrl}/tracking';

  @override
  Future<void> startSharing(String orderId) async {
    _currentOrderId = orderId;
    final token = await secureStorage.read(key: 'auth_token');
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    _channel = WebSocketChannel.connect(
      Uri.parse('$_wsBaseUrl/$orderId?token=$token'),
    );
  }

  @override
  Future<void> stopSharing() async {
    await _channel?.sink.close();
    _channel = null;
    _currentOrderId = null;
  }

  @override
  Future<void> sendLocationUpdate(WorkerLocationModel location) async {
    if (_channel == null || _currentOrderId == null) {
      throw Exception('Sharing not started');
    }

    final data = {
      'type': 'location_update',
      'order_id': _currentOrderId,
      'location': location.toJson(),
    };

    _channel!.sink.add(jsonEncode(data));
  }
}
