import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/chat_conversation.dart';

/// Page displaying a list of active chat conversations.
///
/// Shows worker name, avatar, online status, last message preview
/// (truncated to 80 characters), order title, and unread count.
///
/// Validates: Requirement 11.7
class ChatListPage extends StatelessWidget {
  const ChatListPage({
    super.key,
    this.conversations = const [],
    this.onConversationTap,
  });

  /// List of active conversations.
  final List<ChatConversation> conversations;

  /// Callback when a conversation is tapped.
  final void Function(ChatConversation conversation)? onConversationTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan'),
      ),
      body: conversations.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  onTap: () => onConversationTap?.call(conversation),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: AppSizing.iconXxl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Belum ada percakapan',
              style: AppTypography.h6.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Percakapan dengan tukang akan muncul di sini setelah Anda membuat pesanan',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile widget for a single conversation in the chat list.
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePaddingHorizontal,
        vertical: AppSpacing.xs,
      ),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: AppSizing.avatarMd / 2,
            backgroundImage: conversation.workerAvatarUrl != null
                ? NetworkImage(conversation.workerAvatarUrl!)
                : null,
            child: conversation.workerAvatarUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          // Online indicator
          if (conversation.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.workerName,
              style: AppTypography.label.copyWith(
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessageTime != null)
            Text(
              _formatTime(conversation.lastMessageTime!),
              style: AppTypography.caption.copyWith(
                color: conversation.unreadCount > 0
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conversation.orderTitle != null) ...[
            const SizedBox(height: 2),
            Text(
              conversation.orderTitle!,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (conversation.lastMessage != null) ...[
            const SizedBox(height: 2),
            Text(
              _truncateMessage(conversation.lastMessage!),
              style: AppTypography.bodySmall.copyWith(
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: conversation.unreadCount > 0
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: conversation.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
              constraints: const BoxConstraints(minWidth: 20),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : '${conversation.unreadCount}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : null,
    );
  }

  String _truncateMessage(String message) {
    if (message.length <= 80) return message;
    return '${message.substring(0, 80)}...';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return DateFormat('HH:mm').format(time);
    if (difference.inDays < 7) return DateFormat('EEE', 'id').format(time);
    return DateFormat('dd/MM/yy').format(time);
  }
}
