import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:situkang_app/core/constants/app_constants.dart';
import 'package:situkang_app/core/theme/theme.dart';
import 'worker_order_items_page.dart'; // To access PurchaseInput

class WorkerInvoiceScanPage extends StatefulWidget {
  const WorkerInvoiceScanPage({required this.orderId, super.key});

  final String orderId;

  @override
  State<WorkerInvoiceScanPage> createState() => _WorkerInvoiceScanPageState();
}

class _WorkerInvoiceScanPageState extends State<WorkerInvoiceScanPage>
    with SingleTickerProviderStateMixin {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  
  late AnimationController _scannerAnimationController;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _scannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // Select back camera
      final backCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scannerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_isCameraInitialized || _isProcessing) return;

    try {
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      final XFile imageFile = await _cameraController!.takePicture();
      await _processInvoiceImage(imageFile.path);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Gagal mengambil gambar: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    try {
      final XFile? imageFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (imageFile == null) return;

      setState(() => _isProcessing = true);
      await _processInvoiceImage(imageFile.path);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Gagal mengambil gambar dari galeri: $e');
    }
  }

  Future<void> _processInvoiceImage(String imagePath) async {
    var apiKey = AppConstants.geminiApiKey.trim();
    if (apiKey.startsWith('"') && apiKey.endsWith('"')) {
      apiKey = apiKey.substring(1, apiKey.length - 1);
    } else if (apiKey.startsWith("'") && apiKey.endsWith("'")) {
      apiKey = apiKey.substring(1, apiKey.length - 1);
    }
    apiKey = apiKey.trim();

    if (apiKey.isEmpty) {
      _showNoApiKeyDialog(imagePath);
      return;
    }

    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final dio = Dio();
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

      final response = await dio.post<Map<String, dynamic>>(
        url,
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Misi Anda adalah mengekstrak item material/bahan bangunan dari kuitansi/invoice belanja ini. '
                      'Kembalikan data dalam format JSON array berisi objek dengan properti: '
                      '"itemName" (nama barang), "quantity" (jumlah barang, bertipe integer/angka), '
                      '"unit" (satuan barang, misal: pcs, sak, kg), "unitPrice" (harga per satuan, bertipe integer/angka), '
                      '"totalPrice" (harga total hasil perkalian jumlah dan harga satuan, bertipe integer/angka), '
                      'dan "reason" (catatan/alasan kebutuhan, kosongkan saja ""). '
                      'Kembalikan HANYA array JSON mentah sesuai format tersebut, tanpa format markdown ```json ... ```.'
                },
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        },
      );

      final candidates = response.data?['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Tidak ada respon candidates dari Gemini AI');
      }

      final text = candidates.first['content']['parts'].first['text'] as String;
      final parsedJson = jsonDecode(text.trim());

      if (parsedJson is! List) {
        throw Exception('Format respon tidak sesuai (harus List JSON)');
      }

      final List<PurchaseInput> items = [];
      for (final item in parsedJson) {
        if (item is Map<String, dynamic>) {
          final itemName = item['itemName'] as String? ?? '';
          if (itemName.isEmpty) continue;
          
          final quantity = (item['quantity'] as num? ?? 1).toInt();
          final unit = item['unit'] as String? ?? 'pcs';
          final unitPrice = (item['unitPrice'] as num? ?? 0).toInt();
          final totalPrice = (item['totalPrice'] as num? ?? (quantity * unitPrice)).toInt();
          final reason = item['reason'] as String? ?? '';

          items.add(PurchaseInput(
            itemName: itemName,
            quantity: quantity,
            unit: unit,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
            reason: reason,
          ));
        }
      }

      if (items.isEmpty) {
        throw Exception('Tidak ada barang material yang berhasil diekstrak dari gambar ini.');
      }

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.of(context).pop(items);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        var finalError = e.toString();
        if (e is DioException) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 404) {
            finalError = 'DioException [bad response] (404):\n'
                '- Pastikan API Key Gemini yang dimasukkan valid dan benar.\n'
                '- Pastikan "Generative Language API" sudah di-enable di Google Cloud Console untuk API Key ini.\n'
                '- Pastikan regional Anda memiliki akses ke model gemini-2.5-flash.\n\n'
                'Detail:\n${e.message ?? e.toString()}';
          }
        }
        _showScanErrorDialog(imagePath, finalError);
      }
    }
  }

  void _showNoApiKeyDialog(String imagePath) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API Key Belum Dikonfigurasi'),
        content: const Text(
          'API Key untuk Gemini AI belum didefinisikan di environment (GEMINI_API_KEY). '
          'Anda dapat mensimulasikan hasil deteksi invoice untuk keperluan pengujian.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isProcessing = false);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _simulateScannedItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00647C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simulasi Scan'),
          ),
        ],
      ),
    );
  }

  void _showScanErrorDialog(String imagePath, String errorMessage) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Gagal Memindai Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aplikasi gagal memproses gambar invoice ini melalui AI. Silakan coba lagi atau gunakan simulasi.',
            ),
            const SizedBox(height: 10),
            Text(
              'Error: $errorMessage',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _simulateScannedItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00647C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simulasi Scan'),
          ),
        ],
      ),
    );
  }

  void _simulateScannedItems() {
    final mockItems = [
      const PurchaseInput(
        itemName: 'Semen Tiga Roda 40kg',
        quantity: 5,
        unit: 'sak',
        unitPrice: 65000,
        totalPrice: 325000,
        reason: 'Pemindaian struk toko bangunan',
      ),
      const PurchaseInput(
        itemName: 'Pipa PVC Wavin 1/2"',
        quantity: 4,
        unit: 'lonjor',
        unitPrice: 28000,
        totalPrice: 112000,
        reason: 'Pemindaian struk toko bangunan',
      ),
      const PurchaseInput(
        itemName: 'Kran Air Stainless Tebal',
        quantity: 2,
        unit: 'pcs',
        unitPrice: 45000,
        totalPrice: 90000,
        reason: 'Pemindaian struk toko bangunan',
      ),
    ];
    Navigator.of(context).pop(mockItems);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCameraActive = _isCameraInitialized && _cameraController != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview / Black background
          if (isCameraActive)
            Center(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // 2. Custom Bounding Box & Translucent Overlay
          AnimatedBuilder(
            animation: _scannerAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ScannerOverlayPainter(
                  scanWindowSize: Size(size.width * 0.85, size.height * 0.45),
                  laserProgress: _scannerAnimationController.value,
                ),
              );
            },
          ),

          // 3. UI Controls Layout
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      Text(
                        'Pindai Struk / Invoice',
                        style: AppTypography.label.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        child: IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Helper Instruction Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Posisikan nota belanja material di dalam bingkai',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Bottom control panel ( frosted glass feel )
                Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                            onPressed: _pickFromGallery,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Galeri',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),

                      // Take Photo Shutter
                      GestureDetector(
                        onTap: _captureAndProcess,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Simulator button
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.analytics_outlined, color: Colors.tealAccent, size: 28),
                            onPressed: _simulateScannedItems,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Simulasi',
                            style: TextStyle(color: Colors.tealAccent, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Processing overlay screen
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        color: Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Menganalisis Invoice...',
                      style: AppTypography.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI sedang mengekstrak detail bahan & harga',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.scanWindowSize, required this.laserProgress});

  final Size scanWindowSize;
  final double laserProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final double windowWidth = scanWindowSize.width;
    final double windowHeight = scanWindowSize.height;
    final double left = (size.width - windowWidth) / 2;
    final double top = (size.height - windowHeight) / 2.3; // slightly elevated from absolute center
    final double right = left + windowWidth;
    final double bottom = top + windowHeight;
    
    final scanRect = Rect.fromLTRB(left, top, right, bottom);

    // 1. Draw dark background masking everything except scanWindow
    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, path, Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))), 
      backgroundPaint,
    );

    // 2. Draw white translucent border around scanning rect
    final framePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)), framePaint);

    // 3. Draw neon teal corner brackets
    final cornerPaint = Paint()
      ..color = Colors.tealAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const double cornerLen = 24.0;
    const double radius = 16.0;

    // Top Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(left + cornerLen, top)
        ..arcToPoint(Offset(left, top + radius), radius: const Radius.circular(radius), clockwise: false)
        ..lineTo(left, top + cornerLen),
      cornerPaint,
    );

    // Top Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLen, top)
        ..arcToPoint(Offset(right, top + radius), radius: const Radius.circular(radius))
        ..lineTo(right, top + cornerLen),
      cornerPaint,
    );

    // Bottom Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(left + cornerLen, bottom)
        ..arcToPoint(Offset(left, bottom - radius), radius: const Radius.circular(radius))
        ..lineTo(left, bottom - cornerLen),
      cornerPaint,
    );

    // Bottom Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLen, bottom)
        ..arcToPoint(Offset(right, bottom - radius), radius: const Radius.circular(radius), clockwise: false)
        ..lineTo(right, bottom - cornerLen),
      cornerPaint,
    );

    // 4. Draw moving red/teal laser line
    final double laserY = top + (windowHeight * laserProgress);
    final laserPaint = Paint()
      ..color = Colors.tealAccent.withValues(alpha: 0.8)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(left + 8, laserY), Offset(right - 8, laserY), laserPaint);

    // Draw fading laser glow
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.tealAccent.withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTRB(left, laserY - 12, right, laserY));
    canvas.drawRect(Rect.fromLTRB(left + 8, laserY - 12, right - 8, laserY), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.laserProgress != laserProgress || oldDelegate.scanWindowSize != scanWindowSize;
  }
}
