import '../../../../core/error/result.dart';
import '../../../invoice/domain/entities/invoice.dart';

/// Repository interface for a worker managing an active order.
abstract class WorkerOrderRepository {
  /// Updates the status of the active order (e.g., on_the_way, arrived, in_progress, completed).
  Future<Result<void>> updateOrderStatus({
    required String orderId,
    required String status,
  });

  /// Uploads a progress or completion photo for the order.
  Future<Result<void>> uploadProgressPhoto({
    required String orderId,
    required String filePath,
    String? caption,
  });

  /// Adds a new work item/material to the order, which affects the final invoice.
  Future<Result<void>> addWorkItem({
    required String orderId,
    required String itemName,
    required int cost,
    String? description,
  });

  /// Completes the order and generates the initial invoice.
  Future<Result<Invoice>> completeOrder({
    required String orderId,
    String? workerNotes,
  });
}
