import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/worker_profile.dart';
import '../bloc/worker_profile_bloc.dart';

class ServiceManagementPage extends StatefulWidget {
  const ServiceManagementPage({
    super.key,
    required this.services,
  });

  final List<WorkerService> services;

  @override
  State<ServiceManagementPage> createState() => _ServiceManagementPageState();
}

class _ServiceManagementPageState extends State<ServiceManagementPage> {
  void _showAddServiceDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String unit = 'jam';
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Layanan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: nameController,
                    label: 'Nama Layanan',
                    hint: 'Contoh: Perbaikan Atap Bocor',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: priceController,
                    label: 'Harga Dasar (Rp)',
                    hint: '50000',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: unit,
                    decoration: const InputDecoration(
                      labelText: 'Satuan',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'jam', child: Text('Per Jam')),
                      DropdownMenuItem(value: 'hari', child: Text('Per Hari')),
                      DropdownMenuItem(value: 'm2', child: Text('Per Meter Persegi')),
                      DropdownMenuItem(value: 'borongan', child: Text('Borongan (Pekerjaan)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => unit = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final price = int.tryParse(priceController.text) ?? 0;
                    if (name.isNotEmpty && price > 0) {
                      Navigator.of(dialogContext).pop();
                      this.context.read<WorkerProfileBloc>().add(
                        AddWorkerService(name: name, basePrice: price, priceUnit: unit),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String serviceId, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Layanan'),
          content: Text('Apakah Anda yakin ingin menghapus layanan "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<WorkerProfileBloc>().add(RemoveWorkerService(serviceId));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Layanan'),
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
          }
        },
        builder: (context, state) {
          final isLoading = state is WorkerProfileActionLoading;
          
          List<WorkerService> currentServices = widget.services;
          if (state is WorkerProfileLoaded) {
            currentServices = state.profile.services;
          }

          return Stack(
            children: [
              currentServices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.design_services, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: AppSpacing.md),
                          const Text('Belum ada layanan.'),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            text: 'Tambah Layanan',
                            onPressed: _showAddServiceDialog,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: AppSpacing.pagePadding,
                      itemCount: currentServices.length,
                      itemBuilder: (context, index) {
                        final service = currentServices[index];
                        return AppCard(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(service.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text('Rp${service.basePrice}/${service.priceUnit}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _confirmDelete(service.id, service.name),
                            ),
                          ),
                        );
                      },
                    ),
              
              if (isLoading)
                Container(
                  color: Colors.black12,
                  child: const Center(child: LoadingIndicator()),
                ),
            ],
          );
        },
      ),
      floatingActionButton: widget.services.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddServiceDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
