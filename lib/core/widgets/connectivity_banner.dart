import 'dart:async';

import 'package:flutter/material.dart';

import '../network/connectivity_manager.dart';
import '../theme/theme.dart';

/// A banner widget that shows offline/online connectivity status.
///
/// Listens to [ConnectivityManager.statusStream] and displays a banner
/// at the top of the screen when the device is offline. Shows a brief
/// "back online" message when connectivity is restored.
class ConnectivityBanner extends StatefulWidget {
  /// Creates a [ConnectivityBanner].
  const ConnectivityBanner({
    required this.connectivityManager, required this.child, super.key,
  });

  /// The connectivity manager to listen to.
  final ConnectivityManager connectivityManager;

  /// The child widget displayed below the banner.
  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late StreamSubscription<ConnectivityStatus> _subscription;
  ConnectivityStatus _status = ConnectivityStatus.online;
  bool _showRestoredBanner = false;

  @override
  void initState() {
    super.initState();
    _status = widget.connectivityManager.currentStatus;
    _subscription = widget.connectivityManager.statusStream.listen(_onStatusChanged);
  }

  void _onStatusChanged(ConnectivityStatus status) {
    if (!mounted) return;

    final wasOffline = _status == ConnectivityStatus.offline;
    setState(() {
      _status = status;
    });

    if (wasOffline && status == ConnectivityStatus.online) {
      setState(() {
        _showRestoredBanner = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showRestoredBanner = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_status == ConnectivityStatus.offline)
          _OfflineBanner()
        else if (_showRestoredBanner)
          _OnlineBanner(),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.error,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off,
            size: AppSizing.iconSm,
            color: AppColors.onError,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Tidak ada koneksi internet',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onError,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.success,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi,
            size: AppSizing.iconSm,
            color: AppColors.onSuccess,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Kembali online',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSuccess,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
