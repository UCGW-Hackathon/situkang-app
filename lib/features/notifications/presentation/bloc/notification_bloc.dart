import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/websocket_events.dart';
import '../../../../core/network/websocket_manager.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

@injectable
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(this.repository, this.webSocketManager)
      : super(const NotificationState()) {
    on<FetchNotifications>(_onFetchNotifications);
    on<LoadMoreNotifications>(_onLoadMoreNotifications);
    on<FilterNotifications>(_onFilterNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<FetchUnreadCount>(_onFetchUnreadCount);

    _wsSubscription = webSocketManager.eventStream.listen((event) {
      if (event is NewNotificationEvent) {
        add(FetchUnreadCount());
        // Could also add it to the top of the list or refetch
      }
    });
  }

  final NotificationRepository repository;
  final WebSocketManager webSocketManager;
  StreamSubscription<WebSocketEvent>? _wsSubscription;

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFetchNotifications(
    FetchNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading, page: 1));

    final result = await repository.getNotifications(
      page: 1,
      type: state.filterType,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationStatus.error,
        failure: failure,
      )),
      (notifications) => emit(state.copyWith(
        status: NotificationStatus.success,
        notifications: notifications,
        hasReachedMax: notifications.isEmpty,
      )),
    );
  }

  Future<void> _onLoadMoreNotifications(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.hasReachedMax || state.status == NotificationStatus.loading) return;

    final nextPage = state.page + 1;
    final result = await repository.getNotifications(
      page: nextPage,
      type: state.filterType,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationStatus.error,
        failure: failure,
      )),
      (notifications) {
        emit(notifications.isEmpty
            ? state.copyWith(hasReachedMax: true)
            : state.copyWith(
                status: NotificationStatus.success,
                notifications: List.of(state.notifications)..addAll(notifications),
                page: nextPage,
                hasReachedMax: false,
              ));
      },
    );
  }

  Future<void> _onFilterNotifications(
    FilterNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(filterType: event.type));
    add(FetchNotifications());
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await repository.markAsRead(event.id);
    
    result.fold(
      (failure) {
        // Just silently fail or log it
      },
      (_) {
        // Update local state
        final updatedList = state.notifications.map((n) {
          if (n.id == event.id) {
            return NotificationEntity(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              createdAt: n.createdAt,
              isRead: true,
              targetId: n.targetId,
            );
          }
          return n;
        }).toList();
        
        emit(state.copyWith(
          notifications: updatedList,
          unreadCount: (state.unreadCount > 0) ? state.unreadCount - 1 : 0,
        ));
      },
    );
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await repository.markAllAsRead();
    
    result.fold(
      (failure) {},
      (_) {
        // Update local state
        final updatedList = state.notifications.map((n) {
          return NotificationEntity(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            createdAt: n.createdAt,
            isRead: true,
            targetId: n.targetId,
          );
        }).toList();
        
        emit(state.copyWith(
          notifications: updatedList,
          unreadCount: 0,
        ));
      },
    );
  }

  Future<void> _onFetchUnreadCount(
    FetchUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await repository.getUnreadCount();
    
    result.fold(
      (failure) {},
      (count) {
        emit(state.copyWith(unreadCount: count));
      },
    );
  }
}
