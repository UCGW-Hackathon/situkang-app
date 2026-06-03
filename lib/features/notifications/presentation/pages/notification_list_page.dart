import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notification_bloc.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(FetchNotifications());
    context.read<NotificationBloc>().add(FetchUnreadCount());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<NotificationBloc>().add(LoadMoreNotifications());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200);
  }

  Widget _buildFilterChips(String? currentType) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.pagePadding,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Semua'),
            selected: currentType == null,
            onSelected: (selected) {
              if (selected) {
                context.read<NotificationBloc>().add(const FilterNotifications(null));
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Pembelian'),
            selected: currentType == 'purchase',
            onSelected: (selected) {
              if (selected) {
                context.read<NotificationBloc>().add(const FilterNotifications('purchase'));
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Promo'),
            selected: currentType == 'promo',
            onSelected: (selected) {
              if (selected) {
                context.read<NotificationBloc>().add(const FilterNotifications('promo'));
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Chat'),
            selected: currentType == 'chat',
            onSelected: (selected) {
              if (selected) {
                context.read<NotificationBloc>().add(const FilterNotifications('chat'));
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Pesanan'),
            selected: currentType == 'order',
            onSelected: (selected) {
              if (selected) {
                context.read<NotificationBloc>().add(const FilterNotifications('order'));
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Pembayaran'),
            selected: currentType == 'payment',
            onSelected: (selected) {
              if (selected) {
                context.read<NotificationBloc>().add(const FilterNotifications('payment'));
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Sistem'),
            selected: currentType == 'system',
            onSelected: (selected) {
              if (selected) {
                context.read<NotificationBloc>().add(const FilterNotifications('system'));
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationEntity notification) {
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(MarkNotificationAsRead(notification.id));
    }
    
    if (notification.targetId == null) return;
    
    // Route based on type
    switch (notification.type) {
      case 'order':
        context.push('/orders/');
        break;
      case 'chat':
        context.push('/chat/');
        break;
      case 'payment':
        context.push('/invoice/');
        break;
      case 'purchase':
        context.push('/purchases/');
        break;
      case 'promo':
        // Custom promo page doesn't exist yet, ignore
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(MarkAllNotificationsAsRead());
                  },
                  child: const Text('Tandai Dibaca'),
                );
              }
              return const SizedBox.shrink();
            },
          )
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStatus.initial || 
              (state.status == NotificationStatus.loading && state.notifications.isEmpty)) {
            return Column(
              children: [
                _buildFilterChips(state.filterType),
                const Expanded(child: Center(child: LoadingIndicator())),
              ],
            );
          }

          if (state.status == NotificationStatus.error && state.notifications.isEmpty) {
            return Column(
              children: [
                _buildFilterChips(state.filterType),
                Expanded(
                  child: AppErrorWidget(
                    message: state.failure?.message ?? 'Terjadi kesalahan',
                    onRetry: () => context.read<NotificationBloc>().add(FetchNotifications()),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildFilterChips(state.filterType),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<NotificationBloc>().add(FetchNotifications());
                    context.read<NotificationBloc>().add(FetchUnreadCount());
                  },
                  child: state.notifications.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('Tidak ada notifikasi.')),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          itemCount: state.hasReachedMax
                              ? state.notifications.length
                              : state.notifications.length + 1,
                          itemBuilder: (context, index) {
                            if (index >= state.notifications.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Center(child: LoadingIndicator()),
                              );
                            }
                            
                            final notification = state.notifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'order':
        icon = Icons.assignment;
        iconColor = AppColors.primary;
        break;
      case 'payment':
        icon = Icons.payment;
        iconColor = AppColors.success;
        break;
      case 'chat':
        icon = Icons.chat;
        iconColor = AppColors.secondary;
        break;
      case 'promo':
        icon = Icons.local_offer;
        iconColor = AppColors.warning;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppColors.textSecondary;
        break;
    }

    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.surface : AppColors.primaryContainer.withValues(alpha: 0.3),
          border: const Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(notification.createdAt),
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.body,
                    style: AppTypography.bodySmall.copyWith(
                      color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
