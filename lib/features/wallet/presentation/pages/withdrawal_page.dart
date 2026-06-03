import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/wallet_bloc.dart';

class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({
    super.key,
    required this.availableBalance,
  });

  final int availableBalance;

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  final NumberFormat _formatter = NumberFormat('#,###', 'id');
  
  int _amount = 0;

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<WalletBloc>().add(
        RequestWithdrawal(
          amount: _amount,
          bankName: _bankNameController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          accountHolderName: _accountHolderNameController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarik Dana'),
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state.withdrawStatus == WalletStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure?.message ?? 'Gagal memproses penarikan'),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state.withdrawStatus == WalletStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permintaan penarikan berhasil diajukan.'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          final isLoading = state.withdrawStatus == WalletStatus.loading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        color: AppColors.primaryContainer,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Saldo Tersedia', style: AppTypography.bodyMedium),
                            Text(
                              'Rp${_formatter.format(widget.availableBalance)}',
                              style: AppTypography.h6.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      Text('Nominal Penarikan', style: AppTypography.label),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _amountController,
                        hint: 'Min. Rp50.000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Rp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _amount = int.tryParse(val) ?? 0;
                          });
                        },
                        validator: (val) {
                          final amount = int.tryParse(val ?? '') ?? 0;
                          if (amount < 50000) {
                            return 'Minimal penarikan Rp50.000';
                          }
                          if (amount > widget.availableBalance) {
                            return 'Saldo tidak mencukupi';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Biaya Admin:', style: AppTypography.caption),
                          Text('Rp0 (Gratis)', style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      const Divider(),
                      const SizedBox(height: AppSpacing.xl),
                      
                      Text('Informasi Rekening', style: AppTypography.h6),
                      const SizedBox(height: AppSpacing.md),
                      
                      AppTextField(
                        controller: _bankNameController,
                        label: 'Nama Bank / E-Wallet',
                        hint: 'BCA, Mandiri, GoPay, OVO, dll',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      AppTextField(
                        controller: _accountNumberController,
                        label: 'Nomor Rekening / No. HP',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      AppTextField(
                        controller: _accountHolderNameController,
                        label: 'Nama Pemilik Rekening',
                        hint: 'Sesuai di buku tabungan / aplikasi',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      AppButton(
                        text: 'Tarik Rp${_formatter.format(_amount > 0 ? _amount : 0)}',
                        onPressed: (_amount >= 50000 && _amount <= widget.availableBalance && !isLoading) 
                            ? _submit 
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black12,
                  child: const Center(child: LoadingIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
