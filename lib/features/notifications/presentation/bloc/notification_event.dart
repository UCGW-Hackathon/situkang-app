part of 'notification_bloc.dart';

sealed class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class FetchNotifications extends NotificationEvent {}

class LoadMoreNotifications extends NotificationEvent {}

class FilterNotifications extends NotificationEvent {
  const FilterNotifications(this.type);

  final String? type;

  @override
  List<Object?> get props => [type];
}

class MarkNotificationAsRead extends NotificationEvent {
  const MarkNotificationAsRead(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsAsRead extends NotificationEvent {}

class FetchUnreadCount extends NotificationEvent {}

class NewNotificationEvent extends NotificationEvent {
  const NewNotificationEvent(this.notification);
  final NotificationEntity notification;
  @override
  List<Object?> get props => [notification];
}
