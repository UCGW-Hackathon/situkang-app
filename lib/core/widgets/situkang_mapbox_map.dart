import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../constants/app_constants.dart';
import '../theme/theme.dart';

class SitukangMapboxMarker {
  const SitukangMapboxMarker({
    required this.point,
    required this.color,
    this.radius = 8,
  });

  final latlng.LatLng point;
  final Color color;
  final double radius;
}

class SitukangMapboxMap extends StatefulWidget {
  const SitukangMapboxMap({
    required this.initialCenter,
    this.initialZoom = 14,
    this.pitch = 0,
    this.markers = const [],
    this.route = const [],
    this.fitPoints = const [],
    this.onMapCreated,
    this.onCameraIdle,
    super.key,
  });

  final latlng.LatLng initialCenter;
  final double initialZoom;
  final double pitch;
  final List<SitukangMapboxMarker> markers;
  final List<latlng.LatLng> route;
  final List<latlng.LatLng> fitPoints;
  final ValueChanged<MapboxMap>? onMapCreated;
  final ValueChanged<latlng.LatLng>? onCameraIdle;

  @override
  State<SitukangMapboxMap> createState() => _SitukangMapboxMapState();
}

class _SitukangMapboxMapState extends State<SitukangMapboxMap> {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleManager;
  PolylineAnnotationManager? _polylineManager;

  bool get _hasToken => AppConstants.mapboxAccessToken.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasToken) {
      MapboxOptions.setAccessToken(AppConstants.mapboxAccessToken);
    }
  }

  @override
  void didUpdateWidget(covariant SitukangMapboxMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers ||
        oldWidget.route != widget.route) {
      _syncAnnotations();
    }
    if (oldWidget.fitPoints != widget.fitPoints ||
        oldWidget.initialCenter != widget.initialCenter) {
      _fitCameraToPoints();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasToken) {
      return _MissingTokenPlaceholder(onRetry: () => setState(() {}));
    }

    return MapWidget(
      key: ValueKey(
        '${widget.initialCenter.latitude},${widget.initialCenter.longitude}',
      ),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      viewport: CameraViewportState(
        center: _toPoint(widget.initialCenter),
        zoom: widget.initialZoom,
        pitch: widget.pitch,
        bearing: 0,
      ),
      gestureRecognizers: const {
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      },
      onMapCreated: (mapboxMap) async {
        _mapboxMap = mapboxMap;
        await _configureMap(mapboxMap);
        widget.onMapCreated?.call(mapboxMap);
      },
      onStyleLoadedListener: (_) async {
        await _createManagers();
        await _syncAnnotations();
        await _fitCameraToPoints();
      },
      onMapIdleListener: (_) async {
        final map = _mapboxMap;
        if (map == null || widget.onCameraIdle == null) return;
        final camera = await map.getCameraState();
        widget.onCameraIdle?.call(_fromPoint(camera.center));
      },
    );
  }

  Future<void> _createManagers() async {
    final map = _mapboxMap;
    if (map == null) return;
    _circleManager ??= await map.annotations.createCircleAnnotationManager();
    _polylineManager ??= await map.annotations
        .createPolylineAnnotationManager();
  }

  Future<void> _configureMap(MapboxMap mapboxMap) async {
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.gestures.updateSettings(
      GesturesSettings(
        scrollEnabled: true,
        pinchToZoomEnabled: true,
        pinchPanEnabled: true,
        rotateEnabled: true,
        pitchEnabled: false,
      ),
    );
  }

  Future<void> _fitCameraToPoints() async {
    final map = _mapboxMap;
    final points = widget.fitPoints;
    if (map == null || points.length < 2) return;

    final bounds = _boundsFor(points);
    final camera = await map.cameraForCoordinateBounds(
      bounds,
      MbxEdgeInsets(top: 44, left: 42, bottom: 72, right: 42),
      0,
      0,
      15,
      null,
    );

    await map.easeTo(
      CameraOptions(
        center: camera.center,
        padding: camera.padding,
        zoom: camera.zoom,
        bearing: 0,
        pitch: 0,
      ),
      MapAnimationOptions(duration: 450),
    );
  }

  Future<void> _syncAnnotations() async {
    final circles = _circleManager;
    final polylines = _polylineManager;
    if (circles == null || polylines == null) return;

    await circles.deleteAll();
    await polylines.deleteAll();

    if (widget.route.length >= 2) {
      await polylines.create(
        PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: widget.route.map(_toPosition).toList(),
          ),
          lineColor: AppColors.primary.toARGB32(),
          lineWidth: 5,
          lineBorderColor: Colors.white.toARGB32(),
          lineBorderWidth: 2,
          lineJoin: LineJoin.ROUND,
        ),
      );
    }

    for (final marker in widget.markers) {
      await circles.create(
        CircleAnnotationOptions(
          geometry: _toPoint(marker.point),
          circleColor: marker.color.toARGB32(),
          circleRadius: marker.radius,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 3,
          circleOpacity: 1,
        ),
      );
    }
  }

  Point _toPoint(latlng.LatLng point) {
    return Point(coordinates: _toPosition(point));
  }

  Position _toPosition(latlng.LatLng point) {
    return Position(point.longitude, point.latitude);
  }

  CoordinateBounds _boundsFor(List<latlng.LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = mathMin(minLat, point.latitude);
      maxLat = mathMax(maxLat, point.latitude);
      minLng = mathMin(minLng, point.longitude);
      maxLng = mathMax(maxLng, point.longitude);
    }

    return CoordinateBounds(
      southwest: Point(coordinates: Position(minLng, minLat)),
      northeast: Point(coordinates: Position(maxLng, maxLat)),
      infiniteBounds: false,
    );
  }

  latlng.LatLng _fromPoint(Point point) {
    return latlng.LatLng(
      point.coordinates.lat.toDouble(),
      point.coordinates.lng.toDouble(),
    );
  }
}

double mathMin(double a, double b) => a < b ? a : b;

double mathMax(double a, double b) => a > b ? a : b;

class _MissingTokenPlaceholder extends StatelessWidget {
  const _MissingTokenPlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surfaceVariant),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Mapbox token belum diset.\nJalankan dengan --dart-define=MAPBOX_ACCESS_TOKEN=...',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
