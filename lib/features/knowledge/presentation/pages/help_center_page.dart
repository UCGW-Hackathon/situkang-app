import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/knowledge_entities.dart';
import '../bloc/knowledge_bloc.dart';
import 'article_detail_page.dart';
import 'faq_page.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  final List<Map<String, dynamic>> _categories = [
    {'id': null, 'name': 'Semua', 'icon': Icons.list},
    {'id': 'guide', 'name': 'Panduan', 'icon': Icons.menu_book},
    {'id': 'tips', 'name': 'Tips', 'icon': Icons.lightbulb},
    {'id': 'safety', 'name': 'Keamanan', 'icon': Icons.security},
    {'id': 'payment', 'name': 'Pembayaran', 'icon': Icons.payment},
  ];

  @override
  void initState() {
    super.initState();
    context.read<KnowledgeBloc>().add(FetchArticles());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<KnowledgeBloc>().add(LoadMoreArticles());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<KnowledgeBloc>().add(SearchArticles(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: AppSpacing.pagePadding,
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ada yang bisa kami bantu?',
                  style: AppTypography.h5.copyWith(color: AppColors.onPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _searchController,
                  hint: 'Cari topik bantuan...',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: _onSearchChanged,
                  
                ),
              ],
            ),
          ),
          
          Expanded(
            child: BlocBuilder<KnowledgeBloc, KnowledgeState>(
              builder: (context, state) {
                // Determine if we are searching
                if (state.isSearch && state.searchQuery.isNotEmpty) {
                  return _buildSearchResults(state);
                }

                return _buildMainContent(state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(KnowledgeState state) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        title: 'FAQ',
                        subtitle: 'Pertanyaan umum',
                        icon: Icons.question_answer,
                        color: AppColors.secondary,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FaqPage()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildQuickActionCard(
                        title: 'Hubungi CS',
                        subtitle: 'Bantuan langsung',
                        icon: Icons.support_agent,
                        color: AppColors.success,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membuka obrolan dengan Customer Service...')));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                
                const Text('Kategori Topik', style: AppTypography.h6),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = state.filterCategory == cat['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(cat['name'] as String),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected || cat['id'] == null) {
                              context.read<KnowledgeBloc>().add(FilterArticles(cat['id'] as String?));
                            }
                          },
                          avatar: Icon(cat['icon'] as IconData, size: 16),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text('Artikel Bantuan', style: AppTypography.h6),
              ],
            ),
          ),
        ),
        
        // Articles List
        if (state.status == KnowledgeStatus.loading && state.articles.isEmpty)
          const SliverFillRemaining(
            child: Center(child: LoadingIndicator()),
          )
        else if (state.status == KnowledgeStatus.error && state.articles.isEmpty)
          SliverFillRemaining(
            child: AppErrorWidget(
              message: state.failure?.message ?? 'Gagal memuat artikel',
              onRetry: () => context.read<KnowledgeBloc>().add(FetchArticles()),
            ),
          )
        else if (state.articles.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('Belum ada artikel di kategori ini.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= state.articles.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(child: LoadingIndicator()),
                    );
                  }
                  return _buildArticleCard(state.articles[index]);
                },
                childCount: state.hasReachedMax
                    ? state.articles.length
                    : state.articles.length + 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults(KnowledgeState state) {
    if (state.status == KnowledgeStatus.loading) {
      return const Center(child: LoadingIndicator());
    }

    if (state.status == KnowledgeStatus.error) {
      return AppErrorWidget(
        message: state.failure?.message ?? 'Gagal melakukan pencarian',
        onRetry: () => context.read<KnowledgeBloc>().add(SearchArticles(state.searchQuery)),
      );
    }

    if (state.articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tidak menemukan hasil untuk "${state.searchQuery}"',
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Coba gunakan kata kunci lain.',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.articles.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'Hasil pencarian untuk "${state.searchQuery}"',
              style: AppTypography.label,
            ),
          );
        }
        return _buildArticleCard(state.articles[index - 1]);
      },
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(Article article) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailPage(articleId: article.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getCategoryName(article.category),
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${article.readTime} mnt', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(article.title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            article.excerpt,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String id) {
    final category = _categories.firstWhere(
      (c) => c['id'] == id,
      orElse: () => {'name': id},
    );
    return category['name'] as String;
  }
}
