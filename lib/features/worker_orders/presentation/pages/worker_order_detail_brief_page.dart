import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/situkang_mapbox_map.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/worker_order_detail.dart';
import '../bloc/worker_order_bloc.dart';

class WorkerOrderDetailBriefPage extends StatefulWidget {
  const WorkerOrderDetailBriefPage({required this.orderId, super.key});

  final String orderId;

  @override
  State<WorkerOrderDetailBriefPage> createState() =>
      _WorkerOrderDetailBriefPageState();
}

class _WorkerOrderDetailBriefPageState
    extends State<WorkerOrderDetailBriefPage> {
  static const _brandTeal = Color(0xFF00647C);
  static const _screenBackground = Color(0xFFF8F9FF);
  static const _complaintBackground = Color(0xFFE6EEFF);
  static const _complaintBorder = Color(0xFFD5E3FC);

  mb.MapboxMap? _mapboxMap;
  LatLng? _currentLocation;
  List<LatLng> _directionsRoute = const [];
  String? _directionsRouteKey;
  bool _isLoadingDirections = false;
  String? _mapboxPlaceName;
  String? _mapboxPlaceKey;
  bool _isLoadingPlaceName = false;

  @override
  void initState() {
    super.initState();
    context.read<WorkerOrderBloc>().add(
      FetchWorkerOrderDetail(orderId: widget.orderId),
    );
    unawaited(_loadCurrentLocation());
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } on Exception {
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkerOrderBloc, WorkerOrderState>(
      listener: (context, state) {
        if (state is WorkerOrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        }

        if (state is WorkerOrderStatusUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_statusUpdatedMessage(state.newStatus)),
              backgroundColor: AppColors.success,
            ),
          );
          if (state.newStatus == 'completed') {
            context.go('/worker');
          } else {
            context.read<WorkerOrderBloc>().add(
              FetchWorkerOrderDetail(orderId: widget.orderId),
            );
          }
        }

        if (state is WorkerOrderCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pekerjaan selesai. Tagihan berhasil dibuat.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/worker');
        }
      },
      builder: (context, state) {
        if (state is WorkerOrderInitial ||
            state is WorkerOrderDetailLoading ||
            state is WorkerOrderLoading ||
            state is WorkerOrderStatusUpdated ||
            state is WorkerOrderCompleted) {
          return const Scaffold(
            backgroundColor: _screenBackground,
            body: Center(child: LoadingIndicator()),
          );
        }

        if (state is WorkerOrderError) {
          return Scaffold(
            backgroundColor: _screenBackground,
            appBar: _buildAppBar(context),
            body: AppErrorWidget(
              message: state.failure.message,
              onRetry: () => context.read<WorkerOrderBloc>().add(
                FetchWorkerOrderDetail(orderId: widget.orderId),
              ),
            ),
          );
        }

        if (state is WorkerOrderDetailLoaded) {
          return _buildDetailScaffold(context, state.detail);
        }

        return const Scaffold(
          backgroundColor: _screenBackground,
          body: SizedBox.shrink(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 1,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: AppColors.textPrimary,
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/worker');
          }
        },
      ),
      title: Text(
        'Detail Order',
        style: AppTypography.h5.copyWith(
          color: _brandTeal,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDetailScaffold(BuildContext context, WorkerOrderDetail detail) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _screenBackground,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<WorkerOrderBloc>().add(
            FetchWorkerOrderDetail(orderId: widget.orderId),
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomInset + 164),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  _buildMap(detail),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 250, 16, 0),
                    child: _buildCustomerCard(detail),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildWorkSnapshot(detail),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: _buildComplaintSection(detail),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionArea(context, detail),
    );
  }

  Widget _buildMap(WorkerOrderDetail detail) {
    final target = LatLng(detail.location.latitude, detail.location.longitude);
    final center = detail.hasUsableLocation
        ? target
        : const LatLng(-6.2, 106.8);
    final markers = [
      if (_currentLocation != null)
        SitukangMapboxMarker(
          point: _currentLocation!,
          color: AppColors.success,
        ),
      if (detail.hasUsableLocation)
        SitukangMapboxMarker(point: target, color: _brandTeal, radius: 9),
    ];
    final fitPoints =
        detail.hasUsableLocation &&
            _currentLocation != null &&
            _currentLocation != target
        ? [_currentLocation!, target]
        : const <LatLng>[];
    unawaited(_loadDirectionsRoute(target, fitPoints));
    if (detail.hasUsableLocation) {
      unawaited(_loadMapboxPlaceName(target));
    }

    return SizedBox(
      height: 309,
      child: Stack(
        children: [
          SitukangMapboxMap(
            initialCenter: center,
            markers: markers,
            route: _directionsRoute,
            fitPoints: fitPoints,
            onMapCreated: (mapboxMap) {
              _mapboxMap = mapboxMap;
            },
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x00F8F9FF),
                      Color(0xCCF8F9FF),
                    ],
                    stops: [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 40,
            child: Material(
              color: AppColors.surface,
              shape: const CircleBorder(),
              elevation: 4,
              child: IconButton(
                tooltip: 'Pusatkan peta',
                onPressed: detail.hasUsableLocation
                    ? () => _mapboxMap?.flyTo(
                        mb.CameraOptions(
                          center: _toPoint(target),
                          zoom: 14.5,
                          bearing: 0,
                          pitch: 0,
                        ),
                        mb.MapAnimationOptions(duration: 700),
                      )
                    : null,
                icon: const Icon(Icons.my_location),
                color: _brandTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDirectionsRoute(
    LatLng target,
    List<LatLng> fitPoints,
  ) async {
    final origin = _currentLocation;
    final token = AppConstants.mapboxAccessToken.trim();
    if (origin == null || fitPoints.length < 2 || token.isEmpty) {
      if (_directionsRoute.isNotEmpty) {
        setState(() {
          _directionsRoute = const [];
          _directionsRouteKey = null;
        });
      }
      return;
    }

    final routeKey =
        '${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}'
        '>${target.latitude.toStringAsFixed(6)},${target.longitude.toStringAsFixed(6)}';
    if (_directionsRouteKey == routeKey || _isLoadingDirections) return;

    _isLoadingDirections = true;
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
      if (routes is List && routes.isNotEmpty) {
        final firstRoute = routes.first;
        if (firstRoute is Map) {
          final geometry = firstRoute['geometry'];
          if (geometry is Map) {
            coordinates = geometry['coordinates'];
          }
        }
      }
      if (coordinates is! List) return;

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

      if (!mounted) return;
      setState(() {
        _directionsRouteKey = routeKey;
        _directionsRoute = parsedRoute;
      });
    } on DioException {
      if (!mounted) return;
      setState(() {
        _directionsRouteKey = routeKey;
        _directionsRoute = const [];
      });
    } finally {
      _isLoadingDirections = false;
    }
  }

  Future<void> _loadMapboxPlaceName(LatLng target) async {
    final token = AppConstants.mapboxAccessToken.trim();
    if (token.isEmpty) return;

    final placeKey =
        '${target.latitude.toStringAsFixed(6)},${target.longitude.toStringAsFixed(6)}';
    if (_mapboxPlaceKey == placeKey || _isLoadingPlaceName) return;

    _isLoadingPlaceName = true;
    try {
      final response = await Dio().get<Map<String, dynamic>>(
        'https://api.mapbox.com/search/geocode/v6/reverse',
        queryParameters: {
          'longitude': target.longitude,
          'latitude': target.latitude,
          'language': 'id',
          'country': 'ID',
          'access_token': token,
        },
      );

      final features = response.data?['features'];
      Object? properties;
      if (features is List && features.isNotEmpty) {
        final firstFeature = features.first;
        if (firstFeature is Map) {
          properties = firstFeature['properties'];
        }
      }
      if (properties is! Map) return;

      final placeName =
          properties['full_address'] ??
          properties['place_formatted'] ??
          properties['name'];
      if (placeName is! String || placeName.trim().isEmpty) return;

      if (!mounted) return;
      setState(() {
        _mapboxPlaceKey = placeKey;
        _mapboxPlaceName = placeName.trim();
      });
    } on DioException {
      if (!mounted) return;
      setState(() {
        _mapboxPlaceKey = placeKey;
      });
    } finally {
      _isLoadingPlaceName = false;
    }
  }

  Widget _buildCustomerCard(WorkerOrderDetail detail) {
    final customer = detail.customer;
    final customerName = _displayCustomerName(detail);
    final distanceText = _distanceText(detail);
    final address = _displayAddress(detail);
    final addressDetail = detail.location.addressDetail?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x4DBDC8CE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CustomerAvatar(avatarUrl: customer?.avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: AppTypography.h4.copyWith(
                          fontSize: 20,
                          color: const Color(0xFF0D1C2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (distanceText != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.pin_drop_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                distanceText,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3E484D),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: detail.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0x4DBDC8CE)),
            const SizedBox(height: 16),
            _LocationSummary(
              address: address,
              addressDetail: addressDetail,
              coordinateText: detail.hasUsableLocation
                  ? '${detail.location.latitude.toStringAsFixed(5)}, '
                        '${detail.location.longitude.toStringAsFixed(5)}'
                  : null,
              routeText: _routeText(detail),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkSnapshot(WorkerOrderDetail detail) {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: Icons.build_circle_outlined,
            label: 'Layanan',
            value: _serviceLabel(detail),
            color: _brandTeal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            icon: Icons.bolt_outlined,
            label: 'Prioritas',
            value: _urgencyLabel(detail.urgency),
            color: _urgencyColor(detail.urgency),
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintSection(WorkerOrderDetail detail) {
    final description = detail.description.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.assignment_outlined,
          title: 'Brief Pekerjaan',
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE1E8EF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: _complaintBackground,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.plumbing, color: _brandTeal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.title,
                            style: AppTypography.h4.copyWith(
                              color: const Color(0xFF0D1C2E),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoPill(
                                icon: Icons.confirmation_number_outlined,
                                label: '#${detail.orderNumber}',
                              ),
                              _InfoPill(
                                icon: Icons.schedule_outlined,
                                label: _formatDateTime(detail.createdAt),
                              ),
                              if (detail.acceptedAt != null)
                                _InfoPill(
                                  icon: Icons.check_circle_outline,
                                  label:
                                      'Diterima ${_formatClock(detail.acceptedAt!)}',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _complaintBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _complaintBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Pelanggan',
                          style: AppTypography.label.copyWith(
                            color: _brandTeal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description.isNotEmpty
                              ? description
                              : 'Pelanggan belum menambahkan catatan khusus.',
                          style: AppTypography.bodyLarge.copyWith(
                            color: const Color(0xFF3E484D),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Titik pekerjaan',
                  value: _displayAddress(detail),
                  subValue:
                      detail.location.addressDetail?.trim().isNotEmpty == true
                      ? detail.location.addressDetail!.trim()
                      : _routeText(detail),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.route_outlined,
                  label: 'Navigasi',
                  value: _routeText(detail),
                  subValue: detail.hasUsableLocation
                      ? 'Koordinat ${detail.location.latitude.toStringAsFixed(5)}, ${detail.location.longitude.toStringAsFixed(5)}'
                      : null,
                ),
                if (detail.photos.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Foto Kerusakan',
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D1C2E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F3F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${detail.photos.length}',
                          style: AppTypography.caption.copyWith(
                            color: _brandTeal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.photos.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return _DamagePhoto(url: detail.photos[index]);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionArea(
    BuildContext context,
    WorkerOrderDetail detail,
  ) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final nextStatus = _nextStatus(detail.status);
    final canStartWork = _canStartWork(detail);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: Color(0x33BDC8CE))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 17, 16, math.max(16, bottomPadding)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      '/worker/chat/${detail.id}',
                      extra: _displayCustomerName(detail),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _brandTeal,
                    side: const BorderSide(color: _brandTeal, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: AppTypography.buttonMedium.copyWith(
                      color: _brandTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: Text(_contactLabel(detail)),
                ),
              ),
              const SizedBox(height: 16),
              if (detail.status == OrderStatus.pending)
                _PendingOrderDecisionButtons(
                  onReject: () {
                    context.read<WorkerOrderBloc>().add(
                      RejectWorkerOrder(orderId: detail.id),
                    );
                  },
                  onAccept: () {
                    context.read<WorkerOrderBloc>().add(
                      AcceptWorkerOrder(orderId: detail.id),
                    );
                  },
                )
              else if (detail.status == OrderStatus.accepted)
                _SlideToStartButton(
                  text: 'Geser untuk Menuju Lokasi',
                  onCompleted: () {
                    context.read<WorkerOrderBloc>().add(
                      UpdateOrderStatus(
                        orderId: detail.id,
                        status: 'on_the_way',
                        currentStatus: detail.status.value,
                      ),
                    );
                  },
                )
              else if (detail.status == OrderStatus.onTheWay)
                canStartWork
                    ? _SlideToStartButton(
                        text: 'Geser Saat Tiba Lokasi',
                        onCompleted: () {
                          context.read<WorkerOrderBloc>().add(
                            UpdateOrderStatus(
                              orderId: detail.id,
                              status: 'arrived',
                              currentStatus: detail.status.value,
                            ),
                          );
                        },
                      )
                    : _DistanceLockedAction(text: _arriveLockedText(detail))
              else if (detail.status == OrderStatus.arrived)
                canStartWork
                    ? _SlideToStartButton(
                        text: 'Geser untuk Kerjakan',
                        onCompleted: () {
                          context.read<WorkerOrderBloc>().add(
                            UpdateOrderStatus(
                              orderId: detail.id,
                              status: 'in_progress',
                              currentStatus: detail.status.value,
                            ),
                          );
                        },
                      )
                    : _DistanceLockedAction(text: _startWorkLockedText(detail))
              else if (detail.status == OrderStatus.inProgress)
                _SlideToStartButton(
                  text: 'Geser untuk Selesaikan Pekerjaan',
                  onCompleted: () {
                    context.push(
                      '/worker/orders/${detail.id}/items',
                      extra: detail,
                    );
                  },
                )
              else if (detail.status == OrderStatus.paid || detail.status == OrderStatus.waitingPayment)
                _SlideToStartButton(
                  text: 'Geser untuk Selesaikan Pekerjaan',
                  onCompleted: () {
                    context.read<WorkerOrderBloc>().add(
                      UpdateOrderStatus(
                        orderId: detail.id,
                        status: 'completed',
                        currentStatus: detail.status.value,
                      ),
                    );
                  },
                )
              else if (nextStatus != null)
                _SlideToStartButton(
                  text: _slideText(detail.status),
                  onCompleted: () {
                    context.read<WorkerOrderBloc>().add(
                      UpdateOrderStatus(
                        orderId: detail.id,
                        status: nextStatus,
                        currentStatus: detail.status.value,
                      ),
                    );
                  },
                )
              else
                Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                  ),
                  child: Text(
                    _terminalActionLabel(detail.status),
                    style: AppTypography.buttonMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (detail.status == OrderStatus.waitingPayment || detail.status == OrderStatus.paid) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/worker/orders/${detail.id}/invoice');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long, size: 20),
                    label: const Text('Lihat Detail Invoice / Pembayaran'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _displayCustomerName(WorkerOrderDetail detail) {
    final name = detail.customer?.fullName.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Pelanggan';
  }

  String _contactLabel(WorkerOrderDetail detail) {
    final name = detail.customer?.fullName.trim();
    if (name == null || name.isEmpty) return 'Hubungi Pelanggan (Chat)';
    return 'Hubungi ${name.split(RegExp(r'\s+')).first} (Chat)';
  }

  String _displayAddress(WorkerOrderDetail detail) {
    final mapboxAddress = _mapboxPlaceName?.trim();
    if (mapboxAddress != null && mapboxAddress.isNotEmpty) {
      return mapboxAddress;
    }

    final apiAddress = detail.location.address.trim();
    if (apiAddress.isNotEmpty) return apiAddress;

    return detail.hasUsableLocation
        ? 'Lokasi sesuai titik peta'
        : 'Lokasi belum tersedia';
  }

  String _serviceLabel(WorkerOrderDetail detail) {
    final serviceName = detail.serviceName?.trim();
    if (serviceName != null && serviceName.isNotEmpty) return serviceName;
    return 'Jasa Tukang';
  }

  String _urgencyLabel(OrderUrgency urgency) {
    switch (urgency) {
      case OrderUrgency.urgent:
        return 'Mendesak';
      case OrderUrgency.normal:
        return 'Normal';
    }
  }

  Color _urgencyColor(OrderUrgency urgency) {
    switch (urgency) {
      case OrderUrgency.urgent:
        return AppColors.error;
      case OrderUrgency.normal:
        return _brandTeal;
    }
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('dd MMM yyyy, HH:mm').format(value.toLocal());
  }

  String _formatClock(DateTime value) {
    return DateFormat('HH:mm').format(value.toLocal());
  }

  String _routeText(WorkerOrderDetail detail) {
    if (!detail.hasUsableLocation) return 'Titik peta belum tersedia';
    final distanceText = _distanceText(detail);
    if (distanceText != null) return distanceText;
    return 'Rute siap setelah lokasi Anda aktif';
  }

  String? _distanceText(WorkerOrderDetail detail) {
    final meters = _distanceMeters(detail);
    if (meters == null) return null;

    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km dari lokasi Anda';
    }
    return '${meters.round()} m dari lokasi Anda';
  }

  double? _distanceMeters(WorkerOrderDetail detail) {
    if (_currentLocation == null || !detail.hasUsableLocation) return null;

    final target = LatLng(detail.location.latitude, detail.location.longitude);
    return const Distance().as(LengthUnit.Meter, _currentLocation!, target);
  }

  mb.Point _toPoint(LatLng point) {
    return mb.Point(coordinates: mb.Position(point.longitude, point.latitude));
  }

  bool _canStartWork(WorkerOrderDetail detail) {
    final meters = _distanceMeters(detail);
    return meters != null && meters < 100;
  }

  String _startWorkLockedText(WorkerOrderDetail detail) {
    final meters = _distanceMeters(detail);
    if (meters == null) {
      return 'Aktifkan lokasi untuk mulai pekerjaan';
    }
    return 'Dekati lokasi pelanggan (<100 m). Saat ini ${_distanceText(detail)}';
  }

  String _arriveLockedText(WorkerOrderDetail detail) {
    final meters = _distanceMeters(detail);
    if (meters == null) {
      return 'Aktifkan lokasi untuk konfirmasi tiba';
    }
    return 'Konfirmasi tiba saat sudah <100 m. Saat ini ${_distanceText(detail)}';
  }

  String? _nextStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
      case OrderStatus.onTheWay:
      case OrderStatus.arrived:
        return null;
      case OrderStatus.workPaused:
        return 'in_progress';
      case OrderStatus.pending:
      case OrderStatus.inProgress:
      case OrderStatus.waitingPayment:
      case OrderStatus.paid:
      case OrderStatus.completed:
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return null;
    }
  }

  String _slideText(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return 'Geser untuk Menuju Lokasi';
      case OrderStatus.onTheWay:
        return 'Geser Saat Tiba Lokasi';
      case OrderStatus.arrived:
        return 'Geser untuk Mulai Pengerjaan';
      case OrderStatus.workPaused:
        return 'Geser untuk Lanjut Kerja';
      case OrderStatus.pending:
      case OrderStatus.inProgress:
      case OrderStatus.waitingPayment:
      case OrderStatus.paid:
      case OrderStatus.completed:
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return 'Tidak Ada Aksi';
    }
  }

  String _terminalActionLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.inProgress:
        return 'Pekerjaan sedang berlangsung';
      case OrderStatus.waitingPayment:
        return 'Menunggu pembayaran pelanggan';
      case OrderStatus.paid:
        return 'Pelanggan sudah membayar';
      case OrderStatus.completed:
        return 'Pekerjaan selesai';
      case OrderStatus.cancelled:
        return 'Pesanan dibatalkan';
      case OrderStatus.rejected:
        return 'Pesanan ditolak';
      case OrderStatus.pending:
      case OrderStatus.accepted:
      case OrderStatus.onTheWay:
      case OrderStatus.arrived:
      case OrderStatus.workPaused:
        return 'Tidak ada aksi lanjutan';
    }
  }

  String _statusUpdatedMessage(String status) {
    switch (status) {
      case 'in_progress':
        return 'Pekerjaan dimulai.';
      case 'on_the_way':
        return 'Status diperbarui: menuju lokasi.';
      case 'arrived':
        return 'Status diperbarui: tiba di lokasi.';
      case 'accepted':
        return 'Pekerjaan berhasil diterima.';
      case 'completed':
        return 'Pekerjaan berhasil diselesaikan.';
      default:
        return 'Status pekerjaan diperbarui.';
    }
  }
}

class _LocationSummary extends StatelessWidget {
  const _LocationSummary({
    required this.address,
    required this.routeText,
    this.addressDetail,
    this.coordinateText,
  });

  final String address;
  final String routeText;
  final String? addressDetail;
  final String? coordinateText;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E8EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 22,
                  color: _WorkerOrderDetailBriefPageState._brandTeal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0D1C2E),
                        ),
                      ),
                      if (addressDetail != null &&
                          addressDetail!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          addressDetail!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: const Color(0xFF52606D),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(icon: Icons.route_outlined, label: routeText),
                if (coordinateText != null)
                  _InfoPill(
                    icon: Icons.my_location_outlined,
                    label: coordinateText!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E8EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFF0D1C2E),
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: _WorkerOrderDetailBriefPageState._brandTeal,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.h4.copyWith(
            color: const Color(0xFF0D1C2E),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7FA),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        border: Border.all(color: const Color(0xFFDDE8EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: _WorkerOrderDetailBriefPageState._brandTeal,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: const Color(0xFF3E484D),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F7FA),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: _WorkerOrderDetailBriefPageState._brandTeal,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: const Color(0xFF0D1C2E),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              if (subValue != null && subValue!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subValue!,
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF52606D),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD5E3FC), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? const ColoredBox(
              color: Color(0xFFE6EEFF),
              child: Icon(Icons.person, color: Color(0xFF00647C)),
            )
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const ColoredBox(
                color: Color(0xFFE6EEFF),
                child: Icon(Icons.person, color: Color(0xFF00647C)),
              ),
            ),
    );
  }
}

class _DamagePhoto extends StatelessWidget {
  const _DamagePhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x80BDC8CE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => const ColoredBox(
          color: AppColors.surfaceVariant,
          child: Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: colors.$1),
          const SizedBox(width: 4),
          Text(
            _label(status),
            style: AppTypography.caption.copyWith(
              color: colors.$1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _colors(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
      case OrderStatus.onTheWay:
      case OrderStatus.arrived:
      case OrderStatus.inProgress:
      case OrderStatus.workPaused:
      case OrderStatus.waitingPayment:
      case OrderStatus.paid:
      case OrderStatus.completed:
        return (const Color(0xFF00647C), const Color(0x1A00647C));
      case OrderStatus.pending:
        return (AppColors.warning, AppColors.warningLight);
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return (AppColors.error, AppColors.errorLight);
    }
  }

  String _label(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu';
      case OrderStatus.accepted:
        return 'Diterima';
      case OrderStatus.onTheWay:
        return 'Menuju';
      case OrderStatus.arrived:
        return 'Tiba';
      case OrderStatus.inProgress:
        return 'Dikerjakan';
      case OrderStatus.workPaused:
        return 'Jeda';
      case OrderStatus.waitingPayment:
        return 'Menunggu Bayar';
      case OrderStatus.paid:
        return 'Sudah Bayar';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Batal';
      case OrderStatus.rejected:
        return 'Ditolak';
    }
  }
}

class _PendingOrderDecisionButtons extends StatelessWidget {
  const _PendingOrderDecisionButtons({
    required this.onReject,
    required this.onAccept,
  });

  static const _gojekGreen = Color(0xFF00AA13);
  static const _rejectRed = Color(0xFFE53935);

  final VoidCallback onReject;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onReject();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _rejectRed,
                side: const BorderSide(color: _rejectRed, width: 1.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(Icons.close, size: 28),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 7,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                onAccept();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _gojekGreen,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: _gojekGreen.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: AppTypography.buttonLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              child: const Text('TERIMA'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideToStartButton extends StatefulWidget {
  const _SlideToStartButton({required this.text, required this.onCompleted});

  final String text;
  final VoidCallback onCompleted;

  @override
  State<_SlideToStartButton> createState() => _SlideToStartButtonState();
}

class _SlideToStartButtonState extends State<_SlideToStartButton> {
  static const _thumbSize = 48.0;
  static const _gojekGreen = Color(0xFF00AA13);
  static const _trackColor = Color(0xFF00647C);
  double _dragValue = 0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = math.max(0.0, constraints.maxWidth - _thumbSize - 8);
        final progressWidth = math.min(
          constraints.maxWidth,
          _dragValue + _thumbSize + 4,
        );

        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: _trackColor,
            borderRadius: BorderRadius.circular(AppSizing.radiusFull),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOut,
                    width: progressWidth,
                    decoration: const BoxDecoration(
                      color: _gojekGreen,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(AppSizing.radiusFull),
                        right: Radius.circular(AppSizing.radiusFull),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: _completed ? 0.82 : 1,
                  child: Text(
                    widget.text,
                    style: AppTypography.buttonLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned(
                left: 4 + _dragValue,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_completed) return;
                    setState(() {
                      final nextValue = _dragValue + details.delta.dx;
                      _dragValue = math.min(maxDrag, math.max(0, nextValue));
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (_completed) return;
                    if (_dragValue >= maxDrag * 0.78) {
                      setState(() {
                        _dragValue = maxDrag;
                        _completed = true;
                      });
                      HapticFeedback.heavyImpact();
                      unawaited(SystemSound.play(SystemSoundType.alert));
                      widget.onCompleted();
                    } else {
                      setState(() {
                        _dragValue = 0;
                      });
                    }
                  },
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _completed
                          ? Icons.check_rounded
                          : Icons.keyboard_double_arrow_right,
                      color: _completed ? _gojekGreen : _trackColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DistanceLockedAction extends StatelessWidget {
  const _DistanceLockedAction({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        border: Border.all(color: const Color(0xFFD7DEE5)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.buttonSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
