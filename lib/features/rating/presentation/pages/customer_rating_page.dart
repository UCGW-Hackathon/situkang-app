import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/worker_rating_bloc.dart';

class CustomerRatingPage extends StatefulWidget {
  const CustomerRatingPage({
    required this.orderId, required this.customerName, super.key,
  });

  final String orderId;
  final String customerName;

  @override
  State<CustomerRatingPage> createState() => _CustomerRatingPageState();
}

class _CustomerRatingPageState extends State<CustomerRatingPage> {
  double _rating = 0;
  final _commentController = TextEditingController();
  final List<String> _selectedTags = [];

  final List<String> _availableTags = [
    'Ramah',
    'Lokasi Akurat',
    'Pembayaran Cepat',
    'Responsif',
    'Kooperatif',
  ];

  @override
  void initState() {
    super.initState();
    context.read<WorkerRatingBloc>().add(FetchCustomerRating(widget.orderId));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan berikan rating (bintang) terlebih dahulu.')),
      );
      return;
    }

    context.read<WorkerRatingBloc>().add(
      SubmitCustomerRating(
        orderId: widget.orderId,
        rating: _rating,
        comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
        tags: _selectedTags,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penilaian Pelanggan'),
      ),
      body: BlocConsumer<WorkerRatingBloc, WorkerRatingState>(
        listener: (context, state) {
          if (state is WorkerRatingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is WorkerRatingSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Penilaian berhasil dikirim.'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state is WorkerRatingLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is WorkerRatingLoaded) {
            // Read only view
            final rating = state.rating;
            return SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.check_circle, size: 64, color: AppColors.success),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Anda sudah memberikan penilaian',
                    style: AppTypography.h6,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    child: Column(
                      children: [
                        Text('Pelanggan: ${widget.customerName}', style: AppTypography.bodyMedium),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating.score ? Icons.star : Icons.star_border,
                              color: AppColors.warning,
                              size: 40,
                            );
                          }),
                        ),
                        if (rating.tags.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            alignment: WrapAlignment.center,
                            children: rating.tags.map((tag) {
                              return Chip(
                                label: Text(tag, style: const TextStyle(fontSize: 12)),
                                backgroundColor: AppColors.primaryContainer,
                              );
                            }).toList(),
                          ),
                        ],
                        if (rating.comment != null && rating.comment!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                            ),
                            child: Text(
                              rating.comment!,
                              style: AppTypography.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: 'Kembali',
                    onPressed: () => context.pop(),
                  )
                ],
              ),
            );
          }

          // Submission form
          final isSubmitting = state is WorkerRatingSubmitting;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bagaimana pengalaman Anda dengan pelanggan\n${widget.customerName}?',
                      style: AppTypography.h6,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => _rating = index + 1.0);
                          },
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: AppColors.warning,
                            size: 48,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    
                    const Text('Apa yang Anda sukai? (Opsional)', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                          selectedColor: AppColors.primaryContainer,
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      controller: _commentController,
                      label: 'Ulasan Tambahan (Opsional)',
                      hint: 'Tuliskan ulasan Anda...',
                      maxLines: 4,
                      maxLength: 500,
                    ),
                    
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      text: 'Kirim Penilaian',
                      onPressed: isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ),
              
              if (isSubmitting)
                const ColoredBox(
                  color: Colors.black12,
                  child: Center(child: LoadingIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
