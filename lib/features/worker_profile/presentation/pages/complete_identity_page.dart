import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/worker_profile.dart';
import '../bloc/worker_profile_bloc.dart';

class CompleteIdentityPage extends StatefulWidget {
  final WorkerProfile? profile;
  
  const CompleteIdentityPage({super.key, this.profile});

  @override
  State<CompleteIdentityPage> createState() => _CompleteIdentityPageState();
}

class _CompleteIdentityPageState extends State<CompleteIdentityPage> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _servicePriceController = TextEditingController();
  String _priceUnit = 'per jam';

  final List<String> _priceUnitOptions = [
    'per jam',
    'per hari',
    'per meter persegi',
    'per titik',
    'per pekerjaan/borongan',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _bioController.text = widget.profile?.bio ?? '';
      
      // Note: we don't prepopulate services for MVP because they are not saved in the mock backend yet,
      // but if there are services, we could get the first one.
      if (widget.profile!.services.isNotEmpty) {
        final service = widget.profile!.services.first;
        _serviceNameController.text = service.name;
        _servicePriceController.text = service.basePrice.toString();
        if (_priceUnitOptions.contains(service.priceUnit)) {
          _priceUnit = service.priceUnit;
        }
      }
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _serviceNameController.dispose();
    _servicePriceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final basePrice = int.tryParse(_servicePriceController.text) ?? 0;
      
      context.read<WorkerProfileBloc>().add(
        CompleteIdentity(
          bio: _bioController.text.trim(),
          serviceName: _serviceNameController.text.trim(),
          serviceBasePrice: basePrice,
          servicePriceUnit: _priceUnit,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Melengkapi Identitas Akun'),
      ),
      body: BlocConsumer<WorkerProfileBloc, WorkerProfileState>(
        listener: (context, state) {
          if (state is WorkerProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is WorkerProfileVerificationSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Identitas berhasil dilengkapi! Anda sekarang dapat menerima pesanan.'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          final isLoading = state is WorkerProfileActionLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppCard(
                        color: AppColors.primaryContainer,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: AppColors.primary),
                                SizedBox(width: AppSpacing.md),
                                Expanded(child: Text('Lengkapi Profil Anda', style: AppTypography.h6)),
                              ],
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Isi biodata dan tambahkan minimal satu layanan utama agar pelanggan dapat mulai memesan jasa Anda.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      const Text('Deskripsi Diri (Bio)', style: AppTypography.h6),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _bioController,
                        hint: 'Ceritakan keahlian dan pengalaman Anda...',
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bio tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      const Text('Layanan Utama', style: AppTypography.h6),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Tambahkan layanan utama yang Anda tawarkan. Anda bisa menambahkan layanan lainnya nanti di halaman Profil.',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      AppTextField(
                        controller: _serviceNameController,
                        label: 'Nama Layanan',
                        hint: 'Contoh: Perbaikan AC Split',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama layanan wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      AppTextField(
                        controller: _servicePriceController,
                        label: 'Harga Dasar (Rp)',
                        hint: '50000',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Harga wajib diisi';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Harus berupa angka';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _priceUnit,
                        decoration: const InputDecoration(
                          labelText: 'Satuan',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        items: _priceUnitOptions.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _priceUnit = val);
                          }
                        },
                      ),

                      const SizedBox(height: AppSpacing.xxl),
                      AppButton(
                        text: 'Simpan Identitas',
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                const ColoredBox(
                  color: Colors.black12,
                  child: Center(child: LoadingIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
