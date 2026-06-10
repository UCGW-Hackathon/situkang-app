import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/connectivity_manager.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import '../datasources/chat_websocket_data_source.dart';

/// Implementation of [ChatRepository] combining REST, WebSocket, and local cache.
///
/// Uses WebSocket for real-time message delivery and typing indicators.
/// Uses REST for message history, image uploads, and mark-as-read.
/// Uses local cache for offline access to previously loaded messages.
///
/// Requirements: 11.1, 11.2, 11.3, 11.6, 11.8
@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.webSocketDataSource,
    required this.localDataSource,
    required this.tokenStorage,
    required this.connectivityManager,
  });

  final ChatRemoteDataSource remoteDataSource;
  final ChatWebSocketDataSource webSocketDataSource;
  final ChatLocalDataSource localDataSource;
  final TokenStorage tokenStorage;
  final ConnectivityManager connectivityManager;

  @override
  Stream<ChatMessage> get incomingMessageStream =>
      webSocketDataSource.incomingMessageStream;

  @override
  Stream<bool> get typingStream => webSocketDataSource.typingStream;

  @override
  Future<Result<List<ChatMessage>>> getMessages(
    String orderId, {
    String? cursor,
    int limit = 50,
    bool isWorker = false,
  }) async {
    try {
      if (!connectivityManager.isOnline) {
        // Return cached messages when offline
        final cached = await localDataSource.getCachedMessages(orderId);
        if (cached != null) {
          return Right(cached.map((m) => m.toEntity()).toList());
        }
        return const Left(NetworkFailure());
      }

      final models = await remoteDataSource.getMessages(
        orderId,
        cursor: cursor,
        limit: limit,
        isWorker: isWorker,
      );

      // Cache the first page of messages (no cursor = first load)
      if (cursor == null) {
        await localDataSource.cacheMessages(orderId, models);
      }

      final messages = models.map((m) => m.toEntity()).toList();
      return Right(messages);
    } on DioException catch (e) {
      // Try cache on network error
      final cached = await localDataSource.getCachedMessages(orderId);
      if (cached != null) {
        return Right(cached.map((m) => m.toEntity()).toList());
      }
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<ChatMessage>> sendTextMessage(
    String orderId,
    String content, {
    bool isWorker = false,
  }) async {
    try {
      final model = await remoteDataSource.sendTextMessage(
        orderId,
        content,
        isWorker: isWorker,
      );
      final message = model.toEntity();

      // Cache the sent message
      await localDataSource.appendMessage(orderId, model);

      return Right(message);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<ChatMessage>> sendImageMessage(
    String orderId,
    File image, {
    String? caption,
    bool isWorker = false,
  }) async {
    try {
      final model = await remoteDataSource.sendImageMessage(
        orderId,
        image,
        caption: caption,
        isWorker: isWorker,
      );
      final message = model.toEntity();

      // Cache the sent message
      await localDataSource.appendMessage(orderId, model);

      return Right(message);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> markAsRead(
    String orderId, {
    bool isWorker = false,
  }) async {
    try {
      await remoteDataSource.markAsRead(orderId, isWorker: isWorker);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<List<ChatConversation>>> getChatList() async {
    try {
      if (!connectivityManager.isOnline) {
        // Return cached chat list when offline
        final cached = await localDataSource.getCachedChatList();
        if (cached != null) {
          return Right(cached.map((c) => c.toEntity()).toList());
        }
        return const Left(NetworkFailure());
      }

      final models = await remoteDataSource.getChatList();

      // Cache the chat list
      await localDataSource.cacheChatList(models);

      final conversations = models.map((m) => m.toEntity()).toList();
      return Right(conversations);
    } on DioException catch (e) {
      // Try cache on network error
      final cached = await localDataSource.getCachedChatList();
      if (cached != null) {
        return Right(cached.map((c) => c.toEntity()).toList());
      }
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  void sendTypingIndicator(String orderId) {
    webSocketDataSource.sendTypingIndicator(orderId);
  }

  @override
  Future<void> connectToChat(String orderId) async {
    final token = await tokenStorage.getAccessToken();
    if (token == null) return;

    await webSocketDataSource.connect(orderId, token);
  }

  @override
  Future<void> disconnectFromChat() async {
    await webSocketDataSource.disconnect();
  }

  /// Maps a [DioException] to the appropriate [Failure] type.
  Failure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final data = e.response?.data as Map<String, dynamic>?;
        final message = data?['message'] as String? ?? 'Terjadi kesalahan';
        return ServerFailure(message, statusCode: statusCode);
      default:
        return const NetworkFailure();
    }
  }
}
