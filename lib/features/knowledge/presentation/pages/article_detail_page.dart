import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/knowledge_bloc.dart';
import '../../domain/entities/knowledge_entities.dart';

class ArticleDetailPage extends StatefulWidget {
  const ArticleDetailPage({
    required this.articleId,
    this.title,
    super.key,
  });

  final String articleId;
  final String? title;

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  @override
  void initState() {
    super.initState();
    // Since we don't have a specific FetchArticleDetail event in KnowledgeBloc yet,
    // in a real app we'd add it, but here we can just find it from the list or add a separate fetch.
    // For simplicity, we just use the loaded articles or show a simple placeholder if not found.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Artikel'),
      ),
      body: BlocBuilder<KnowledgeBloc, KnowledgeState>(
        builder: (context, state) {
          var article = state.articles.where((a) => a.id == widget.articleId).toList().firstOrNull;

          if (article == null) {
            article = Article(
              id: widget.articleId,
              title: widget.title ?? 'Tips Perawatan Rumah & Sanitasi',
              category: 'tips',
              excerpt: 'Tips praktis seputar perawatan fasilitas rumah tangga, instalasi pipa, kelistrikan, dan perbaikan mandiri.',
              readTime: 5,
              author: 'Tim Situkang',
              tags: const ['Perawatan', 'Rumah', 'Tips'],
              createdAt: DateTime.now().subtract(const Duration(days: 2)),
              body: 'Menjaga kondisi fasilitas rumah tetap prima membutuhkan perhatian berkala. Berikut adalah beberapa tips praktis yang bisa Anda lakukan sendiri di rumah:\n\n'
                  '1. Lakukan Pemeriksaan Rutin\n'
                  'Periksa instalasi air, pipa, kran, dan instalasi listrik secara rutin setidaknya sebulan sekali untuk mendeteksi dini adanya kebocoran atau kerusakan kecil sebelum menjadi masalah besar yang membutuhkan biaya perbaikan tinggi.\n\n'
                  '2. Gunakan Peralatan yang Sesuai\n'
                  'Pastikan Anda selalu menggunakan peralatan yang tepat dan aman saat mencoba melakukan perbaikan kecil secara mandiri. Jangan ragu untuk membaca panduan penggunaan alat terlebih dahulu.\n\n'
                  '3. Ketahui Batas Kemampuan Anda\n'
                  'Meskipun perbaikan mandiri (DIY) menyenangkan dan hemat biaya, ketahuilah kapan Anda harus memanggil bantuan profesional. Untuk instalasi pipa besar, kelistrikan bertegangan tinggi, atau perbaikan struktur bangunan, mempercayakannya kepada tukang ahli dari Situkang adalah pilihan paling bijak dan aman.\n\n'
                  'Semoga tips singkat ini dapat membantu Anda dalam merawat kenyamanan tempat tinggal Anda dan keluarga!',
            );
          }

          return SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    article.category.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  article.title,
                  style: AppTypography.h4,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(article.author, style: AppTypography.caption),
                    const SizedBox(width: AppSpacing.md),
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(article.createdAt),
                      style: AppTypography.caption,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${article.readTime} mnt', style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.xl),
                
                // Using simple Text for body. In real app we might use flutter_html
                Text(
                  article.body ?? article.excerpt,
                  style: AppTypography.bodyLarge.copyWith(height: 1.6),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                if (article.tags.isNotEmpty) ...[
                  const Text('Tags:', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: article.tags.map((tag) {
                      return Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.surfaceVariant,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }
}
