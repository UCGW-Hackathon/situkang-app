import 'package:situkang_app/core/error/result.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/worker_dashboard.dart';

/// Repository interface for worker home/dashboard operations.
abstract class WorkerHomeRepository {
  /// Fetches the current dashboard data for the authenticated worker.
  Future<Result<WorkerDashboard>> getDashboardData();

  /// Toggles the worker's availability status.
  /// Returns the new availability state.
  Future<Result<bool>> toggleAvailability({required bool isAvailable});
}
