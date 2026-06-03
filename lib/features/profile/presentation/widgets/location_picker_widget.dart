import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Data class representing a location with coordinates and address.
class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}

/// Widget for picking/updating user location with lat/lng/address input.
///
/// Provides simple text fields for latitude, longitude, and address.
/// This is a placeholder for future map integration (e.g., Google Maps picker).
class LocationPickerWidget extends StatefulWidget {
  const LocationPickerWidget({
    required this.onLocationSelected,
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.isLoading = false,
  });

  /// Initial latitude value to pre-fill.
  final double? initialLatitude;

  /// Initial longitude value to pre-fill.
  final double? initialLongitude;

  /// Initial address value to pre-fill.
  final String? initialAddress;

  /// Callback when the user confirms a location update.
  final ValueChanged<LocationData> onLocationSelected;

  /// Whether a location update is in progress.
  final bool isLoading;

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _addressController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(
      text: widget.initialLatitude?.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: widget.initialLongitude?.toString() ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initialAddress ?? '',
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final latitude = double.tryParse(_latController.text.trim());
    final longitude = double.tryParse(_lngController.text.trim());
    final address = _addressController.text.trim();

    if (latitude == null || longitude == null) return;

    widget.onLocationSelected(LocationData(
      latitude: latitude,
      longitude: longitude,
      address: address,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lokasi',
            style: AppTypography.h5,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Placeholder for future map integration
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSizing.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: AppSizing.iconXl,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Peta akan tersedia segera',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Latitude and Longitude in a row
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _latController,
                  label: 'Latitude',
                  hint: '-6.2088',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  enabled: !widget.isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Wajib diisi';
                    }
                    final lat = double.tryParse(value.trim());
                    if (lat == null) {
                      return 'Format tidak valid';
                    }
                    if (lat < -90 || lat > 90) {
                      return 'Rentang: -90 s/d 90';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _lngController,
                  label: 'Longitude',
                  hint: '106.8456',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  enabled: !widget.isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Wajib diisi';
                    }
                    final lng = double.tryParse(value.trim());
                    if (lng == null) {
                      return 'Format tidak valid';
                    }
                    if (lng < -180 || lng > 180) {
                      return 'Rentang: -180 s/d 180';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _addressController,
            label: 'Alamat',
            hint: 'Masukkan alamat lengkap',
            maxLines: 2,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.location_on_outlined),
            enabled: !widget.isLoading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Alamat tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Perbarui Lokasi',
            onPressed: widget.isLoading ? null : _onSubmit,
            isLoading: widget.isLoading,
            icon: Icons.my_location,
          ),
        ],
      ),
    );
  }
}
