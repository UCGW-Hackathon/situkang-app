import 'package:situkang_app/core/error/result.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Result<List<NotificationEntity>>> getNotifications({
    required int page,
    String? type,
  });

  Future<Result<void>> markAsRead(String id);
  
  Future<Result<void>> markAllAsRead();
  
  Future<Result<int>> getUnreadCount();
}
