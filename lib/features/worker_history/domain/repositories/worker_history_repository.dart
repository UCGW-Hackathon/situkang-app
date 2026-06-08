import 'package:situkang_app/core/error/result.dart';
import 'package:situkang_app/core/constants/enums.dart';

import '../../../orders/domain/entities/order.dart';
import '../entities/worker_statistics.dart';

abstract class WorkerHistoryRepository {
  Future<Result<List<Order>>> getHistory({
    required OrderStatus? status,
    required int page,
  });

  Future<Result<WorkerStatistics>> getStatistics({
    required String timeRange, // 'week', 'month', 'year', 'all'
  });
}
