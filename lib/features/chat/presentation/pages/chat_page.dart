import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/chat_message.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Page for real-time chat within an active order.
///
/// Displays messages in a scrollable list with optimistic UI for sending,
/// typing indicators, image attachments, cursor-based pagination,
/// and message retry for failures.
///
/// Validates: Requirements 11.1-11.11
class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.orderId, required this.currentUserId, super.key,
    this.workerName = 'Tukang',
    this.workerAvatarUrl,
    this.isWorkerOnline = false,
  });

  /// The order ID for this chat conversation.
  final String orderId;

  /// The current user's ID (to distinguish sent vs received messages).
  final String currentUserId;

  /// The worker's display name.
  final String workerName;

  /// The worker's avatar URL.
  final String? workerAvatarUrl;

  /// Whether the worker is currently online.
  final bool isWorkerOnline;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadMessages(orderId: widget.orderId));
    context.read<ChatBloc>().add(MarkAsRead(orderId: widget.orderId));

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load older messages when scrolling to the top
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<ChatBloc>().state;
      if (state is ChatLoaded && state.hasMore && !state.isLoadingMore) {
        context.read<ChatBloc>().add(
              LoadMessages(
                orderId: widget.orderId,
                cursor: state.nextCursor,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.workerAvatarUrl != null
                      ? NetworkImage(widget.workerAvatarUrl!)
                      : null,
                  child: widget.workerAvatarUrl == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                if (widget.isWorkerOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.workerName,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ),
                  BlocBuilder<ChatBloc, ChatState>(
                    buildWhen: (prev, curr) {
                      if (prev is ChatLoaded && curr is ChatLoaded) {
                        return prev.isCounterpartTyping !=
                            curr.isCounterpartTyping;
                      }
                      return false;
                    },
                    builder: (context, state) {
                      if (state is ChatLoaded && state.isCounterpartTyping) {
                        return Text(
                          'sedang mengetik...',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textOnDark.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      return Text(
                        widget.isWorkerOnline ? 'Online' : 'Offline',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.7),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatInitial) {
                  return const LoadingIndicator();
                }

                if (state is ChatError) {
                  return AppErrorWidget(
                    message: state.failure.message,
                    onRetry: () {
                      context.read<ChatBloc>().add(
                            LoadMessages(orderId: widget.orderId),
                          );
                    },
                  );
                }

                if (state is ChatLoaded) {
                  return _buildMessageList(state);
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatLoaded state) {
    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: AppSizing.iconXxl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Mulai percakapan',
              style: AppTypography.h6.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kirim pesan ke ${widget.workerName}',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Loading more indicator
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),

        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: AppSpacing.pagePadding,
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final message = state.messages[index];
              final isMe = message.senderId == widget.currentUserId;

              // Date separator
              final showDate = _shouldShowDateSeparator(
                state.messages,
                index,
              );

              return Column(
                children: [
                  if (showDate)
                    _buildDateSeparator(message.createdAt),
                  ChatBubble(
                    message: message,
                    isMe: isMe,
                    onRetry: message.deliveryStatus ==
                            MessageDeliveryStatus.failed
                        ? () => context.read<ChatBloc>().add(
                              RetryMessage(message: message),
                            )
                        : null,
                  ),
                ],
              );
            },
          ),
        ),

        // Typing indicator
        if (state.isCounterpartTyping)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.pagePaddingHorizontal,
              bottom: AppSpacing.xs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TypingIndicator(name: widget.workerName),
            ),
          ),
      ],
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          ),
          child: Text(
            _formatDateSeparator(date),
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (prev, curr) {
        if (prev is ChatLoaded && curr is ChatLoaded) {
          return prev.isSending != curr.isSending;
        }
        return false;
      },
      builder: (context, state) {
        final isSending = state is ChatLoaded && state.isSending;

        return Container(
          padding: EdgeInsets.only(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            top: AppSpacing.sm,
            bottom: MediaQuery.of(context).viewPadding.bottom + AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image picker button
              IconButton(
                onPressed: isSending ? null : _pickImage,
                icon: const Icon(Icons.image_outlined),
                color: AppColors.textSecondary,
              ),

              // Text input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: !isSending,
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusFull),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 2000,
                  maxLines: 4,
                  minLines: 1,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  onChanged: (_) {
                    context.read<ChatBloc>().add(
                          TypingStarted(orderId: widget.orderId),
                        );
                  },
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // Send button
              Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: isSending ? null : _sendMessage,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: AppColors.onPrimary,
                            size: AppSizing.iconSm + 4,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(
          SendTextMessage(
            orderId: widget.orderId,
            content: text,
          ),
        );
    _messageController.clear();
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      // Optional: show caption dialog
      if (mounted) {
        context.read<ChatBloc>().add(
              SendImageMessage(
                orderId: widget.orderId,
                image: file,
              ),
            );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowDateSeparator(List<ChatMessage> messages, int index) {
    if (index == messages.length - 1) return true;

    final current = messages[index].createdAt;
    final next = messages[index + 1].createdAt;

    return current.day != next.day ||
        current.month != next.month ||
        current.year != next.year;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return 'Hari ini';
    if (messageDate == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return DateFormat('dd MMMM yyyy', 'id').format(date);
  }
}
