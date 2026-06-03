import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/article_item.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/featured_worker.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/entities/promo_banner.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

const _teal = Color(0xFF00758A);
const _ink = Color(0xFF101A2D);
const _muted = Color(0xFF6F7B83);
const _softBg = Color(0xFFF6F7FC);
const _iconBg = Color(0xFFDCE9FF);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const FetchHomeData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const LoadingIndicator(message: 'Memuat beranda...');
          }

          if (state is HomeError) {
            return AppErrorWidget(
              message: state.failure.message,
              onRetry: () => context.read<HomeBloc>().add(
                    const FetchHomeData(),
                  ),
            );
          }

          if (state is HomeLoaded) {
            return _HomeContent(homeData: state.homeData);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.homeData});

  final HomeData homeData;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _teal,
      onRefresh: () async {
        context.read<HomeBloc>().add(const RefreshHomeData());
      },
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(36, 32, 36, 18),
                child: _Header(homeData: homeData),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(36, 24, 36, 28),
                child: _SearchBar(
                  onFilterTap: () => context.push('/workers'),
                  onTap: () => context.push('/workers'),
                ),
              ),
            ),
            if (homeData.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: _CategoriesSection(categories: homeData.categories),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: _PromoArticleStrip(
                  promos: homeData.promos,
                  articles: homeData.articles,
                ),
              ),
            ),
            if (homeData.featuredWorkers.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(36, 34, 36, 120),
                  child: _FeaturedWorkersSection(
                    workers: homeData.featuredWorkers,
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.homeData});

  final HomeData homeData;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(url: homeData.avatarUrl, size: 68),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat datang,',
                style: TextStyle(
                  color: Color(0xFF48535B),
                  fontSize: 16,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Halo, ${homeData.fullName}!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 178),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, color: _teal, size: 28),
                  Text(
                    'Lokasi saat ini',
                    style: TextStyle(
                      color: _teal,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                homeData.currentAddress,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF3D464D),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap, required this.onFilterTap});

  final VoidCallback onTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 78,
        padding: const EdgeInsets.only(left: 24, right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF68757D), size: 40),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Cari tukang atau jenis kerusakan...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF77838B),
                  fontSize: 22,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ),
            IconButton(
              onPressed: onFilterTap,
              icon: const Icon(Icons.tune, color: Colors.white, size: 34),
              style: IconButton.styleFrom(
                backgroundColor: _teal,
                fixedSize: const Size(44, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({required this.categories});

  final List<CategoryItem> categories;

  @override
  Widget build(BuildContext context) {
    final visible = categories.take(8).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          _SectionHeader(
            title: 'Kategori Jasa',
            action: 'Lihat Semua',
            onAction: () => context.push('/categories'),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 24,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              return _CategoryTile(category: visible[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final CategoryItem category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/workers'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: _iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _categoryIcon(category.name),
                color: _teal,
                size: 34,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF39434A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoArticleStrip extends StatelessWidget {
  const _PromoArticleStrip({required this.promos, required this.articles});

  final List<PromoBanner> promos;
  final List<ArticleItem> articles;

  @override
  Widget build(BuildContext context) {
    if (promos.isEmpty && articles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 224,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 36),
        children: [
          if (promos.isNotEmpty) _PromoCard(promo: promos.first),
          if (articles.isNotEmpty) ...[
            const SizedBox(width: 0),
            _ArticleCard(article: articles.first),
          ],
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo});

  final PromoBanner promo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 452,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: promo.imageUrl,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const ColoredBox(
              color: Color(0xFF264653),
            ),
          ),
          const ColoredBox(color: Color(0x66001422)),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROMO KHUSUS',
                  style: TextStyle(
                    color: Color(0xFFFFB12D),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  promo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    promo.ctaLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final ArticleItem article;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      padding: const EdgeInsets.fromLTRB(24, 28, 18, 20),
      decoration: const BoxDecoration(
        color: _iconBg,
        borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ARTIKEL',
            style: TextStyle(
              color: _teal,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            article.title,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          const Row(
            children: [
              Text(
                'Baca',
                style: TextStyle(
                  color: _teal,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, color: _teal, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedWorkersSection extends StatelessWidget {
  const _FeaturedWorkersSection({required this.workers});

  final List<FeaturedWorker> workers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          title: 'Tukang Unggulan Terdekat',
          action: 'Lihat Semua',
          onAction: () => context.push('/workers'),
        ),
        const SizedBox(height: 16),
        ...workers.take(4).map(
              (worker) => Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: _WorkerCard(worker: worker),
              ),
            ),
      ],
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.worker});

  final FeaturedWorker worker;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/workers/${worker.id}'),
      child: Container(
        minHeight: 126,
        padding: const EdgeInsets.fromLTRB(28, 22, 22, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDEBFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                _Avatar(url: worker.avatarUrl, size: 66),
                if (worker.isVerified)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF009870),
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 3),
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    worker.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    worker.specialization,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Color(0xFF465158), size: 24),
                      Text(
                        '${worker.distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: Color(0xFF465158),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(width: 28),
                      const Icon(Icons.work_outline,
                          color: Color(0xFF465158), size: 24),
                      Text(
                        '${worker.completedJobs}+ Job',
                        style: const TextStyle(
                          color: Color(0xFF465158),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F0FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFA000), size: 26),
                  Text(
                    worker.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFF3D464D),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: onAction,
          child: Text(
            action,
            style: const TextStyle(
              color: _teal,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url == null || url!.isEmpty
            ? const ColoredBox(
                color: _iconBg,
                child: Icon(Icons.person, color: _teal),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const ColoredBox(
                  color: _iconBg,
                  child: Icon(Icons.person, color: _teal),
                ),
              ),
      ),
    );
  }
}

IconData _categoryIcon(String name) {
  switch (name.toLowerCase()) {
    case 'ac':
      return Icons.ac_unit;
    case 'pipa':
      return Icons.plumbing;
    case 'atap':
      return Icons.roofing;
    case 'listrik':
      return Icons.electrical_services;
    case 'kunci':
      return Icons.vpn_key;
    case 'kayu':
      return Icons.carpenter;
    case 'cat':
      return Icons.format_paint;
    case 'kebun':
      return Icons.local_florist;
    default:
      return Icons.handyman;
  }
}
