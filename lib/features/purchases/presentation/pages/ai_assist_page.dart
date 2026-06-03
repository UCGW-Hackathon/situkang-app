import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/worker_purchase_bloc.dart';

class AiAssistPage extends StatefulWidget {
  const AiAssistPage({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<AiAssistPage> createState() => _AiAssistPageState();
}

class _AiAssistPageState extends State<AiAssistPage> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _processAi() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan teks terlebih dahulu')),
      );
      return;
    }

    context.read<WorkerPurchaseBloc>().add(
      ProcessAiPurchase(orderId: widget.orderId, rawText: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bantu Rapikan dengan AI'),
      ),
      body: BlocConsumer<WorkerPurchaseBloc, WorkerPurchaseState>(
        listener: (context, state) {
          if (state is WorkerPurchaseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is WorkerPurchaseBatchSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Berhasil memproses ${state.purchases.length} item.'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop(); // Go back to draft list
          }
        },
        builder: (context, state) {
          final isProcessing = state is WorkerPurchaseAiProcessing;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Ketik saja barang yang kamu beli secara bebas, AI kami akan merapikannya menjadi daftar belanja otomatis.',
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AppTextField(
                      controller: _textController,
                      label: 'Deskripsi Belanja',
                      hint: 'Contoh: Tadi beli semen gresik 2 sak harganya 50rb per sak, terus paku beton 1kg 15rb...',
                      maxLines: 8,
                      maxLength: 2000,
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      text: 'Proses dengan AI',
                      icon: Icons.auto_awesome,
                      onPressed: isProcessing ? null : _processAi,
                    ),
                  ],
                ),
              ),
              if (isProcessing)
                Container(
                  color: Colors.black12,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const LoadingIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'AI sedang memproses catatanmu...',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
