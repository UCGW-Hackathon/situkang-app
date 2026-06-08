import 'package:situkang_app/core/error/result.dart';

import '../entities/wallet_entities.dart';

abstract class WalletRepository {
  Future<Result<WalletSummary>> getWalletSummary();

  Future<Result<List<WalletTransaction>>> getTransactions({
    required int page,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Result<void>> requestWithdrawal({
    required int amount,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  });
}
