import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/order_detail.dart';
import '../../domain/repositories/order_repository.dart';
import '../helpers/rag_parser.dart';

class OrderPaymentReviewPage extends StatefulWidget {
  const OrderPaymentReviewPage({
    required this.orderId,
    this.initialOrder,
    super.key,
  });

  final String orderId;
  final OrderDetail? initialOrder;

  @override
  State<OrderPaymentReviewPage> createState() => _OrderPaymentReviewPageState();
}

class _OrderPaymentReviewPageState extends State<OrderPaymentReviewPage> {
  static const _brandTeal = Color(0xFF007C92);
  static const _gojekGreen = Color(0xFF00AA13);
  static const _softBlue = Color(0xFFE6F7FF);
  static const _dangerRed = Color(0xFFE53935);
  static const _appTransactionFee = 2000;

  late Future<_ReviewPaymentData> _future;
  var _isPaying = false;
  var _selectedPaymentMethod = _PaymentMethod.qris;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_ReviewPaymentData> _loadData() async {
    final order = await _resolveOrder();
    final apiClient = getIt<ApiClient>();
    final invoice = await _tryLoadInvoice(apiClient, order);
    final purchases = await _tryLoadPurchases(apiClient);
    final items = _buildReviewItems(order, invoice, purchases);

    // Evaluate price anomalies via RAG ask pipeline
    await _evaluateAnomalies(items);

    final total =
        invoice?.grandTotal ??
        order.grandTotal ??
        items.fold<int>(0, (sum, item) => sum + item.amount);

    return _ReviewPaymentData(
      order: order,
      invoice: invoice,
      items: items,
      total: total,
      appTransactionFee: _appTransactionFee,
    );
  }

  Future<void> _evaluateAnomalies(List<_ReviewLineItem> items) async {
    print('--- RAG EVALUATION START ---');
    print('Evaluating ${items.length} items:');
    for (final item in items) {
      print(' - Item: "${item.title}" | Amount: ${item.amount} | Category: ${item.category}');
    }
    
    try {
      if (items.isEmpty) {
        print('No items to evaluate.');
        return;
      }
      
      final titles = items.map((item) => item.title).join(', ');
      print('Querying RAG with titles: "$titles"');
      
      final dio = Dio();
      final response = await dio.post(
        'https://ragrag-api.azurewebsites.net/ask',
        data: {
          'question': 'Berapa harga patokan untuk layanan-layanan berikut? $titles',
        },
      );
      
      print('RAG Response Status: ${response.statusCode}');
      final responseData = response.data;
      if (responseData != null && responseData['answer'] is String) {
        final answer = responseData['answer'] as String;
        print('RAG Raw Answer:\n$answer\n');
        
        final patokanPrices = RagParser.parsePatokanPrices(answer);
        print('Parsed Patokan Prices: $patokanPrices');
        
        for (final item in items) {
          final patokanPrice = RagParser.findPatokanPrice(item.title, patokanPrices);
          print('Matching "${item.title}": matched patokan price = $patokanPrice');
          if (patokanPrice != null && item.amount > patokanPrice) {
            final diffPercent = ((item.amount - patokanPrice) / patokanPrice * 100).round();
            print('  Price is higher: offered = ${item.amount}, patokan = $patokanPrice, markup = $diffPercent%');
            if (diffPercent >= 20) {
              item.isAnomaly = true;
              item.anomalyWarning = 'Perhatian: Harga ini $diffPercent% lebih tinggi dari rata-rata pasar (harga patokan Rp ${NumberFormat('#,###', 'id').format(patokanPrice)}). Silakan konfirmasi kembali dengan tukang.';
              print('  --> FLAGGED AS ANOMALY! Warning: ${item.anomalyWarning}');
            } else {
              print('  --> Under 20% markup, not flagged.');
            }
          } else {
            print('  --> Not higher than patokan or no patokan price found.');
          }
        }
      } else {
        print('RAG ResponseData has null or invalid answer: $responseData');
      }
    } catch (e, stackTrace) {
      print('RAG Evaluation Error: $e');
      print(stackTrace);
    }
    print('--- RAG EVALUATION END ---');
  }

  Future<OrderDetail> _resolveOrder() async {
    final initialOrder = widget.initialOrder;
    if (initialOrder != null) return initialOrder;

    final orderResult = await getIt<OrderRepository>().getOrderDetail(
      widget.orderId,
    );
    return orderResult.fold(
      (failure) => throw Exception(failure.message),
      (order) => order,
    );
  }

  Future<_ReviewInvoice?> _tryLoadInvoice(
    ApiClient apiClient,
    OrderDetail order,
  ) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.orderInvoice(widget.orderId),
      );
      final data = response.data ?? const <String, dynamic>{};
      final raw = data['data'];
      final invoiceJson = raw is Map<String, dynamic>
          ? raw
          : raw is Map
          ? Map<String, dynamic>.from(raw)
          : data;
      return _ReviewInvoice.fromJson(invoiceJson, order);
    } on DioException {
      return null;
    } on Exception {
      return null;
    }
  }

  Future<List<_ReviewLineItem>> _tryLoadPurchases(ApiClient apiClient) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.orderPurchases(widget.orderId),
      );
      final data = response.data ?? const <String, dynamic>{};
      final raw = data['data'];
      final list = raw is List
          ? raw
          : raw is Map && raw['purchases'] is List
          ? raw['purchases'] as List
          : const <dynamic>[];

      return list.map(_ReviewLineItem.fromPurchaseJson).toList();
    } on DioException {
      return const [];
    } on Exception {
      return const [];
    }
  }

  List<_ReviewLineItem> _buildReviewItems(
    OrderDetail order,
    _ReviewInvoice? invoice,
    List<_ReviewLineItem> purchases,
  ) {
    final items = <_ReviewLineItem>[];
    final serviceFee = invoice?.baseServiceFee ?? order.baseServiceFee ?? 0;
    if (serviceFee > 0) {
      items.add(
        _ReviewLineItem(
          title: order.serviceInfo?.name ?? order.title,
          subtitle: 'Sesuai dengan rata-rata layanan serupa di area sekitar',
          amount: serviceFee,
          category: 'service',
        ),
      );
    }

    if (invoice != null && invoice.items.isNotEmpty) {
      // API returns line_items as detailed breakdown
      items.addAll(invoice.items);
    } else {
      // API often returns empty line_items but non-zero materialsTotal —
      // show material cost as a single aggregated row
      final materialCost = invoice?.materialsTotal ?? 0;
      if (materialCost > 0) {
        items.add(
          _ReviewLineItem(
            title: 'Biaya Material & Bahan',
            subtitle: 'Material yang ditambahkan selama pengerjaan',
            amount: materialCost,
            category: 'material',
          ),
        );
      } else if (purchases.isNotEmpty) {
        // No invoice material total — fall back to purchase records
        items.addAll(purchases);
      } else if (order.totalMaterialCost > 0) {
        // Final fallback: order-level material cost
        items.add(
          _ReviewLineItem(
            title: 'Biaya Material',
            subtitle: 'Material yang ditambahkan selama pengerjaan',
            amount: order.totalMaterialCost,
            category: 'material',
          ),
        );
      }
    }

    return items;
  }

  Future<void> _pay(_ReviewPaymentData data) async {
    setState(() => _isPaying = true);
    try {
      final paymentMethod = _selectedPaymentMethod.apiValue;
      final response = await getIt<ApiClient>().post<Map<String, dynamic>>(
        ApiEndpoints.orderPayment(widget.orderId),
        data: {
          'payment_method': paymentMethod,
          'amount': data.payableTotal,
          'gross_amount': data.payableTotal,
        },
      );
      if (!mounted) return;

      final rawResponse = response.data;
      final rawData = rawResponse != null ? rawResponse['data'] : null;
      final paymentId = rawData is Map<String, dynamic>
          ? rawData['payment_id'] as String?
          : rawData is Map
              ? rawData['payment_id'] as String?
              : rawResponse != null
                  ? rawResponse['payment_id'] as String?
                  : null;

      if (_selectedPaymentMethod == _PaymentMethod.cash) {
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
            // Ignore callback error to avoid blocking success screen transition
          }
        }

        context.go(
          '/orders/${widget.orderId}/payment-success',
          extra: {
            'workerName': data.order.workerInfo?.fullName ?? 'Tukang',
            'serviceName': data.order.serviceInfo?.name ?? data.order.title,
            'total': data.payableTotal,
            'paymentMethod': _selectedPaymentMethod.label,
          },
        );
        return;
      }

      final paymentTarget = _extractPaymentTarget(response.data);
      final redirectUrl = paymentTarget.url;
      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw Exception('Payment gateway belum mengirim redirect_url.');
      }

      unawaited(
        context.push(
          '/orders/${widget.orderId}/payment-webview',
          extra: {
            'url': _normalizePaymentUrl(redirectUrl),
            'token': paymentTarget.token,
            'paymentId': paymentId,
            'workerName': data.order.workerInfo?.fullName ?? 'Tukang',
            'serviceName': data.order.serviceInfo?.name ?? data.order.title,
            'total': data.payableTotal,
            'paymentMethod': _selectedPaymentMethod.label,
          },
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? data['message'] as String? ?? 'Gagal memproses pembayaran'
          : 'Gagal memproses pembayaran';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  _PaymentTarget _extractPaymentTarget(Map<String, dynamic>? response) {
    if (response == null) return const _PaymentTarget();
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return _PaymentTarget(
        url: _pickPaymentUrl(data),
        token: data['token'] as String? ?? data['snap_token'] as String?,
      );
    }
    if (data is Map) {
      final mapped = Map<String, dynamic>.from(data);
      return _PaymentTarget(
        url: _pickPaymentUrl(mapped),
        token: mapped['token'] as String? ?? mapped['snap_token'] as String?,
      );
    }
    return _PaymentTarget(
      url: _pickPaymentUrl(response),
      token: response['token'] as String? ?? response['snap_token'] as String?,
    );
  }

  String? _pickPaymentUrl(Map<String, dynamic> data) {
    final directUrl = data['redirect_url'] as String?;
    if (directUrl != null && directUrl.isNotEmpty) return directUrl;

    final snapRedirectUrl = data['snap_redirect_url'] as String?;
    if (snapRedirectUrl != null && snapRedirectUrl.isNotEmpty) {
      return snapRedirectUrl;
    }

    final token = data['token'] as String? ?? data['snap_token'] as String?;
    if (token == null || token.isEmpty) return null;
    return 'https://app.sandbox.midtrans.com/snap/v2/vtweb/$token';
  }

  String _normalizePaymentUrl(String rawUrl) {
    final uri = Uri.parse(rawUrl);
    if (!uri.hasScheme) {
      final baseUri = Uri.parse(AppConstants.baseUrl);
      return baseUri.replace(path: uri.path, query: uri.query).toString();
    }
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      final baseUri = Uri.parse(AppConstants.baseUrl);
      return baseUri
          .replace(path: uri.path, query: uri.query, fragment: uri.fragment)
          .toString();
    }
    return rawUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: FutureBuilder<_ReviewPaymentData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: () => setState(() => _future = _loadData()),
              );
            }
            final data = snapshot.data!;
            return _buildContent(context, data);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, _ReviewPaymentData data) {
    final worker = data.order.workerInfo;

    return Column(
      children: [
        _Header(
          workerName: worker?.fullName ?? 'Tukang',
          workerAvatarUrl: worker?.avatarUrl,
          status: 'Menyelesaikan pembayaran',
          onBack: () => context.pop(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionTitle('Review Pembayaran'),
                const SizedBox(height: 14),
                Text(
                  'Tinjau Rincian Pekerjaan',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF122033),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Periksa detail biaya sebelum membayar',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (data.items.isEmpty)
                  const _EmptyCostCard()
                else
                  ...data.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CostReviewCard(item: item),
                    ),
                  ),
                const SizedBox(height: 16),
                const _AiInfoBox(),
                const SizedBox(height: 18),
                _PaymentMethodSection(
                  selectedMethod: _selectedPaymentMethod,
                  onChanged: (method) {
                    setState(() => _selectedPaymentMethod = method);
                  },
                ),
                const SizedBox(height: 18),
                _TotalRow(
                  subtotal: data.total,
                  appTransactionFee: data.appTransactionFee,
                  total: data.payableTotal,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/chat/${widget.orderId}',
                    extra: worker?.fullName ?? 'Tukang',
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Hubungi Tukang'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _brandTeal,
                    side: const BorderSide(color: _brandTeal, width: 1.5),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: AppTypography.buttonMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isPaying ? null : () => _pay(data),
                  icon: _isPaying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payments_outlined, size: 18),
                  label: Text(_selectedPaymentMethod.ctaLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: AppTypography.buttonMedium.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _PaymentMethod {
  qris(
    label: 'QRIS',
    description: 'Bayar via Midtrans QRIS',
    apiValue: 'ewallet',
    ctaLabel: 'Lanjut ke QRIS',
    icon: Icons.qr_code_2,
  ),
  cash(
    label: 'Cash',
    description: 'Bayar tunai ke tukang',
    apiValue: 'cash',
    ctaLabel: 'Konfirmasi Cash',
    icon: Icons.payments_outlined,
  );

  const _PaymentMethod({
    required this.label,
    required this.description,
    required this.apiValue,
    required this.ctaLabel,
    required this.icon,
  });

  final String label;
  final String description;
  final String apiValue;
  final String ctaLabel;
  final IconData icon;
}

class _ReviewPaymentData {
  const _ReviewPaymentData({
    required this.order,
    required this.items,
    required this.total,
    required this.appTransactionFee,
    this.invoice,
  });

  final OrderDetail order;
  final _ReviewInvoice? invoice;
  final List<_ReviewLineItem> items;
  final int total;
  final int appTransactionFee;

  int get payableTotal => total + appTransactionFee;
}

class _PaymentTarget {
  const _PaymentTarget({this.url, this.token});

  final String? url;
  final String? token;
}

class _ReviewInvoice {
  const _ReviewInvoice({
    required this.baseServiceFee,
    required this.materialsTotal,
    required this.grandTotal,
    required this.items,
  });

  factory _ReviewInvoice.fromJson(
    Map<String, dynamic> json,
    OrderDetail order,
  ) {
    // API returns 'line_items' (not 'items' or 'invoice_line_items')
    final rawItems =
        json['line_items'] ?? json['items'] ?? json['invoice_line_items'];
    return _ReviewInvoice(
      baseServiceFee: _asInt(json['base_service_fee'] ?? order.baseServiceFee),
      // API returns 'total_material_cost' (not 'materials_total')
      materialsTotal: _asInt(
        json['total_material_cost'] ?? json['materials_total'] ?? json['total_material_cost'],
      ),
      grandTotal: _asInt(json['grand_total'] ?? order.grandTotal),
      items: rawItems is List
          ? rawItems.map(_ReviewLineItem.fromInvoiceJson).toList()
          : const [],
    );
  }

  final int baseServiceFee;
  final int materialsTotal;
  final int grandTotal;
  final List<_ReviewLineItem> items;
}

class _ReviewLineItem {
  _ReviewLineItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.category,
    this.isAnomaly = false,
    this.anomalyWarning = '',
  });

  factory _ReviewLineItem.fromInvoiceJson(dynamic raw) {
    final json = raw is Map<String, dynamic>
        ? raw
        : raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final quantity = _asDouble(json['quantity']) ?? 1;
    final unit = json['unit'] as String?;
    return _ReviewLineItem(
      title:
          json['name'] as String? ??
          json['label'] as String? ??
          json['item_name'] as String? ??
          'Item Biaya',
      subtitle: quantity > 1 && unit != null
          ? '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)} $unit'
          : json['description'] as String? ?? 'Harga wajar',
      amount: _asInt(json['total_price'] ?? json['amount']),
      category:
          json['type'] as String? ?? json['category'] as String? ?? 'material',
    );
  }

  factory _ReviewLineItem.fromPurchaseJson(dynamic raw) {
    final json = raw is Map<String, dynamic>
        ? raw
        : raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final quantity = _asDouble(json['quantity']) ?? 1;
    final unit = json['unit'] as String? ?? 'pcs';
    return _ReviewLineItem(
      title: json['item_name'] as String? ?? 'Material',
      subtitle: '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)} $unit',
      amount: _asInt(json['total_price']),
      category: json['category'] as String? ?? 'material',
    );
  }

  final String title;
  final String subtitle;
  final int amount;
  final String category;
  bool isAnomaly;
  String anomalyWarning;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.workerName,
    required this.status,
    required this.onBack,
    this.workerAvatarUrl,
  });

  final String workerName;
  final String status;
  final String? workerAvatarUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6ECF1))),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          CircleAvatar(
            radius: 18,
            backgroundImage: workerAvatarUrl == null
                ? null
                : NetworkImage(workerAvatarUrl!),
            child: workerAvatarUrl == null
                ? const Icon(Icons.person, size: 18)
                : null,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workerName,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  status,
                  style: AppTypography.caption.copyWith(
                    color: _OrderPaymentReviewPageState._gojekGreen,
                    fontWeight: FontWeight.w800,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.label.copyWith(
            color: _OrderPaymentReviewPageState._brandTeal,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 66,
          height: 3,
          decoration: BoxDecoration(
            color: _OrderPaymentReviewPageState._brandTeal,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _CostReviewCard extends StatelessWidget {
  const _CostReviewCard({required this.item});

  final _ReviewLineItem item;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id');
    
    final backgroundColor = item.isAnomaly ? const Color(0xFFFFF1F1) : Colors.white;
    final borderColor = item.isAnomaly ? const Color(0xFFFFD2D2) : const Color(0xFFE4EAF0);
    final amountColor = item.isAnomaly 
        ? _OrderPaymentReviewPageState._dangerRed 
        : _OrderPaymentReviewPageState._brandTeal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: item.isAnomaly ? 1.2 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                'Rp ${formatter.format(item.amount)}',
                style: AppTypography.caption.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (item.isAnomaly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Anomali Harga',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            const _FairBadge(),
          const SizedBox(height: 9),
          Text(
            item.isAnomaly
                ? item.anomalyWarning
                : item.subtitle.isEmpty
                    ? 'Sesuai dengan harga pasar saat ini'
                    : item.subtitle,
            style: AppTypography.caption.copyWith(
              color: item.isAnomaly 
                  ? _OrderPaymentReviewPageState._dangerRed 
                  : AppColors.textSecondary,
              fontWeight: item.isAnomaly ? FontWeight.w700 : FontWeight.normal,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _FairBadge extends StatelessWidget {
  const _FairBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F8ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 12, color: Color(0xFF00AA13)),
          const SizedBox(width: 4),
          Text(
            'Harga Wajar',
            style: AppTypography.caption.copyWith(
              color: const Color(0xFF008C2E),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInfoBox extends StatelessWidget {
  const _AiInfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _OrderPaymentReviewPageState._softBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF9DDBEE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_fix_high,
            color: _OrderPaymentReviewPageState._brandTeal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Analisis kami menggunakan data transaksi real-time di Jakarta Selatan untuk memastikan Anda membayar dengan harga yang adil.',
              style: AppTypography.caption.copyWith(
                color: _OrderPaymentReviewPageState._brandTeal,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodSection extends StatelessWidget {
  const _PaymentMethodSection({
    required this.selectedMethod,
    required this.onChanged,
  });

  final _PaymentMethod selectedMethod;
  final ValueChanged<_PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode Pembayaran',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF122033),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PaymentMethodCard(
                method: _PaymentMethod.qris,
                isSelected: selectedMethod == _PaymentMethod.qris,
                onTap: () => onChanged(_PaymentMethod.qris),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PaymentMethodCard(
                method: _PaymentMethod.cash,
                isSelected: selectedMethod == _PaymentMethod.cash,
                onTap: () => onChanged(_PaymentMethod.cash),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? _OrderPaymentReviewPageState._gojekGreen
        : const Color(0xFFCBD5E1);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent, width: isSelected ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? _OrderPaymentReviewPageState._gojekGreen.withValues(
                        alpha: 0.12,
                      )
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 14 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE7F8ED)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(method.icon, color: accent, size: 20),
                  ),
                  const Spacer(),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: accent,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                method.label,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                method.description,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.subtotal,
    required this.appTransactionFee,
    required this.total,
  });

  final int subtotal;
  final int appTransactionFee;
  final int total;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Column(
        children: [
          _PriceLine(label: 'Subtotal Pekerjaan', value: subtotal),
          const SizedBox(height: 8),
          _PriceLine(
            label: 'Pajak Aplikasi',
            value: appTransactionFee,
            valueColor: _OrderPaymentReviewPageState._gojekGreen,
          ),
          const Divider(height: 22),
          Row(
            children: [
              Text(
                'Total Tagihan',
                style: AppTypography.bodyMedium.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                'Rp ${formatter.format(total)}',
                style: AppTypography.h5.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.label, required this.value, this.valueColor});

  final String label;
  final int value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id');
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          'Rp ${formatter.format(value)}',
          style: AppTypography.bodySmall.copyWith(
            color: valueColor ?? const Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyCostCard extends StatelessWidget {
  const _EmptyCostCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Text(
        'Rincian invoice belum tersedia. Data akan muncul setelah invoice dibuat oleh backend.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
