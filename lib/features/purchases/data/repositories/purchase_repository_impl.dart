import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/purchase_summary.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/purchase_remote_data_source.dart';

/// Implementation of [PurchaseRepository].
///
/// For purchase operations (approve, reject, clarify, bulk-approve):
/// always goes to the API since these are mutations.
/// For fetching purchases: fetches from API directly.
@LazySingleton(as: PurchaseRepository)
class PurchaseRepositoryImpl implements PurchaseRepository {
  const PurchaseRepositoryImpl({
    required this.remoteDataSource,
  });

  final PurchaseRemoteDataSource remoteDataSource;

  @override
  Future<Result<(List<Purchase>, PurchaseSummary)>> getPurchases(
      String orderId) async {
    try {
      final (purchaseModels, summaryModel) =
          await remoteDataSource.getPurchases(orderId);

      final purchases = purchaseModels.map((m) => m.toEntity()).toList();
      final summary = summaryModel.toEntity();

      return Right((purchases, summary));
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Purchase>> approvePurchase(
      String orderId, String purchaseId) async {
    try {
      final purchaseModel =
          await remoteDataSource.approvePurchase(orderId, purchaseId);
      return Right(purchaseModel.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Purchase>> rejectPurchase(
      String orderId, String purchaseId, String reason) async {
    try {
      final purchaseModel =
          await remoteDataSource.rejectPurchase(orderId, purchaseId, reason);
      return Right(purchaseModel.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Purchase>> requestClarification(
      String orderId, String purchaseId, String question) async {
    try {
      final purchaseModel = await remoteDataSource.requestClarification(
          orderId, purchaseId, question);
      return Right(purchaseModel.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<List<Purchase>>> bulkApprove(
      String orderId, List<String> purchaseIds) async {
    try {
      final purchaseModels =
          await remoteDataSource.bulkApprove(orderId, purchaseIds);
      return Right(purchaseModels.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  /// Maps [DioException] to typed [Failure] objects.
  Failure _mapDioExceptionToFailure(DioException exception) {
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.sendTimeout) {
      return const TimeoutFailure();
    }

    if (exception.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    final statusCode = exception.response?.statusCode ?? 500;
    final responseData = exception.response?.data;

    var message = 'Terjadi kesalahan pada server';
    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] as String? ?? message;
    }

    if (statusCode == 401 || statusCode == 403) {
      return AuthFailure(message);
    }

    if (statusCode == 404) {
      return ServerFailure('Pembelian tidak ditemukan', statusCode: statusCode);
    }

    if (statusCode == 422) {
      return ServerFailure(message, statusCode: statusCode);
    }

    return ServerFailure(message, statusCode: statusCode);
  }
}
