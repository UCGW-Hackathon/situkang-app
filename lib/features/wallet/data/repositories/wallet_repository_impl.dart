import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:situkang_app/core/error/result.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/wallet_entities.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this.remoteDataSource);

  final WalletRemoteDataSource remoteDataSource;

  @override
  Future<Result<WalletSummary>> getWalletSummary() async {
    try {
      final summary = await remoteDataSource.getWalletSummary();
      return Right(summary);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<List<WalletTransaction>>> getTransactions({
    required int page,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await remoteDataSource.getTransactions(
        page: page,
        type: type,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(transactions);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> requestWithdrawal({
    required int amount,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    try {
      await remoteDataSource.requestWithdrawal(
        amount: amount,
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
      );
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
