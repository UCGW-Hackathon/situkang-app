import 'package:situkang_app/core/error/result.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/worker_purchase_repository.dart';
import '../datasources/worker_purchase_remote_data_source.dart';

@LazySingleton(as: WorkerPurchaseRepository)
class WorkerPurchaseRepositoryImpl implements WorkerPurchaseRepository {
  const WorkerPurchaseRepositoryImpl(this.remoteDataSource);

  final WorkerPurchaseRemoteDataSource remoteDataSource;

  @override
  Future<Result<Purchase>> addPurchase({
    required String orderId,
    required String itemName,
    required String category,
    required int quantity,
    required String unit,
    required int unitPrice,
    required int totalPrice,
    String? reason,
    String? receiptPhotoPath,
  }) async {
    try {
      final purchase = await remoteDataSource.addPurchase(
        orderId: orderId,
        itemName: itemName,
        category: category,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        reason: reason,
        receiptPhotoPath: receiptPhotoPath,
      );
      return Right(purchase.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<List<Purchase>>> processAiInput({
    required String orderId,
    required String rawText,
  }) async {
    try {
      final purchases = await remoteDataSource.processAiInput(orderId, rawText);
      return Right(purchases.map((m) => m.toEntity()).toList());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<List<Purchase>>> scanReceipt({
    required String orderId,
    required String photoPath,
  }) async {
    try {
      final purchases = await remoteDataSource.scanReceipt(orderId, photoPath);
      return Right(purchases.map((m) => m.toEntity()).toList());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Purchase>> submitForApproval({
    required String orderId,
    required String purchaseId,
  }) async {
    try {
      final purchase = await remoteDataSource.submitForApproval(orderId, purchaseId);
      return Right(purchase.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> deleteDraft({
    required String orderId,
    required String purchaseId,
  }) async {
    try {
      await remoteDataSource.deleteDraft(orderId, purchaseId);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Purchase>> respondToClarification({
    required String orderId,
    required String purchaseId,
    required String responseText,
    String? updatedItemName,
    String? updatedReason,
  }) async {
    try {
      final purchase = await remoteDataSource.respondToClarification(
        orderId: orderId,
        purchaseId: purchaseId,
        responseText: responseText,
        updatedItemName: updatedItemName,
        updatedReason: updatedReason,
      );
      return Right(purchase.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
