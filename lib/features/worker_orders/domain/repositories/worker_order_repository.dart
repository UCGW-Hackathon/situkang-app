import '../../../../core/error/result.dart';
import '../../../invoice/domain/entities/invoice.dart';
import '../entities/invoice_material_input.dart';
import '../entities/worker_order_detail.dart';

/// Repository interface for a worker managing an active order.
abstract class WorkerOrderRepository {
  /// Fetches the worker-facing detail brief for an order.
  Future<Result<WorkerOrderDetail>> getOrderDetail(String orderId);

  /// Accepts a pending order assigned to the current worker.
  Future<Result<void>> acceptOrder({
    required String orderId,
    int? estimatedArrivalMinutes,
  });

  /// Rejects a pending order offer.
  Future<Result<void>> rejectOrder({
    required String orderId,
    required String reasonCode,
  });

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
    List<InvoiceMaterialInput> materials = const [],
  });
}
