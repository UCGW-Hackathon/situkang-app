import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/situkang_mapbox_map.dart';
import '../../../orders/domain/repositories/order_repository.dart';

/// Client-side live tracker for monitoring a worker en route to the job site.
class TrackingPage extends StatefulWidget {
  const TrackingPage({
    required this.orderId,
    super.key,
    this.workerName,
    this.workerAvatarUrl,
    this.workerSpecialization,
    this.workerRating,
    this.workerPhone,
    this.userLatitude,
    this.userLongitude,
  });

  final String orderId;
  final String? workerName;
  final String? workerAvatarUrl;
  final String? workerSpecialization;
  final double? workerRating;
  final String? workerPhone;
  final double? userLatitude;
  final double? userLongitude;

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  static const _brandTeal = Color(0xFF00647C);
  static const _gojekGreen = Color(0xFF00AA13);
  static const _demoWorkerOrigin = LatLng(-7.279881, 112.797580);
  static const _demoSpeedKmh = 40.0;

  List<LatLng> _route = const [];
  String? _routeKey;
  bool _isLoadingRoute = false;
  int? _etaMinutes;
  LatLng? _fetchedDestination;
  bool _isFetchingOrderDetail = false;

  LatLng? get _destination {
    if (_fetchedDestination != null) return _fetchedDestination;
    final latitude = widget.userLatitude;
    final longitude = widget.userLongitude;
    if (latitude == null || longitude == null) return null;
    if (latitude == 0 || longitude == 0) return null;
    return LatLng(latitude, longitude);
  }

  @override
  void initState() {
    super.initState();
    if (_destination == null) {
      unawaited(_loadOrderDestination());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _buildTracker(context),
    );
  }

  Widget _buildTracker(BuildContext context) {
    final destination = _destination;
    const workerPoint = _demoWorkerOrigin;
    if (destination != null) {
      unawaited(_loadDirectionsRoute(workerPoint, destination));
    }

    return Stack(
      children: [
        Positioned.fill(
          child: _buildMap(workerPoint: workerPoint, destination: destination),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              children: [
                _CircleMapButton(
                  icon: Icons.arrow_back,
                  onPressed: () => context.pop(),
                ),
                const Spacer(),
                _CircleMapButton(
                  icon: Icons.help_outline,
                  onPressed: _showTrackingInfo,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _TrackerSheet(
            workerName: widget.workerName ?? 'Tukang',
            workerAvatarUrl: widget.workerAvatarUrl,
            workerSpecialization: widget.workerSpecialization ?? 'Spesialis',
            workerRating: widget.workerRating,
            etaMinutes:
                _etaMinutes ?? _estimateEtaMinutes(workerPoint, destination),
            status: OrderStatus.onTheWay,
            isConnecting: false,
            onChat: () => context.push(
              '/chat/${widget.orderId}',
              extra: widget.workerName ?? 'Tukang',
            ),
            onCall: _callWorker,
            onCancel: () => context.pop(),
          ),
        ),
      ],
    );
  }

  Widget _buildMap({LatLng? workerPoint, LatLng? destination}) {
    final resolvedMarkers = [
      if (destination != null)
        SitukangMapboxMarker(point: destination, color: _brandTeal, radius: 9),
      if (workerPoint != null)
        SitukangMapboxMarker(
          point: workerPoint,
          color: _gojekGreen,
          radius: 10,
        ),
    ];
    final fitPoints = [?workerPoint, ?destination];
    final center =
        workerPoint ?? destination ?? const LatLng(-6.200000, 106.816666);

    return SitukangMapboxMap(
      initialCenter: center,
      initialZoom: 13,
      markers: resolvedMarkers,
      route: _route,
      fitPoints: fitPoints.length >= 2 ? fitPoints : const [],
    );
  }

  Future<void> _loadDirectionsRoute(LatLng origin, LatLng target) async {
    final token = AppConstants.mapboxAccessToken.trim();
    if (token.isEmpty) return;

    final routeKey =
        '${origin.latitude.toStringAsFixed(5)},${origin.longitude.toStringAsFixed(5)}'
        '>${target.latitude.toStringAsFixed(5)},${target.longitude.toStringAsFixed(5)}';
    if (_routeKey == routeKey || _isLoadingRoute) return;

    _isLoadingRoute = true;
    try {
      final response = await Dio().get<Map<String, dynamic>>(
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${origin.longitude},${origin.latitude};'
        '${target.longitude},${target.latitude}',
        queryParameters: {
          'alternatives': false,
          'geometries': 'geojson',
          'overview': 'full',
          'steps': false,
          'access_token': token,
        },
      );

      final routes = response.data?['routes'];
      Object? coordinates;
      double? distanceMeters;
      if (routes is List && routes.isNotEmpty) {
        final firstRoute = routes.first;
        if (firstRoute is Map) {
          distanceMeters = _asDouble(firstRoute['distance']);
          final geometry = firstRoute['geometry'];
          if (geometry is Map) coordinates = geometry['coordinates'];
        }
      }
      if (coordinates is! List) {
        if (!mounted) return;
        setState(() {
          _routeKey = routeKey;
          _route = const [];
          _etaMinutes = _estimateEtaMinutes(origin, target);
        });
        return;
      }

      final parsedRoute = coordinates
          .whereType<List<dynamic>>()
          .where((coordinate) => coordinate.length >= 2)
          .map(
            (coordinate) => LatLng(
              (coordinate[1] as num).toDouble(),
              (coordinate[0] as num).toDouble(),
            ),
          )
          .toList(growable: false);
      if (parsedRoute.length < 2) {
        if (!mounted) return;
        setState(() {
          _routeKey = routeKey;
          _route = const [];
          _etaMinutes = _estimateEtaMinutes(origin, target);
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _routeKey = routeKey;
        _route = parsedRoute;
        _etaMinutes = _estimateEtaFromMeters(
          distanceMeters ?? _distanceAlongRouteMeters(parsedRoute),
        );
      });
    } on DioException {
      if (!mounted) return;
      setState(() {
        _routeKey = routeKey;
        _route = const [];
        _etaMinutes = _estimateEtaMinutes(origin, target);
      });
    } finally {
      _isLoadingRoute = false;
    }
  }

  Future<void> _loadOrderDestination() async {
    if (_isFetchingOrderDetail) return;
    _isFetchingOrderDetail = true;
    final result = await getIt<OrderRepository>().getOrderDetail(
      widget.orderId,
    );
    result.fold((_) {}, (order) {
      if (!mounted) return;
      final latitude = order.location.latitude;
      final longitude = order.location.longitude;
      if (latitude == 0 || longitude == 0) return;
      setState(() {
        _fetchedDestination = LatLng(latitude, longitude);
        _etaMinutes = _estimateEtaMinutes(
          _demoWorkerOrigin,
          _fetchedDestination,
        );
      });
    });
    _isFetchingOrderDetail = false;
  }

  int? _estimateEtaMinutes(LatLng origin, LatLng? target) {
    if (target == null) return null;
    final meters = const Distance().as(LengthUnit.Meter, origin, target);
    return _estimateEtaFromMeters(meters);
  }

  int _estimateEtaFromMeters(double meters) {
    final distanceKm = meters / 1000;
    final hours = distanceKm / _demoSpeedKmh;
    return math.max(1, (hours * 60).ceil());
  }

  double _distanceAlongRouteMeters(List<LatLng> route) {
    if (route.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < route.length; i++) {
      total += const Distance().as(LengthUnit.Meter, route[i - 1], route[i]);
    }
    return total;
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _callWorker() async {
    final phone = widget.workerPhone?.trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon tukang belum tersedia.')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri);
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak bisa membuka aplikasi telepon.')),
    );
  }

  void _showTrackingInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tracking Tukang'),
        content: const Text(
          'Mode demo memakai titik awal tukang tetap di -7.279881, 112.797580. Estimasi tiba dihitung dari jarak rute dengan kecepatan konstan 40 km/jam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}

class _CircleMapButton extends StatelessWidget {
  const _CircleMapButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF102033)),
      ),
    );
  }
}

class _TrackerSheet extends StatelessWidget {
  const _TrackerSheet({
    required this.workerName,
    required this.workerSpecialization,
    required this.status,
    required this.isConnecting,
    required this.onChat,
    required this.onCall,
    required this.onCancel,
    this.workerAvatarUrl,
    this.workerRating,
    this.etaMinutes,
  });

  final String workerName;
  final String workerSpecialization;
  final String? workerAvatarUrl;
  final double? workerRating;
  final int? etaMinutes;
  final OrderStatus status;
  final bool isConnecting;
  final VoidCallback onChat;
  final VoidCallback onCall;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(21, 10, 21, bottomPadding + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD0D8DF),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 19),
          Text(
            _statusTitle,
            style: AppTypography.h4.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 9,
                backgroundColor: _TrackingPageState._brandTeal,
                child: Icon(Icons.schedule, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Text(
                _etaText,
                style: AppTypography.bodyMedium.copyWith(
                  color: _TrackingPageState._brandTeal,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _WorkerTrackerCard(
            name: workerName,
            avatarUrl: workerAvatarUrl,
            specialization: workerSpecialization,
            rating: workerRating,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _TrackingPageState._brandTeal,
                    side: const BorderSide(
                      color: Color(0xFF7DCBFF),
                      width: 1.5,
                    ),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: AppTypography.buttonMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text('Telepon'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _TrackingPageState._brandTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: AppTypography.buttonMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Batalkan Pesanan',
              style: AppTypography.label.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _etaText {
    if (isConnecting) return 'Menghubungkan tracking...';
    if (etaMinutes != null) return 'Estimasi tiba: $etaMinutes Menit';
    return 'Menghitung estimasi tiba...';
  }

  String get _statusTitle {
    switch (status) {
      case OrderStatus.onTheWay:
        return 'Tukang menuju lokasi Anda';
      case OrderStatus.arrived:
        return 'Tukang sudah tiba';
      case OrderStatus.inProgress:
      case OrderStatus.workPaused:
        return 'Pekerjaan sedang berlangsung';
      case OrderStatus.accepted:
        return 'Tukang bersiap menuju lokasi';
      case OrderStatus.completed:
        return 'Pekerjaan selesai';
      case OrderStatus.waitingPayment:
        return 'Menunggu pembayaran';
      case OrderStatus.paid:
        return 'Sudah dibayar';
      case OrderStatus.pending:
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return 'Tracking pesanan';
    }
  }
}

class _WorkerTrackerCard extends StatelessWidget {
  const _WorkerTrackerCard({
    required this.name,
    required this.specialization,
    this.avatarUrl,
    this.rating,
  });

  final String name;
  final String specialization;
  final String? avatarUrl;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    final avatar = avatarUrl?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCAE3FF)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE5EDF3),
                backgroundImage: avatar == null || avatar.isEmpty
                    ? null
                    : NetworkImage(avatar),
                child: avatar == null || avatar.isEmpty
                    ? const Icon(Icons.person, color: Color(0xFF52606D))
                    : null,
              ),
              const Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 7,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: _TrackingPageState._gojekGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.label.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  specialization,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF52606D),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFFFA000)),
                    const SizedBox(width: 4),
                    Text(
                      rating == null
                          ? 'Belum ada review'
                          : '${rating!.toStringAsFixed(1)} Review',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
