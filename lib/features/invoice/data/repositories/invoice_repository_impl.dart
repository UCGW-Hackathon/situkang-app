import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:situkang_app/core/error/result.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_data_source.dart';

@LazySingleton(as: InvoiceRepository)
class InvoiceRepositoryImpl implements InvoiceRepository {
  const InvoiceRepositoryImpl(this.remoteDataSource);

  final InvoiceRemoteDataSource remoteDataSource;

  @override
  Future<Result<Invoice>> getInvoice({required String orderId}) async {
    try {
      final invoice = await remoteDataSource.getInvoice(orderId);
      return Right(invoice);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Invoice>> confirmPayment({
    required String orderId,
    required String paymentMethod,
  }) async {
    try {
      final invoice =
          await remoteDataSource.confirmPayment(orderId, paymentMethod);
      return Right(invoice);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Invoice>> uploadPaymentProof({
    required String orderId,
    required File proofImage,
  }) async {
    try {
      final invoice =
          await remoteDataSource.uploadPaymentProof(orderId, proofImage);
      return Right(invoice);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<String>> downloadInvoicePdf(
      {required String orderId}) async {
    try {
      final url = await remoteDataSource.downloadInvoicePdf(orderId);
      return Right(url);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
