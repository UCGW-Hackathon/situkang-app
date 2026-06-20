import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/theme.dart';

class OrderPaymentWebviewPage extends StatefulWidget {
  const OrderPaymentWebviewPage({
    required this.orderId,
    required this.checkoutUrl,
    this.snapToken,
    this.paymentId,
    this.workerName,
    this.serviceName,
    this.total,
    this.paymentMethod,
    super.key,
  });

  final String orderId;
  final String checkoutUrl;
  final String? snapToken;
  final String? paymentId;
  final String? workerName;
  final String? serviceName;
  final int? total;
  final String? paymentMethod;

  @override
  State<OrderPaymentWebviewPage> createState() =>
      _OrderPaymentWebviewPageState();
}

class _OrderPaymentWebviewPageState extends State<OrderPaymentWebviewPage> {
  late final WebViewController _controller;
  var _progress = 0;
  var _isSyncing = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final checkoutUrl = _resolveCheckoutUrl();
    if (checkoutUrl == null) {
      _loadError = 'URL pembayaran Midtrans tidak tersedia.';
      _controller = WebViewController();
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress),
          onNavigationRequest: (request) {
            if (_isPaidCallback(request.url)) {
              _syncAndGoToSuccess();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {
            if (_isPaidCallback(url)) _syncAndGoToSuccess();
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _loadError ??= 'WebView gagal memuat halaman pembayaran.';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(checkoutUrl));
  }

  String? _resolveCheckoutUrl() {
    if (widget.checkoutUrl.isNotEmpty) return widget.checkoutUrl;
    final token = widget.snapToken;
    if (token == null || token.isEmpty) return null;
    return 'https://app.sandbox.midtrans.com/snap/v2/vtweb/$token';
  }

  bool _isPaidCallback(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('/payments/sandbox-callback') &&
        (lowerUrl.contains('status=paid') ||
            lowerUrl.contains('payment_status=paid') ||
            lowerUrl.contains('status=success'));
  }

  Future<void> _syncAndGoToSuccess() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    try {
      final paymentId = widget.paymentId;
      if (paymentId != null && paymentId.isNotEmpty) {
        try {
          await getIt<ApiClient>().post<Map<String, dynamic>>(
            '/payments/sandbox-callback',
            data: {
              'payment_id': paymentId,
              'status': 'success',
            },
          );
        } catch (_) {
          // Ignore callback failure to not block normal flow
        }
      }

      await getIt<ApiClient>().post<Map<String, dynamic>>(
        ApiEndpoints.orderPaymentSync(widget.orderId),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? data['message'] as String? ?? 'Gagal sinkron pembayaran Midtrans'
          : 'Gagal sinkron pembayaran Midtrans';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
      setState(() => _isSyncing = false);
      return;
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal sinkron pembayaran Midtrans'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isSyncing = false);
      return;
    }

    if (!mounted) return;
    context.go(
      '/orders/${widget.orderId}/payment-success',
      extra: {
        'workerName': widget.workerName,
        'serviceName': widget.serviceName,
        'total': widget.total,
        'paymentMethod': widget.paymentMethod ?? 'QRIS',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pembayaran QRIS'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progress / 100),
              )
            : null,
      ),
      body: _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.web_asset_off, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: ElevatedButton.icon(
            onPressed: _isSyncing ? null : _syncAndGoToSuccess,
            icon: _isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: Text(
              _isSyncing ? 'Mengecek Pembayaran...' : 'Saya Sudah Membayar',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00AA13),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: AppTypography.buttonMedium.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
