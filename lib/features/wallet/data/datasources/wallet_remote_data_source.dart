import 'package:injectable/injectable.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/wallet_models.dart';

abstract class WalletRemoteDataSource {
  Future<WalletSummaryModel> getWalletSummary();
  Future<List<WalletTransactionModel>> getTransactions({
    required int page,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<void> requestWithdrawal({
    required int amount,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  });
}

@LazySingleton(as: WalletRemoteDataSource)
class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  const WalletRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<WalletSummaryModel> getWalletSummary() async {
    final response = await apiClient.get<Map<String, dynamic>>('/worker/wallet/summary');
    final apiResponse = ApiResponse<WalletSummaryModel>.fromJson(response.data!, fromJsonT: (json) => WalletSummaryModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<List<WalletTransactionModel>> getTransactions({
    required int page,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    final response = await apiClient.get<Map<String, dynamic>>(
      '/worker/wallet/transactions',
      queryParams: queryParams,
    );

    final apiResponse = ApiResponse<List<WalletTransactionModel>>.fromJson(response.data!, fromJsonT: (json) => (json as List)
          .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }

  @override
  Future<void> requestWithdrawal({
    required int amount,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    await apiClient.post<Map<String, dynamic>>(
      '/worker/wallet/withdraw',
      data: {
        'amount': amount,
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_holder_name': accountHolderName,
      },
    );
  }
}
