part of 'chat_bloc.dart';

/// Sealed class representing all chat states.
///
/// The [ChatBloc] emits these states in response to [ChatEvent]s,
/// driving the UI to display messages, typing indicators, and errors.
sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// The initial state before any chat action has been taken.
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// State emitted when chat messages are successfully loaded.
///
/// Contains the message list, pagination info, and typing status.
class ChatLoaded extends ChatState {
  /// Creates a [ChatLoaded] state.
  const ChatLoaded({
    required this.messages,
    required this.hasMore,
    this.nextCursor,
    this.isCounterpartTyping = false,
    this.isLoadingMore = false,
    this.isSending = false,
  });

  /// The list of chat messages (newest first in the list).
  final List<ChatMessage> messages;

  /// Whether there are more older messages to load.
  final bool hasMore;

  /// The cursor for loading the next page of older messages.
  final String? nextCursor;

  /// Whether the counterpart is currently typing.
  final bool isCounterpartTyping;

  /// Whether older messages are currently being loaded.
  final bool isLoadingMore;

  /// Whether a message is currently being sent.
  final bool isSending;

  /// Creates a copy of this state with the given fields replaced.
  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? hasMore,
    String? nextCursor,
    bool? isCounterpartTyping,
    bool? isLoadingMore,
    bool? isSending,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      isCounterpartTyping: isCounterpartTyping ?? this.isCounterpartTyping,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        hasMore,
        nextCursor,
        isCounterpartTyping,
        isLoadingMore,
        isSending,
      ];
}

/// State emitted when a chat operation fails.
class ChatError extends ChatState {
  /// Creates a [ChatError] state.
  const ChatError({required this.failure});

  /// The failure describing what went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
