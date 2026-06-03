part of 'notification_bloc.dart';

enum NotificationStatus { initial, loading, success, error }

class NotificationState extends Equatable {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const <NotificationEntity>[],
    this.hasReachedMax = false,
    this.page = 1,
    this.filterType,
    this.unreadCount = 0,
    this.failure,
  });

  final NotificationStatus status;
  final List<NotificationEntity> notifications;
  final bool hasReachedMax;
  final int page;
  final String? filterType;
  final int unreadCount;
  final Failure? failure;

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationEntity>? notifications,
    bool? hasReachedMax,
    int? page,
    String? filterType,
    int? unreadCount,
    Failure? failure,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      filterType: filterType ?? this.filterType,
      unreadCount: unreadCount ?? this.unreadCount,
      failure: failure, // null by default when copying unless explicitly passed
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        hasReachedMax,
        page,
        filterType,
        unreadCount,
        failure,
      ];
}
