import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({
    this.isWorker = false,
    this.currentUserId = '',
    super.key,
  });

  final bool isWorker;
  final String currentUserId;

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _repository = getIt<ChatRepository>();
  final _formatter = DateFormat('HH:mm', 'id');

  Timer? _refreshTimer;
  List<ChatConversation> _conversations = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _highlightedOrderId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadConversations());
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => unawaited(_loadConversations(silent: true)),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final result = await _repository.getChatList(isWorker: widget.isWorker);
    if (!mounted) return;

    result.fold(
      (failure) {
        if (silent) return;
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (items) {
        final sorted = [...items]
          ..sort((a, b) {
            final aTime =
                a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

        final previousFirst = _conversations.isNotEmpty
            ? _conversations.first.orderId
            : null;
        final nextFirst = sorted.isNotEmpty ? sorted.first.orderId : null;
        final shouldHighlight =
            silent &&
            previousFirst != null &&
            nextFirst != null &&
            previousFirst != nextFirst;

        setState(() {
          _conversations = sorted;
          _isLoading = false;
          _errorMessage = null;
          if (shouldHighlight) _highlightedOrderId = nextFirst;
        });

        if (shouldHighlight) {
          Future<void>.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            setState(() => _highlightedOrderId = null);
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FE),
      appBar: AppBar(
        title: Text(widget.isWorker ? 'Chat Pelanggan' : 'Chat Tukang'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePadding,
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.wifi_off,
            size: AppSizing.iconXxl,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: _loadConversations,
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    }

    if (_conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePadding,
        children: [
          const SizedBox(height: 150),
          const Icon(
            Icons.chat_bubble_outline,
            size: AppSizing.iconXxl,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada percakapan',
            textAlign: TextAlign.center,
            style: AppTypography.h6.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.isWorker
                ? 'Percakapan dari pelanggan akan muncul di sini.'
                : 'Percakapan dengan tukang yang Anda pesan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, -0.04),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: ListView.separated(
        key: ValueKey(
          _conversations
              .map(
                (item) =>
                    '${item.orderId}:${item.lastMessageTime?.millisecondsSinceEpoch ?? 0}',
              )
              .join('|'),
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: _conversations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _ConversationCard(
            conversation: conversation,
            timeText: _formatTime(conversation.lastMessageTime),
            highlighted: conversation.orderId == _highlightedOrderId,
            onTap: () => _openConversation(conversation),
          );
        },
      ),
    );
  }

  void _openConversation(ChatConversation conversation) {
    final path = widget.isWorker
        ? '/worker/chat/${conversation.orderId}'
        : '/chat/${conversation.orderId}';
    context.push(path, extra: conversation);
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return _formatter.format(time);
    if (difference.inDays < 7) return DateFormat('EEE', 'id').format(time);
    return DateFormat('dd/MM/yy').format(time);
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.timeText,
    required this.highlighted,
    required this.onTap,
  });

  final ChatConversation conversation;
  final String timeText;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFE8F8FF) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? AppColors.primary : const Color(0xFFE4E8EF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: highlighted ? 0.10 : 0.05),
            blurRadius: highlighted ? 18 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFE8EEF5),
                      backgroundImage: conversation.workerAvatarUrl != null
                          ? NetworkImage(conversation.workerAvatarUrl!)
                          : null,
                      child: conversation.workerAvatarUrl == null
                          ? const Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
                    if (conversation.isOnline)
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.workerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label.copyWith(
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (timeText.isNotEmpty)
                            Text(
                              timeText,
                              style: AppTypography.caption.copyWith(
                                color: conversation.unreadCount > 0
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      if (conversation.orderTitle != null &&
                          conversation.orderTitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          conversation.orderTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage?.trim().isNotEmpty ==
                                      true
                                  ? conversation.lastMessage!
                                  : 'Belum ada pesan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: conversation.unreadCount > 0
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(minWidth: 22),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                  AppSizing.radiusFull,
                                ),
                              ),
                              child: Text(
                                conversation.unreadCount > 99
                                    ? '99+'
                                    : '${conversation.unreadCount}',
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
