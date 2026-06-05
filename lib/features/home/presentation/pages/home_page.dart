import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../knowledge/presentation/pages/article_detail_page.dart';
import '../../../orders/presentation/bloc/order_bloc.dart';
import '../../../orders/presentation/pages/order_detail_page.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/article_item.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/featured_worker.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/entities/promo_banner.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/active_order_banner.dart';

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
    _fetchAndUpdateLocation();
  }

  Future<void> _fetchAndUpdateLocation() async {
    try {
      // 1. Check/Request location permissions
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied.');
        return;
      }

      // 2. Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 3. Reverse geocode using Nominatim API (OpenStreetMap)
      final address = await _reverseGeocode(position.latitude, position.longitude);
      if (address.isEmpty) return;

      // 4. Update location to the backend
      final profileRepo = getIt<ProfileRepository>();
      final result = await profileRepo.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );

      // 5. If successful, refresh HomeBloc to update greeting and location on beranda
      result.fold(
        (failure) => debugPrint('Failed to update location on server: ${failure.message}'),
        (_) {
          if (mounted) {
            context.read<HomeBloc>().add(const RefreshHomeData());
          }
        },
      );
    } catch (e) {
      debugPrint('Error fetching/updating location: $e');
    }
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final dio = Dio();
      dio.options.headers['User-Agent'] = 'SitukangApp/1.0';
      final response = await dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lon,
          'zoom': 18,
          'addressdetails': 1,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final displayName = response.data!['display_name'] as String?;
        if (displayName != null) {
          final parts = displayName.split(',');
          if (parts.length > 2) {
            return '${parts[0].trim()}, ${parts[1].trim()}';
          }
          return displayName;
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return '';
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
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: _Header(homeData: homeData),
              ),
            ),
            if (homeData.activeOrder != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ActiveOrderBanner(
                    activeOrder: homeData.activeOrder!,
                    onTap: () {
                      final orderId = homeData.activeOrder!.orderId;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => getIt<OrderBloc>()
                              ..add(FetchOrderDetailRequested(orderId: orderId)),
                            child: OrderDetailPage(orderId: orderId),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                padding: const EdgeInsets.only(top: 24),
                child: _PromoArticleStrip(
                  promos: homeData.promos,
                  articles: homeData.articles,
                ),
              ),
            ),
            if (homeData.featuredWorkers.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                  child: _FeaturedWorkersSection(
                    workers: homeData.featuredWorkers,
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: _Avatar(url: homeData.avatarUrl, size: 48),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selamat datang,',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Halo, ${homeData.fullName}!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Lokasi Saat Ini (Kanan)
        const Icon(
          Icons.location_on,
          color: _teal,
          size: 20,
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Lokasi saat ini',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _teal,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                homeData.currentAddress.isNotEmpty
                    ? homeData.currentAddress
                    : 'Jl. Merdeka No. 12',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF39434A),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF8E8E93), size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Cari tukang atau jenis kerusakan...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _teal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Colors.white,
                  size: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _SectionHeader(
            title: 'Kategori Jasa',
            action: 'Lihat Semua',
            onAction: () => context.push('/workers'),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/workers?category=${category.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9F0FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _getCategoryIcon(category.name),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _getCategoryIcon(String name) {
  IconData iconData;
  switch (name.toLowerCase()) {
    case 'ac':
      iconData = Icons.ac_unit;
      break;
    case 'pipa':
      iconData = Icons.plumbing;
      break;
    case 'atap':
      iconData = Icons.roofing;
      break;
    case 'listrik':
      iconData = Icons.power;
      break;
    case 'kunci':
      iconData = Icons.vpn_key;
      break;
    case 'kayu':
      iconData = Icons.carpenter;
      break;
    case 'cat':
      iconData = Icons.format_paint;
      break;
    case 'kebun':
      iconData = Icons.local_florist;
      break;
    default:
      iconData = Icons.handyman;
  }
  return Icon(iconData, color: const Color(0xFF0D47A1), size: 20);
}

class _PromoArticleStrip extends StatelessWidget {
  const _PromoArticleStrip({required this.promos, required this.articles});

  final List<PromoBanner> promos;
  final List<ArticleItem> articles;

  @override
  Widget build(BuildContext context) {
    if (promos.isEmpty && articles.isEmpty) return const SizedBox.shrink();

    final List<Widget> children = [];

    for (var promo in promos) {
      children.add(_PromoCard(promo: promo));
      children.add(const SizedBox(width: 12));
    }

    for (var article in articles) {
      children.add(_ArticleCard(article: article));
      children.add(const SizedBox(width: 12));
    }

    if (children.isNotEmpty) {
      children.removeLast();
    }

    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: children,
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
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/promo_ac_banner.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: _teal,
                child: const Center(
                  child: Icon(Icons.ac_unit, color: Colors.white, size: 40),
                ),
              );
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xAA000000),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'PROMO KHUSUS',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Diskon 20% Jasa AC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Klaim Sekarang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailPage(articleId: article.id),
          ),
        );
      },
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F0FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ARTIKEL',
              style: TextStyle(
                color: _teal,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text(
                  'Baca',
                  style: TextStyle(
                    color: _teal,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward, color: _teal, size: 12),
              ],
            ),
          ],
        ),
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
            padding: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                _Avatar(url: worker.avatarUrl, size: 54),
                if (worker.isVerified)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF009870),
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    worker.specialization,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: _teal, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${worker.distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: Color(0xFF5D6A74),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.business_center, color: _muted, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${worker.completedJobs} Job',
                        style: const TextStyle(
                          color: Color(0xFF5D6A74),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFA000), size: 14),
                  const SizedBox(width: 2),
                  Text(
                    worker.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFF5D4037),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onAction,
          child: Text(
            action,
            style: const TextStyle(
              color: _teal,
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
