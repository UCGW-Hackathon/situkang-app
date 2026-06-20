import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/domain/entities/chat_conversation.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../di/injection.dart';
import '../theme/theme.dart';

class UserAppShell extends StatelessWidget {
  const UserAppShell({required this.child, super.key});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/orders');
      case 2:
        context.go('/chat');
      case 3:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ShellScaffold(
      isWorker: false,
      selectedIndex: _selectedIndex(context),
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        _ShellNavItem(
          activeIcon: Icons.home,
          inactiveIcon: Icons.home_outlined,
          label: 'Home',
        ),
        _ShellNavItem(
          activeIcon: Icons.handyman,
          inactiveIcon: Icons.handyman_outlined,
          label: 'Orders',
        ),
        _ShellNavItem(
          activeIcon: Icons.chat_bubble,
          inactiveIcon: Icons.chat_bubble_outline,
          label: 'Chat',
        ),
        _ShellNavItem(
          activeIcon: Icons.person,
          inactiveIcon: Icons.person_outline,
          label: 'Profile',
        ),
      ],
      child: child,
    );
  }
}

class WorkerAppShell extends StatelessWidget {
  const WorkerAppShell({required this.child, super.key});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/worker/orders')) return 1;
    if (location.startsWith('/worker/chat')) return 2;
    if (location.startsWith('/worker/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/worker');
      case 1:
        context.go('/worker/orders');
      case 2:
        context.go('/worker/chat');
      case 3:
        context.go('/worker/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ShellScaffold(
      isWorker: true,
      selectedIndex: _selectedIndex(context),
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        _ShellNavItem(
          activeIcon: Icons.home,
          inactiveIcon: Icons.home_outlined,
          label: 'Home',
        ),
        _ShellNavItem(
          activeIcon: Icons.handyman,
          inactiveIcon: Icons.handyman_outlined,
          label: 'Orders',
        ),
        _ShellNavItem(
          activeIcon: Icons.chat_bubble,
          inactiveIcon: Icons.chat_bubble_outline,
          label: 'Chat',
        ),
        _ShellNavItem(
          activeIcon: Icons.person,
          inactiveIcon: Icons.person_outline,
          label: 'Profile',
        ),
      ],
      child: child,
    );
  }
}

class _ShellScaffold extends StatefulWidget {
  const _ShellScaffold({
    required this.child,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    required this.isWorker,
  });

  final Widget child;
  final List<_ShellNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isWorker;

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold> {
  final _chatRepository = getIt<ChatRepository>();
  final Map<String, DateTime?> _lastMessageTimes = {};

  Timer? _chatPollTimer;
  ChatConversation? _popupConversation;

  @override
  void initState() {
    super.initState();
    unawaited(_primeChatSnapshot());
    _chatPollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_pollChatUpdates()),
    );
  }

  @override
  void dispose() {
    _chatPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _primeChatSnapshot() async {
    final result = await _chatRepository.getChatList(isWorker: widget.isWorker);
    result.fold((_) {}, (items) {
      for (final item in items) {
        _lastMessageTimes[item.orderId] = item.lastMessageTime;
      }
    });
  }

  Future<void> _pollChatUpdates() async {
    final result = await _chatRepository.getChatList(isWorker: widget.isWorker);
    if (!mounted) return;

    result.fold((_) {}, (items) {
      ChatConversation? newest;

      for (final item in items) {
        final previous = _lastMessageTimes[item.orderId];
        final current = item.lastMessageTime;
        _lastMessageTimes[item.orderId] = current;

        if (current == null) continue;

        final isNew = current.toUtc().isAfter(
              DateTime.now().toUtc().subtract(const Duration(seconds: 30)),
            );
        bool shouldShow = false;

        if (previous == null) {
          if (isNew) {
            shouldShow = true;
          }
        } else if (current.isAfter(previous)) {
          shouldShow = true;
        }

        if (shouldShow) {
          if (newest == null ||
              current.isAfter(
                newest.lastMessageTime ??
                    DateTime.fromMillisecondsSinceEpoch(0),
              )) {
            newest = item;
          }
        }
      }

      if (newest == null || _isOnChatRoute()) return;

      setState(() => _popupConversation = newest);
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (!mounted || _popupConversation?.orderId != newest!.orderId) return;
        setState(() => _popupConversation = null);
      });
    });
  }

  bool _isOnChatRoute() {
    final location = GoRouterState.of(context).uri.path;
    return widget.isWorker
        ? location.startsWith('/worker/chat')
        : location.startsWith('/chat');
  }

  void _openPopupConversation() {
    final conversation = _popupConversation;
    if (conversation == null) return;

    setState(() => _popupConversation = null);
    final path = widget.isWorker
        ? '/worker/chat/${conversation.orderId}'
        : '/chat/${conversation.orderId}';
    context.push(path, extra: conversation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          widget.child,
          Positioned(
            left: 14,
            right: 14,
            bottom: 78 + MediaQuery.paddingOf(context).bottom,
            child: _ChatPopup(
              conversation: _popupConversation,
              onTap: _openPopupConversation,
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(widget.items.length, (index) {
                final item = widget.items[index];
                final selected = index == widget.selectedIndex;
                final color = selected
                    ? const Color(0xFF00758A)
                    : const Color(0xFF8E8E93);
                return Expanded(
                  child: InkWell(
                    onTap: () => widget.onTap(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.inactiveIcon,
                          color: color,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatPopup extends StatelessWidget {
  const _ChatPopup({required this.conversation, required this.onTap});

  final ChatConversation? conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visible = conversation != null;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 1.4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          opacity: visible ? 1 : 0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E9F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFE8EEF5),
                      backgroundImage: conversation?.workerAvatarUrl != null
                          ? NetworkImage(conversation!.workerAvatarUrl!)
                          : null,
                      child: conversation?.workerAvatarUrl == null
                          ? const Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation?.workerName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            conversation?.lastMessage ?? 'Pesan baru',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chat_bubble,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellNavItem {
  const _ShellNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });

  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
}
