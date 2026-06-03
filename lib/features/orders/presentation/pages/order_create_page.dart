import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/create_order_params.dart';
import '../../domain/entities/order.dart';
import '../bloc/order_bloc.dart';

/// Page for creating a new service order.
///
/// Displays a form with worker pre-filled, service selection, title,
/// description, photos, location, preferred date/time, urgency,
/// address detail, and notes.
///
/// Validates: Requirements 7.1-7.9
class OrderCreatePage extends StatefulWidget {
  const OrderCreatePage({
    super.key,
    required this.workerId,
    required this.workerName,
    this.workerAvatarUrl,
    this.services = const [],
  });

  /// The pre-selected worker's ID.
  final String workerId;

  /// The pre-selected worker's name (for display).
  final String workerName;

  /// The worker's avatar URL.
  final String? workerAvatarUrl;

  /// Available services from the worker.
  final List<OrderServiceOption> services;

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

/// Represents a service option for the order creation form.
class OrderServiceOption {
  const OrderServiceOption({
    required this.id,
    required this.name,
    this.basePrice,
  });

  final String id;
  final String name;
  final int? basePrice;
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressDetailController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedServiceId;
  OrderUrgency _urgency = OrderUrgency.normal;
  DateTime? _preferredDate;
  TimeOfDay? _preferredTimeStart;
  TimeOfDay? _preferredTimeEnd;
  final List<File> _photos = [];
  double? _latitude;
  double? _longitude;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pesanan'),
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: _onStateChanged,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWorkerInfo(),
                const SizedBox(height: AppSpacing.formSectionSpacing),
                _buildServiceSelection(),
                const SizedBox(height: AppSpacing.formFieldSpacing),
                _buildTitleField(),
                const SizedBox(height: AppSpacing.formFieldSpacing),
                _buildDescriptionField(),
                const SizedBox(height: AppSpacing.formFieldSpacing),
                _buildPhotosSection(),
                const SizedBox(height: AppSpacing.formSectionSpacing),
                _buildLocationSection(),
                const SizedBox(height: AppSpacing.formFieldSpacing),
                _buildAddressDetailField(),
                const SizedBox(height: AppSpacing.formSectionSpacing),
                _buildScheduleSection(),
                const SizedBox(height: AppSpacing.formFieldSpacing),
                _buildUrgencySection(),
                const SizedBox(height: AppSpacing.formFieldSpacing),
                _buildNotesField(),
                const SizedBox(height: AppSpacing.formSectionSpacing),
                _buildBookingFeeInfo(),
                const SizedBox(height: AppSpacing.lg),
                _buildSubmitButton(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerInfo() {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSizing.avatarMd / 2,
            backgroundImage: widget.workerAvatarUrl != null
                ? NetworkImage(widget.workerAvatarUrl!)
                : null,
            child: widget.workerAvatarUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tukang',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.workerName,
                  style: AppTypography.h6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Layanan *', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          value: _selectedServiceId,
          decoration: const InputDecoration(
            hintText: 'Pilih layanan',
          ),
          items: widget.services
              .map((service) => DropdownMenuItem(
                    value: service.id,
                    child: Text(service.name),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedServiceId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Pilih layanan yang diinginkan';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return AppTextField(
      controller: _titleController,
      label: 'Judul *',
      hint: 'Contoh: AC tidak dingin',
      maxLength: 255,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Judul tidak boleh kosong';
        }
        return InputLengthValidator.validate(
          value,
          255,
          fieldName: 'Judul',
        );
      },
    );
  }

  Widget _buildDescriptionField() {
    return AppTextField(
      controller: _descriptionController,
      label: 'Deskripsi *',
      hint: 'Jelaskan masalah yang Anda alami...',
      maxLength: 2000,
      maxLines: 5,
      minLines: 3,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Deskripsi tidak boleh kosong';
        }
        return InputLengthValidator.validate(
          value,
          2000,
          fieldName: 'Deskripsi',
        );
      },
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto (maks. ${AppConstants.maxOrderPhotos})',
          style: AppTypography.label,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'JPG/PNG, maks. 5MB per foto',
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ..._photos.asMap().entries.map((entry) => _buildPhotoThumbnail(
                  entry.value,
                  entry.key,
                )),
            if (_photos.length < AppConstants.maxOrderPhotos)
              _buildAddPhotoButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(File photo, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          child: Image.file(
            photo,
            width: AppSizing.thumbnailLg,
            height: AppSizing.thumbnailLg,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.close,
                size: AppSizing.iconXs,
                color: AppColors.onError,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: AppSizing.thumbnailLg,
        height: AppSizing.thumbnailLg,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: AppSizing.iconLg,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppSpacing.xs),
            Text('Tambah', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lokasi *', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _addressController,
          hint: 'Masukkan alamat lokasi pekerjaan',
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          prefixIcon: const Icon(Icons.location_on_outlined),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Alamat lokasi tidak boleh kosong';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _useCurrentLocation,
          icon: const Icon(Icons.my_location),
          label: Text(
            _latitude == null || _longitude == null
                ? 'Gunakan Lokasi Saat Ini'
                : 'Lokasi Saat Ini Dipakai',
          ),
        ),
      ],
    );
  }

  Widget _buildAddressDetailField() {
    return AppTextField(
      controller: _addressDetailController,
      label: 'Detail Alamat',
      hint: 'Contoh: Lantai 2, dekat lift',
      maxLength: 500,
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          return InputLengthValidator.validate(
            value,
            500,
            fieldName: 'Detail alamat',
          );
        }
        return null;
      },
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jadwal Preferensi', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        // Date picker
        GestureDetector(
          onTap: _pickDate,
          child: AbsorbPointer(
            child: AppTextField(
              controller: TextEditingController(
                text: _preferredDate != null
                    ? DateFormat('dd MMMM yyyy', 'id').format(_preferredDate!)
                    : '',
              ),
              hint: 'Pilih tanggal',
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              suffixIcon: _preferredDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _preferredDate = null;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Time range
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickTime(isStart: true),
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: TextEditingController(
                      text: _preferredTimeStart != null
                          ? _formatTimeOfDay(_preferredTimeStart!)
                          : '',
                    ),
                    hint: 'Dari',
                    prefixIcon: const Icon(Icons.access_time),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickTime(isStart: false),
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: TextEditingController(
                      text: _preferredTimeEnd != null
                          ? _formatTimeOfDay(_preferredTimeEnd!)
                          : '',
                    ),
                    hint: 'Sampai',
                    prefixIcon: const Icon(Icons.access_time),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Urgensi', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildUrgencyOption(
                OrderUrgency.normal,
                'Normal',
                Icons.schedule,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildUrgencyOption(
                OrderUrgency.urgent,
                'Urgent',
                Icons.priority_high,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgencyOption(
    OrderUrgency urgency,
    String label,
    IconData icon,
  ) {
    final isSelected = _urgency == urgency;
    return GestureDetector(
      onTap: () {
        setState(() {
          _urgency = urgency;
        });
      },
      child: Container(
        padding: AppSpacing.cardPaddingSmall,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppSizing.iconSm,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return AppTextField(
      controller: _notesController,
      label: 'Catatan Tambahan',
      hint: 'Informasi tambahan untuk tukang...',
      maxLength: 1000,
      maxLines: 3,
      minLines: 2,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          return InputLengthValidator.validate(
            value,
            1000,
            fieldName: 'Catatan',
          );
        }
        return null;
      },
    );
  }

  Widget _buildBookingFeeInfo() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: AppSizing.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biaya Booking',
                  style: AppTypography.label.copyWith(color: AppColors.info),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Rp${NumberFormat('#,###', 'id').format(AppConstants.bookingFee)}',
                  style: AppTypography.priceMedium.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        return AppButton(
          text: 'Buat Pesanan',
          isLoading: state is OrderLoading,
          onPressed: _submitOrder,
        );
      },
    );
  }

  void _onStateChanged(BuildContext context, OrderState state) {
    if (state is OrderCreated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pesanan berhasil dibuat! No: ${state.order.orderNumber}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(state.order);
    } else if (state is OrderError) {
      final message = _getErrorMessage(state.failure);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure && failure.statusCode == 422) {
      return failure.message;
    }
    if (failure is ValidationFailure) {
      return failure.fieldErrors.values.first;
    }
    return failure.message;
  }

  Future<void> _pickPhoto() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileSize = await file.length();
      final fileName = pickedFile.name;

      final validationError = FileUploadValidator.validate(
        fileName,
        fileSize,
        maxSize: AppConstants.maxPhotoFileSize,
      );

      if (validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationError),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() {
        _photos.add(file);
      });
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
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
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _preferredDate = picked;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_preferredTimeStart ?? TimeOfDay.now())
        : (_preferredTimeEnd ?? TimeOfDay.now());

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _preferredTimeStart = picked;
        } else {
          _preferredTimeEnd = picked;
        }
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi dibutuhkan untuk membuat pesanan'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil lokasi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _submitOrder() {
    if (!_formKey.currentState!.validate()) return;

    // Validate required fields not covered by form validators
    if (_selectedServiceId == null) return;

    if (_addressController.text.trim().isEmpty) return;

    // Validate date not in past
    if (_preferredDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (_preferredDate!.isBefore(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal preferensi tidak boleh di masa lalu'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gunakan lokasi saat ini sebelum membuat pesanan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final params = CreateOrderParams(
      workerId: widget.workerId,
      serviceId: _selectedServiceId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      latitude: _latitude!,
      longitude: _longitude!,
      address: _addressController.text.trim(),
      addressDetail: _addressDetailController.text.trim().isNotEmpty
          ? _addressDetailController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      urgency: _urgency.value,
      preferredDate: _preferredDate != null
          ? DateFormat('yyyy-MM-dd').format(_preferredDate!)
          : null,
      preferredTimeStart: _preferredTimeStart != null
          ? _formatTimeOfDay(_preferredTimeStart!)
          : null,
      preferredTimeEnd: _preferredTimeEnd != null
          ? _formatTimeOfDay(_preferredTimeEnd!)
          : null,
      photos: _photos,
    );

    context.read<OrderBloc>().add(CreateOrderRequested(params: params));
  }

  /// Sets the location coordinates (called from location picker).
  void setLocation(double latitude, double longitude) {
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
    });
  }
}
