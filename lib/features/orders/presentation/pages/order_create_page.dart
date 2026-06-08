import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/create_order_params.dart';
import '../bloc/order_bloc.dart';
import '../../../workers/domain/entities/worker_profile.dart';

class OrderCreatePage extends StatefulWidget {
  const OrderCreatePage({
    required this.workerId,
    this.workerProfile,
    this.selectedServiceId,
    super.key,
  });

  final String workerId;
  final WorkerProfile? workerProfile;
  final String? selectedServiceId;

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressDetailController = TextEditingController();
  
  final List<File> _photos = [];
  final ImagePicker _imagePicker = ImagePicker();

  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(-6.200000, 106.816666); // Default Jakarta
  bool _isLoadingLocation = true;
  String? _selectedServiceId;

  @override
  void initState() {
    super.initState();
    _selectedServiceId = widget.selectedServiceId ?? (widget.workerProfile?.services.isNotEmpty == true ? widget.workerProfile!.services.first.id : null);
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      
      _mapController.move(_selectedLocation, 15);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressDetailController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedServiceId == null || widget.workerProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih layanan terlebih dahulu.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final selectedService = widget.workerProfile!.services.firstWhere(
      (s) => s.id == _selectedServiceId,
      orElse: () => widget.workerProfile!.services.first,
    );

    final params = CreateOrderParams(
      workerId: widget.workerId,
      serviceId: selectedService.id,
      title: 'Pesanan: ${selectedService.name}',
      description: _descriptionController.text.trim(),
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      address: 'Lokasi Peta',
      addressDetail: _addressDetailController.text.trim(),
      photos: _photos,
    );

    context.read<OrderBloc>().add(CreateOrderRequested(params: params));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Pesanan'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pesanan berhasil! No: ${state.order.orderNumber}'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(); // Go back to worker detail, or maybe orders list
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMapSection(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildServiceSelector(),
                      const SizedBox(height: AppSpacing.md),
                      _buildFormFields(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (widget.workerProfile == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: widget.workerProfile!.avatarUrl != null 
                ? CachedNetworkImageProvider(widget.workerProfile!.avatarUrl!) 
                : null,
            child: widget.workerProfile!.avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.workerProfile!.fullName, style: AppTypography.h6),
                const SizedBox(height: 4),
                Text(
                  widget.workerProfile!.specialization ?? 'Spesialis',
                  style: AppTypography.caption.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelector() {
    if (widget.workerProfile == null || widget.workerProfile!.services.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Layanan', style: AppTypography.h6),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.workerProfile!.services.map((service) {
            final isSelected = _selectedServiceId == service.id;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (service.iconUrl != null) ...[
                    CachedNetworkImage(
                      imageUrl: service.iconUrl!,
                      width: 16,
                      height: 16,
                      errorWidget: (_, _, _) => const Icon(Icons.build, size: 16),
                    ),
                    const SizedBox(width: 4),
                  ] else ...[
                    Icon(Icons.build, size: 16, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: 4),
                  ],
                  Text(service.name),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) _selectedServiceId = service.id;
                });
              },
              backgroundColor: AppColors.primaryContainer.withOpacity(0.3),
              selectedColor: AppColors.primaryContainer,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lokasi Pekerjaan', style: AppTypography.h6),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation,
                  initialZoom: 15,
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture && position.center != null) {
                      _selectedLocation = position.center!;
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.situkang.app',
                  ),
                ],
              ),
              // Center pin
              const Padding(
                padding: EdgeInsets.only(bottom: 35),
                child: Icon(Icons.location_on, size: 40, color: AppColors.primary),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  heroTag: 'gps_btn',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  onPressed: () {
                    setState(() => _isLoadingLocation = true);
                    _initCurrentLocation();
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),
              if (_isLoadingLocation)
                Container(
                  color: Colors.white70,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Geser peta untuk menetapkan titik lokasi yang akurat.', style: AppTypography.caption),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detail Kerusakan', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: _descriptionController,
          hint: 'Jelaskan masalah yang Anda hadapi secara singkat...',
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Detail kerusakan wajib diisi';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),

        Text('Detail Alamat Tambahan (Opsional)', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: _addressDetailController,
          hint: 'Cth: Cat pagar warna biru, nomor rumah 12A',
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.md),

        Text('Foto Area Kerusakan (Opsional)', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ..._photos.asMap().entries.map((entry) => _buildPhotoThumbnail(entry.value, entry.key)),
            if (_photos.length < AppConstants.maxOrderPhotos) _buildAddPhotoArea(),
          ],
        ),
      ],
    );
  }

  Widget _buildAddPhotoArea() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryContainer,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 20,
              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Unggah Foto Kerusakan', style: AppTypography.label.copyWith(color: AppColors.primary)),
            Text('Maksimal 5MB (JPG/PNG)', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(File photo, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            photo,
            width: double.infinity,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _photos.removeAt(index)),
            child: Container(
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.close, size: 16, color: AppColors.onError),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) return;
      
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      if (fileSize > AppConstants.maxPhotoFileSize) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ukuran foto maksimal 5MB')));
        return;
      }
      setState(() => _photos.add(file));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Widget _buildBottomBar() {
    final bookingFee = widget.workerProfile?.bookingFee ?? AppConstants.bookingFee;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Fee', style: AppTypography.caption),
                  Text(
                    'Rp${NumberFormat('#,###', 'id').format(bookingFee)}',
                    style: AppTypography.priceMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: BlocBuilder<OrderBloc, OrderState>(
                builder: (context, state) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006C84), // Deep teal
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: state is OrderLoading ? null : _onSubmit,
                    child: state is OrderLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Konfirmasi Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.check_circle, size: 18),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
