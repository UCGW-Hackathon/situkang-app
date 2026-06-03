import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/rating_bloc.dart';

/// Page for submitting a rating and review after an order is completed.
///
/// Validates: Requirements 13.1-13.6
class RatingPage extends StatefulWidget {
  const RatingPage({
    super.key,
    required this.orderId,
    required this.workerId,
    required this.workerName,
    this.workerAvatarUrl,
  });

  final String orderId;
  final String workerId;
  final String workerName;
  final String? workerAvatarUrl;

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int _score = 0;
  final _commentController = TextEditingController();
  final List<String> _selectedTags = [];

  static const _availableTags = [
    'Cepat',
    'Rapi',
    'Profesional',
    'Ramah',
    'Paham Masalah',
  ];

  @override
  void initState() {
    super.initState();
    context.read<RatingBloc>().add(CheckExistingRating(orderId: widget.orderId));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beri Nilai'),
      ),
      body: BlocConsumer<RatingBloc, RatingState>(
        listener: (context, state) {
          if (state is RatingSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Terima kasih atas penilaian Anda!'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is RatingSubmitError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RatingLoading) {
            return const LoadingIndicator();
          }

          if (state is RatingError) {
            return AppErrorWidget(
              message: state.failure.message,
              onRetry: () {
                context
                    .read<RatingBloc>()
                    .add(CheckExistingRating(orderId: widget.orderId));
              },
            );
          }

          if (state is RatingSubmitted) {
            return _buildSubmittedView(state);
          }

          final isSubmitting = state is RatingSubmitting;

          return SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildWorkerInfo(),
                const SizedBox(height: AppSpacing.lg),
                
                Text(
                  'Bagaimana hasil kerja tukang?',
                  style: AppTypography.h5,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                
                RatingStars.input(
                  rating: _score.toDouble(),
                  size: AppSizing.iconXxl,
                  onRatingChanged: (score) {
                    setState(() {
                      _score = score;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_score > 0) ...[
                  _buildTagsSection(),
                  const SizedBox(height: AppSpacing.md),
                  
                  AppTextField(
                    controller: _commentController,
                    label: 'Komentar (Opsional)',
                    hint: 'Ceritakan pengalaman Anda menggunakan jasa tukang ini...',
                    maxLines: 4,
                    maxLength: 1000,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Kirim Penilaian',
                      isLoading: isSubmitting,
                      onPressed: () {
                        context.read<RatingBloc>().add(
                          SubmitRating(
                            orderId: widget.orderId,
                            workerId: widget.workerId,
                            score: _score,
                            comment: _commentController.text.trim(),
                            tags: _selectedTags,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkerInfo() {
    return Column(
      children: [
        CircleAvatar(
          radius: AppSizing.avatarLg / 2,
          backgroundImage: widget.workerAvatarUrl != null
              ? NetworkImage(widget.workerAvatarUrl!)
              : null,
          child: widget.workerAvatarUrl == null
              ? const Icon(Icons.person, size: AppSizing.iconLg)
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.workerName,
          style: AppTypography.h6,
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Apa yang Anda sukai?', style: AppTypography.label),
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
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmittedView(RatingSubmitted state) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: AppSizing.iconXxl,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Penilaian Terkirim', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Terima kasih telah memberikan penilaian untuk ${widget.workerName}.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Read-only display of what they submitted
            AppCard(
              child: Column(
                children: [
                  RatingStars(
                    rating: state.rating.score.toDouble(),
                    size: AppSizing.iconLg,
                  ),
                  if (state.rating.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      alignment: WrapAlignment.center,
                      children: state.rating.tags.map((tag) => Chip(
                        label: Text(tag, style: AppTypography.caption),
                        backgroundColor: AppColors.surfaceVariant,
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  ],
                  if (state.rating.comment != null && state.rating.comment!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '"${state.rating.comment}"',
                      style: AppTypography.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'Kembali ke Pesanan',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
