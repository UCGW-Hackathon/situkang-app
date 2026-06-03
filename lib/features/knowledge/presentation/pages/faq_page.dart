import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/knowledge_entities.dart';
import '../bloc/faq_bloc.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  @override
  void initState() {
    super.initState();
    context.read<FaqBloc>().add(FetchFaqs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
      ),
      body: BlocBuilder<FaqBloc, FaqState>(
        builder: (context, state) {
          if (state.status == FaqStatus.loading) {
            return const Center(child: LoadingIndicator());
          }

          if (state.status == FaqStatus.error) {
            return AppErrorWidget(
              message: state.failure?.message ?? 'Gagal memuat FAQ',
              onRetry: () => context.read<FaqBloc>().add(FetchFaqs()),
            );
          }

          if (state.faqs.isEmpty) {
            return const Center(child: Text('Belum ada FAQ.'));
          }

          // Group by category
          final Map<String, List<Faq>> groupedFaqs = {};
          for (final faq in state.faqs) {
            if (!groupedFaqs.containsKey(faq.category)) {
              groupedFaqs[faq.category] = [];
            }
            groupedFaqs[faq.category]!.add(faq);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: groupedFaqs.length,
            itemBuilder: (context, index) {
              final category = groupedFaqs.keys.elementAt(index);
              final categoryFaqs = groupedFaqs[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      _getCategoryName(category),
                      style: AppTypography.h6.copyWith(color: AppColors.primary),
                    ),
                  ),
                  ...categoryFaqs.map((faq) => _buildFaqItem(faq)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFaqItem(Faq faq) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            faq.answer,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String id) {
    switch (id) {
      case 'general':
        return 'Umum';
      case 'payment':
        return 'Pembayaran';
      case 'order':
        return 'Pesanan';
      case 'account':
        return 'Akun';
      default:
        return id;
    }
  }
}
