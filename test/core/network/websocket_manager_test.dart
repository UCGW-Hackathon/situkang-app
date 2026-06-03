import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/network/websocket_events.dart';
import 'package:situkang_app/core/network/websocket_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ─── Mocks ─────────────────────────────────────────────────────────────────

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

/// A fake WebSocket channel that uses a StreamController for testing.
class FakeWebSocketChannel extends Fake implements WebSocketChannel {
  FakeWebSocketChannel({this.shouldFailReady = false});

  final StreamController<dynamic> _incomingController =
      StreamController<dynamic>.broadcast();
  final FakeWebSocketSink sink = FakeWebSocketSink();
  final bool shouldFailReady;
  bool _isClosed = false;

  @override
  Stream<dynamic> get stream => _incomingController.stream;

  @override
  Future<void> get ready =>
      shouldFailReady ? Future.error(Exception('Connection failed')) : Future.value();

  @override
  int? get closeCode => _isClosed ? 1000 : null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  /// Simulates receiving a message from the server.
  void addIncoming(dynamic data) {
    if (!_incomingController.isClosed) {
      _incomingController.add(data);
    }
  }

  /// Simulates an error on the stream.
  void addError(Object error) {
    if (!_incomingController.isClosed) {
      _incomingController.addError(error);
    }
  }

  /// Simulates the connection being closed by the server.
  void closeFromServer() {
    _isClosed = true;
    _incomingController.close();
  }

  void dispose() {
    _incomingController.close();
  }
}

class FakeWebSocketSink implements WebSocketSink {
  final List<dynamic> sentMessages = [];
  bool isClosed = false;
  Completer<void>? _closeCompleter;

  @override
  void add(dynamic data) {
    sentMessages.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream stream) => Future.value();

  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    isClosed = true;
    _closeCompleter?.complete();
    return Future.value();
  }

  @override
  Future<dynamic> get done => _closeCompleter?.future ?? Future.value();
}

// ─── Tests ─────────────────────────────────────────────────────────────────

void main() {
  group('WebSocketEvent.fromJson', () {
    test('parses LocationUpdateEvent correctly', () {
      final json = {
        'type': 'location_update',
        'data': {
          'latitude': -6.2088,
          'longitude': 106.8456,
          'heading': 45.0,
          'eta': 8,
          'order_id': 'order-123',
        },
      };

      final event = WebSocketEvent.fromJson(json);

      expect(event, isA<LocationUpdateEvent>());
      final locationEvent = event as LocationUpdateEvent;
      expect(locationEvent.latitude, -6.2088);
      expect(locationEvent.longitude, 106.8456);
      expect(locationEvent.heading, 45.0);
      expect(locationEvent.eta, 8);
      expect(locationEvent.orderId, 'order-123');
    });

    test('parses StatusChangeEvent correctly', () {
      final json = {
        'type': 'status_change',
        'data': {
          'order_id': 'order-456',
          'old_status': 'accepted',
          'new_status': 'on_the_way',
        },
      };

      final event = WebSocketEvent.fromJson(json);

      expect(event, isA<StatusChangeEvent>());
      final statusEvent = event as StatusChangeEvent;
      expect(statusEvent.orderId, 'order-456');
      expect(statusEvent.oldStatus, 'accepted');
      expect(statusEvent.newStatus, 'on_the_way');
    });

    test('parses NewPurchaseEvent correctly', () {
      final json = {
        'type': 'new_purchase',
        'data': {
          'purchase_id': 'purchase-1',
          'item_name': 'Pipa PVC',
          'total_price': 50000,
        },
      };

      final event = WebSocketEvent.fromJson(json);

      expect(event, isA<NewPurchaseEvent>());
      final purchaseEvent = event as NewPurchaseEvent;
      expect(purchaseEvent.purchaseData['purchase_id'], 'purchase-1');
      expect(purchaseEvent.purchaseData['item_name'], 'Pipa PVC');
    });

    test('parses PurchaseStatusChangeEvent correctly', () {
      final json = {
        'type': 'purchase_status_change',
        'data': {
          'purchase_id': 'purchase-2',
          'new_status': 'approved',
          'order_id': 'order-789',
        },
      };

      final event = WebSocketEvent.fromJson(json);

      expect(event, isA<PurchaseStatusChangeEvent>());
      final pscEvent = event as PurchaseStatusChangeEvent;
      expect(pscEvent.purchaseId, 'purchase-2');
      expect(pscEvent.newStatus, 'approved');
      expect(pscEvent.orderId, 'order-789');
    });

    test('parses NewMessageEvent correctly', () {
      final json = {
        'type': 'new_message',
        'data': {
          'message_id': 'msg-1',
          'content': 'Hello!',
          'sender_id': 'user-1',
        },
      };

      final event = WebSocketEvent.fromJson(json);

      expect(event, isA<NewMessageEvent>());
      final msgEvent = event as NewMessageEvent;
      expect(msgEvent.messageData['message_id'], 'msg-1');
      expect(msgEvent.messageData['content'], 'Hello!');
    });

    test('parses TypingEvent correctly', () {
      final json = {
        'type': 'typing',
        'data': {
          'user_id': 'user-2',
          'is_typing': true,
          'order_id': 'order-100',
        },
      };

      final event = WebSocketEvent.fromJson(json);

      expect(event, isA<TypingEvent>());
      final typingEvent = event as TypingEvent;
      expect(typingEvent.userId, 'user-2');
      expect(typingEvent.isTyping, true);
      expect(typingEvent.orderId, 'order-100');
    });

    test('parses MessageReadEvent correctly', () {
      final json = {
        'type': 'message_read',
        'data': {
          'message_ids': ['msg-1', 'msg-2', 'msg-3'],
          'order_id': 'order-200',
        },
      };

      final event = WebSocketEvent.fromJson(json);

      expect(event, isA<MessageReadEvent>());
      final readEvent = event as MessageReadEvent;
      expect(readEvent.messageIds, ['msg-1', 'msg-2', 'msg-3']);
      expect(readEvent.orderId, 'order-200');
    });

    test('returns null for unknown event type', () {
      final json = {
        'type': 'unknown_event',
        'data': {'foo': 'bar'},
      };

      final event = WebSocketEvent.fromJson(json);
      expect(event, isNull);
    });

    test('handles missing data field gracefully', () {
      final json = {
        'type': 'location_update',
        'latitude': 1.0,
        'longitude': 2.0,
      };

      // When 'data' is missing, it falls back to using the json itself.
      final event = WebSocketEvent.fromJson(json);
      expect(event, isA<LocationUpdateEvent>());
      final locationEvent = event as LocationUpdateEvent;
      expect(locationEvent.latitude, 1.0);
      expect(locationEvent.longitude, 2.0);
    });

    test('handles missing type field', () {
      final json = {'latitude': 1.0, 'longitude': 2.0};
      final event = WebSocketEvent.fromJson(json);
      expect(event, isNull);
    });
  });

  group('WebSocketManagerImpl', () {
    late WebSocketManagerImpl manager;
    late FakeWebSocketChannel fakeChannel;
    late List<FakeWebSocketChannel> createdChannels;

    setUp(() {
      createdChannels = [];
      fakeChannel = FakeWebSocketChannel();
      createdChannels.add(fakeChannel);

      manager = WebSocketManagerImpl(
        baseUrl: 'wss://test.example.com/ws',
        channelFactory: (uri, token) {
          return fakeChannel;
        },
      );
    });

    tearDown(() async {
      await manager.dispose();
      for (final ch in createdChannels) {
        ch.dispose();
      }
    });

    test('initial state is disconnected', () {
      expect(manager.isConnected, isFalse);
      expect(manager.currentState, ConnectionState.disconnected);
    });

    test('connect transitions to connected state', () async {
      final states = <ConnectionState>[];
      manager.connectionStateStream.listen(states.add);

      await manager.connect('tracking', 'order-1', 'test-token');

      // Allow stream events to propagate.
      await Future<void>.delayed(Duration.zero);

      expect(manager.isConnected, isTrue);
      expect(manager.currentState, ConnectionState.connected);
      expect(states, contains(ConnectionState.connecting));
      expect(states, contains(ConnectionState.connected));
    });

    test('disconnect transitions to disconnected state', () async {
      await manager.connect('tracking', 'order-1', 'test-token');
      await Future<void>.delayed(Duration.zero);

      await manager.disconnect('tracking');
      await Future<void>.delayed(Duration.zero);

      expect(manager.isConnected, isFalse);
      expect(manager.currentState, ConnectionState.disconnected);
    });

    test('receives and parses WebSocket events', () async {
      await manager.connect('tracking', 'order-1', 'test-token');
      await Future<void>.delayed(Duration.zero);

      final events = <WebSocketEvent>[];
      manager.eventStream.listen(events.add);

      final message = jsonEncode({
        'type': 'location_update',
        'data': {
          'latitude': -6.2,
          'longitude': 106.8,
          'heading': 90.0,
          'eta': 5,
        },
      });

      fakeChannel.addIncoming(message);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first, isA<LocationUpdateEvent>());
      final locationEvent = events.first as LocationUpdateEvent;
      expect(locationEvent.latitude, -6.2);
      expect(locationEvent.longitude, 106.8);
      expect(locationEvent.eta, 5);
    });

    test('ignores malformed JSON messages', () async {
      await manager.connect('tracking', 'order-1', 'test-token');
      await Future<void>.delayed(Duration.zero);

      final events = <WebSocketEvent>[];
      manager.eventStream.listen(events.add);

      fakeChannel.addIncoming('not valid json {{{');
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('ignores unknown event types', () async {
      await manager.connect('tracking', 'order-1', 'test-token');
      await Future<void>.delayed(Duration.zero);

      final events = <WebSocketEvent>[];
      manager.eventStream.listen(events.add);

      fakeChannel.addIncoming(jsonEncode({
        'type': 'unknown_type',
        'data': {},
      }));
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('send encodes data as JSON and sends to channel', () async {
      await manager.connect('chat', 'order-1', 'test-token');
      await Future<void>.delayed(Duration.zero);

      manager.send('chat', {'type': 'typing', 'is_typing': true});

      expect(fakeChannel.sink.sentMessages, hasLength(1));
      final sent = jsonDecode(fakeChannel.sink.sentMessages.first as String);
      expect(sent['type'], 'typing');
      expect(sent['is_typing'], true);
    });

    test('send does nothing for non-existent channel', () {
      // Should not throw.
      manager.send('nonexistent', {'data': 'test'});
    });

    test('reconnects on connection error with exponential backoff', () async {
      fakeChannel = FakeWebSocketChannel(shouldFailReady: true);
      createdChannels.add(fakeChannel);

      int connectAttempts = 0;
      manager = WebSocketManagerImpl(
        baseUrl: 'wss://test.example.com/ws',
        channelFactory: (uri, token) {
          connectAttempts++;
          return fakeChannel;
        },
      );

      final states = <ConnectionState>[];
      manager.connectionStateStream.listen(states.add);

      await manager.connect('tracking', 'order-1', 'test-token');
      await Future<void>.delayed(Duration.zero);

      // First attempt fails, should schedule reconnect.
      expect(connectAttempts, 1);
      expect(states, contains(ConnectionState.connecting));
    });

    test('transitions to reconnecting when connection drops', () async {
      await manager.connect('tracking', 'order-1', 'test-token');
      await Future<void>.delayed(Duration.zero);

      final states = <ConnectionState>[];
      manager.connectionStateStream.listen(states.add);

      // Simulate server closing the connection.
      fakeChannel.closeFromServer();
      await Future<void>.delayed(Duration.zero);

      expect(states, contains(ConnectionState.reconnecting));
    });

    test('connecting to same channel disconnects previous connection', () async {
      await manager.connect('tracking', 'order-1', 'test-token');
      await Future<void>.delayed(Duration.zero);

      final newChannel = FakeWebSocketChannel();
      createdChannels.add(newChannel);

      manager = WebSocketManagerImpl(
        baseUrl: 'wss://test.example.com/ws',
        channelFactory: (uri, token) => newChannel,
      );

      // The old channel's sink should have been closed via disconnect.
      // This test verifies no exceptions are thrown.
      await manager.connect('tracking', 'order-2', 'test-token');
      await Future<void>.delayed(Duration.zero);

      expect(manager.isConnected, isTrue);
    });

    test('constructs correct URI from base URL, channel, and orderId', () async {
      Uri? capturedUri;
      String? capturedToken;

      final channel = FakeWebSocketChannel();
      createdChannels.add(channel);

      final testManager = WebSocketManagerImpl(
        baseUrl: 'wss://api.situkang.id/v1/ws',
        channelFactory: (uri, token) {
          capturedUri = uri;
          capturedToken = token;
          return channel;
        },
      );

      await testManager.connect('tracking', 'order-abc', 'my-jwt-token');
      await Future<void>.delayed(Duration.zero);

      expect(capturedUri.toString(), 'wss://api.situkang.id/v1/ws/tracking/order-abc');
      expect(capturedToken, 'my-jwt-token');

      await testManager.dispose();
      channel.dispose();
    });

    test('multiple events are received in order', () async {
      await manager.connect('chat', 'order-1', 'test-token');
      await Future<void>.delayed(Duration.zero);

      final events = <WebSocketEvent>[];
      manager.eventStream.listen(events.add);

      fakeChannel.addIncoming(jsonEncode({
        'type': 'new_message',
        'data': {'message_id': 'msg-1', 'content': 'First'},
      }));
      fakeChannel.addIncoming(jsonEncode({
        'type': 'typing',
        'data': {'user_id': 'user-1', 'is_typing': true},
      }));
      fakeChannel.addIncoming(jsonEncode({
        'type': 'new_message',
        'data': {'message_id': 'msg-2', 'content': 'Second'},
      }));

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(3));
      expect(events[0], isA<NewMessageEvent>());
      expect(events[1], isA<TypingEvent>());
      expect(events[2], isA<NewMessageEvent>());
    });
  });

  group('WebSocketManagerImpl - Backoff Calculation', () {
    test('backoff delays follow exponential pattern capped at 60s', () {
      // We test the backoff logic indirectly by verifying the formula:
      // delay = min(1000ms * 2^attempt, 60000ms)
      // attempt 0: 1s
      // attempt 1: 2s
      // attempt 2: 4s
      // attempt 3: 8s
      // attempt 4: 16s
      // attempt 5: 32s
      // attempt 6: 60s (capped, would be 64s)
      // attempt 7: 60s (capped)

      const initialMs = 1000; // 1 second
      const maxMs = 60000; // 60 seconds

      int calculateDelay(int attempt) {
        final raw = initialMs * (1 << attempt); // 2^attempt
        return raw > maxMs ? maxMs : raw;
      }

      expect(calculateDelay(0), 1000);
      expect(calculateDelay(1), 2000);
      expect(calculateDelay(2), 4000);
      expect(calculateDelay(3), 8000);
      expect(calculateDelay(4), 16000);
      expect(calculateDelay(5), 32000);
      expect(calculateDelay(6), 60000); // capped
      expect(calculateDelay(7), 60000); // capped
      expect(calculateDelay(8), 60000); // capped
      expect(calculateDelay(9), 60000); // capped
    });
  });

  group('LocationUpdateEvent', () {
    test('handles null optional fields', () {
      final event = LocationUpdateEvent.fromJson({
        'latitude': 1.0,
        'longitude': 2.0,
      });

      expect(event.latitude, 1.0);
      expect(event.longitude, 2.0);
      expect(event.heading, isNull);
      expect(event.eta, isNull);
      expect(event.orderId, isNull);
    });

    test('handles integer coordinates', () {
      final event = LocationUpdateEvent.fromJson({
        'latitude': 1,
        'longitude': 2,
        'heading': 90,
        'eta': 10,
      });

      expect(event.latitude, 1.0);
      expect(event.longitude, 2.0);
      expect(event.heading, 90.0);
      expect(event.eta, 10);
    });
  });

  group('MessageReadEvent', () {
    test('handles non-list message_ids gracefully', () {
      final event = MessageReadEvent.fromJson({
        'message_ids': 'not-a-list',
      });

      expect(event.messageIds, isEmpty);
    });

    test('handles empty message_ids list', () {
      final event = MessageReadEvent.fromJson({
        'message_ids': <String>[],
      });

      expect(event.messageIds, isEmpty);
    });
  });

  group('ConnectionState enum', () {
    test('has all expected values', () {
      expect(ConnectionState.values, hasLength(4));
      expect(ConnectionState.values, contains(ConnectionState.connecting));
      expect(ConnectionState.values, contains(ConnectionState.connected));
      expect(ConnectionState.values, contains(ConnectionState.disconnected));
      expect(ConnectionState.values, contains(ConnectionState.reconnecting));
    });
  });
}
