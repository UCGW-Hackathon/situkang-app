import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// BLoC responsible for managing chat state within an order conversation.
///
/// Handles message loading with cursor-based pagination, sending text and
/// image messages, receiving real-time messages via WebSocket, typing
/// indicators, and failed message retry.
///
/// Validates:
/// - Requirement 11.1: Message history with pagination
/// - Requirement 11.2: Text message sending (1-2000 chars)
/// - Requirement 11.3: Image message sending (JPG/PNG, max 10MB)
/// - Requirement 11.4: Real-time incoming messages
/// - Requirement 11.5: Typing indicator
/// - Requirement 11.6: Mark messages as read
/// - Requirement 11.8: Cursor-based pagination
/// - Requirement 11.9: Failed message retry
/// - Requirement 11.10: Image upload error handling
/// - Requirement 11.11: Whitespace-only message rejection
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  /// Creates a [ChatBloc] with the required repository.
  ChatBloc({
    required ChatRepository chatRepository,
  })  : _chatRepository = chatRepository,
        super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendImageMessage>(_onSendImageMessage);
    on<MessageReceived>(_onMessageReceived);
    on<TypingStarted>(_onTypingStarted);
    on<MarkAsRead>(_onMarkAsRead);
    on<TypingStatusChanged>(_onTypingStatusChanged);
    on<RetryMessage>(_onRetryMessage);
  }

  final ChatRepository _chatRepository;
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<bool>? _typingSubscription;

  /// Connects to the chat WebSocket and subscribes to streams.
  Future<void> connectToChat(String orderId) async {
    await _chatRepository.connectToChat(orderId);

    _messageSubscription?.cancel();
    _messageSubscription = _chatRepository.incomingMessageStream.listen(
      (message) => add(MessageReceived(message: message)),
    );

    _typingSubscription?.cancel();
    _typingSubscription = _chatRepository.typingStream.listen(
      (isTyping) => add(TypingStatusChanged(isTyping: isTyping)),
    );
  }

  /// Handles [LoadMessages] events.
  ///
  /// Loads messages with cursor-based pagination. On initial load (no cursor),
  /// replaces the state. On pagination (with cursor), appends older messages.
  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    final isLoadingMore = event.cursor != null;

    if (isLoadingMore && currentState is ChatLoaded) {
      emit(currentState.copyWith(isLoadingMore: true));
    }

    final result = await _chatRepository.getMessages(
      event.orderId,
      cursor: event.cursor,
    );

    result.fold(
      (failure) {
        if (isLoadingMore && currentState is ChatLoaded) {
          emit(currentState.copyWith(isLoadingMore: false));
        } else {
          emit(ChatError(failure: failure));
        }
      },
      (messages) {
        final hasMore = messages.length >= AppConstants.chatPageSize;
        final nextCursor = messages.isNotEmpty
            ? messages.last.createdAt.toIso8601String()
            : null;

        if (isLoadingMore && currentState is ChatLoaded) {
          // Append older messages to the end of the list
          final allMessages = [...currentState.messages, ...messages];
          emit(currentState.copyWith(
            messages: allMessages,
            hasMore: hasMore,
            nextCursor: nextCursor,
            isLoadingMore: false,
          ));
        } else {
          emit(ChatLoaded(
            messages: messages,
            hasMore: hasMore,
            nextCursor: nextCursor,
          ));
        }
      },
    );
  }

  /// Handles [SendTextMessage] events.
  ///
  /// Validates the message content (1-2000 chars, non-whitespace-only),
  /// adds an optimistic message to the UI, then sends via repository.
  /// On failure, marks the message as failed for retry.
  Future<void> _onSendTextMessage(
    SendTextMessage event,
    Emitter<ChatState> emit,
  ) async {
    // Validate message content
    final validationError = MessageValidator.validate(event.content);
    if (validationError != null) {
      return; // Silently reject - UI should prevent this
    }

    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // Create optimistic message
    final optimisticMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      orderId: event.orderId,
      senderId: 'current_user',
      senderName: 'Anda',
      type: MessageType.text,
      content: event.content,
      isRead: false,
      createdAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.sending,
    );

    // Add optimistic message to the top of the list
    emit(currentState.copyWith(
      messages: [optimisticMessage, ...currentState.messages],
      isSending: true,
    ));

    final result = await _chatRepository.sendTextMessage(
      event.orderId,
      event.content,
    );

    final updatedState = state;
    if (updatedState is! ChatLoaded) return;

    result.fold(
      (failure) {
        // Mark message as failed
        final failedMessage = optimisticMessage.copyWith(
          deliveryStatus: MessageDeliveryStatus.failed,
        );
        final updatedMessages = updatedState.messages.map((m) {
          if (m.id == optimisticMessage.id) return failedMessage;
          return m;
        }).toList();
        emit(updatedState.copyWith(
          messages: updatedMessages,
          isSending: false,
        ));
      },
      (sentMessage) {
        // Replace optimistic message with confirmed message
        final updatedMessages = updatedState.messages.map((m) {
          if (m.id == optimisticMessage.id) return sentMessage;
          return m;
        }).toList();
        emit(updatedState.copyWith(
          messages: updatedMessages,
          isSending: false,
        ));
      },
    );
  }

  /// Handles [SendImageMessage] events.
  ///
  /// Validates the image file (JPG/PNG, max 10MB), adds an optimistic message,
  /// then uploads via repository. On failure, marks as failed for retry.
  Future<void> _onSendImageMessage(
    SendImageMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // Validate image file
    final fileName = event.image.path.split('/').last.split(r'\').last;
    final fileSize = await event.image.length();
    final fileValidation = FileUploadValidator.validate(
      fileName,
      fileSize,
      maxSize: AppConstants.maxChatImageFileSize,
    );

    if (fileValidation != null) {
      // Emit error state briefly, then restore
      final failedMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        orderId: event.orderId,
        senderId: 'current_user',
        senderName: 'Anda',
        type: MessageType.image,
        content: fileValidation,
        caption: event.caption,
        isRead: false,
        createdAt: DateTime.now(),
        deliveryStatus: MessageDeliveryStatus.failed,
      );
      emit(currentState.copyWith(
        messages: [failedMessage, ...currentState.messages],
      ));
      return;
    }

    // Validate caption length
    if (event.caption != null && event.caption!.length > 500) {
      return; // Silently reject - UI should prevent this
    }

    // Create optimistic message
    final optimisticMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      orderId: event.orderId,
      senderId: 'current_user',
      senderName: 'Anda',
      type: MessageType.image,
      content: 'Mengirim gambar...',
      caption: event.caption,
      isRead: false,
      createdAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.sending,
    );

    emit(currentState.copyWith(
      messages: [optimisticMessage, ...currentState.messages],
      isSending: true,
    ));

    final result = await _chatRepository.sendImageMessage(
      event.orderId,
      event.image,
      caption: event.caption,
    );

    final updatedState = state;
    if (updatedState is! ChatLoaded) return;

    result.fold(
      (failure) {
        final failedMessage = optimisticMessage.copyWith(
          deliveryStatus: MessageDeliveryStatus.failed,
          content: failure.message,
        );
        final updatedMessages = updatedState.messages.map((m) {
          if (m.id == optimisticMessage.id) return failedMessage;
          return m;
        }).toList();
        emit(updatedState.copyWith(
          messages: updatedMessages,
          isSending: false,
        ));
      },
      (sentMessage) {
        final updatedMessages = updatedState.messages.map((m) {
          if (m.id == optimisticMessage.id) return sentMessage;
          return m;
        }).toList();
        emit(updatedState.copyWith(
          messages: updatedMessages,
          isSending: false,
        ));
      },
    );
  }

  /// Handles [MessageReceived] events from WebSocket.
  ///
  /// Appends the incoming message to the top of the message list.
  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // Avoid duplicates
    final exists = currentState.messages.any((m) => m.id == event.message.id);
    if (exists) return;

    emit(currentState.copyWith(
      messages: [event.message, ...currentState.messages],
    ));
  }

  /// Handles [TypingStarted] events.
  ///
  /// Sends a typing indicator to the counterpart via WebSocket.
  void _onTypingStarted(
    TypingStarted event,
    Emitter<ChatState> emit,
  ) {
    _chatRepository.sendTypingIndicator(event.orderId);
  }

  /// Handles [MarkAsRead] events.
  ///
  /// Calls the mark-read endpoint to mark all messages as read.
  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    await _chatRepository.markAsRead(event.orderId);
  }

  /// Handles [TypingStatusChanged] events from WebSocket.
  ///
  /// Updates the typing indicator display state.
  void _onTypingStatusChanged(
    TypingStatusChanged event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    emit(currentState.copyWith(isCounterpartTyping: event.isTyping));
  }

  /// Handles [RetryMessage] events.
  ///
  /// Retries sending a failed message, preserving its content locally.
  Future<void> _onRetryMessage(
    RetryMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final message = event.message;

    // Mark as sending again
    final sendingMessage = message.copyWith(
      deliveryStatus: MessageDeliveryStatus.sending,
    );
    final updatedMessages = currentState.messages.map((m) {
      if (m.id == message.id) return sendingMessage;
      return m;
    }).toList();
    emit(currentState.copyWith(messages: updatedMessages, isSending: true));

    if (message.type == MessageType.text) {
      final result = await _chatRepository.sendTextMessage(
        message.orderId,
        message.content,
      );

      final latestState = state;
      if (latestState is! ChatLoaded) return;

      result.fold(
        (failure) {
          final failedMessage = message.copyWith(
            deliveryStatus: MessageDeliveryStatus.failed,
          );
          final msgs = latestState.messages.map((m) {
            if (m.id == message.id) return failedMessage;
            return m;
          }).toList();
          emit(latestState.copyWith(messages: msgs, isSending: false));
        },
        (sentMessage) {
          final msgs = latestState.messages.map((m) {
            if (m.id == message.id) return sentMessage;
            return m;
          }).toList();
          emit(latestState.copyWith(messages: msgs, isSending: false));
        },
      );
    }
    // Image retry would require storing the file reference locally
    // which is handled by the UI layer preserving the File reference
  }

  @override
  Future<void> close() async {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    await _chatRepository.disconnectFromChat();
    return super.close();
  }
}
