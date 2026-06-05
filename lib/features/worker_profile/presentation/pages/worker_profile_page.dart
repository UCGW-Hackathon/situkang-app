import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/worker_profile.dart';
import '../bloc/worker_profile_bloc.dart';
import 'service_management_page.dart';
import 'verification_page.dart';

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkerProfileBloc>().add(FetchWorkerProfile());
  }

  Widget _buildVerificationBadge(VerificationStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case VerificationStatus.verified:
        color = AppColors.success;
        text = 'Terverifikasi';
        icon = Icons.verified;
        break;
      case VerificationStatus.pending:
        color = AppColors.warning;
        text = 'Menunggu Verifikasi';
        icon = Icons.hourglass_empty;
        break;
      case VerificationStatus.rejected:
        color = AppColors.error;
        text = 'Verifikasi Ditolak';
        icon = Icons.cancel;
        break;
      case VerificationStatus.unverified:
      default:
        color = AppColors.textSecondary;
        text = 'Belum Terverifikasi';
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(text, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Tukang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur pengaturan sedang dalam pengembangan')));
            },
          ),
        ],
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
          final isLoading = state is WorkerProfileLoading;

          WorkerProfile? profile;
          if (state is WorkerProfileLoaded) {
            profile = state.profile;
          }

          // Fallback to mock worker profile if null
          profile ??= WorkerProfile(
            id: 'mock-worker-id',
            name: 'Asep Tukang Kayu',
            avatarUrl: null,
            coverUrl: null,
            phoneNumber: '085712345678',
            bio: 'Ahli kayu, cat dinding, bocoran rumah, perbaikan atap, dsb. Berpengalaman 10 tahun.',
            verificationStatus: VerificationStatus.verified,
            services: const [
              WorkerService(id: 's1', name: 'Servis AC', basePrice: 150000, priceUnit: 'unit'),
              WorkerService(id: 's2', name: 'Pengecatan Tembok', basePrice: 50000, priceUnit: 'm2'),
            ],
            joinedAt: DateTime(2025, 1, 1),
          );

          return RefreshIndicator(
            onRefresh: () async {
              context.read<WorkerProfileBloc>().add(FetchWorkerProfile());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isLoading) const LinearProgressIndicator(),
                  // Cover & Avatar
                  Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          image: profile.coverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(profile.coverUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: profile.coverUrl == null
                            ? const Icon(Icons.image, size: 48, color: AppColors.textSecondary)
                            : null,
                      ),
                      Positioned(
                        bottom: -40,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.background,
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: AppColors.primaryContainer,
                            backgroundImage: profile.avatarUrl != null
                                ? NetworkImage(profile.avatarUrl!)
                                : null,
                            child: profile.avatarUrl == null
                                ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: AppColors.background),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubah foto sampul sedang dalam pengembangan')));
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 50),
                  
                  // Profile Info
                  Padding(
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(profile.name, style: AppTypography.h5),
                        const SizedBox(height: AppSpacing.xs),
                        _buildVerificationBadge(profile.verificationStatus),
                        const SizedBox(height: AppSpacing.md),
                        
                        if (profile.verificationStatus == VerificationStatus.unverified || 
                            profile.verificationStatus == VerificationStatus.rejected) ...[
                          AppCard(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            child: Column(
                              children: [
                                Text(
                                  profile.verificationStatus == VerificationStatus.rejected
                                      ? 'Verifikasi Ditolak: ${profile.verificationReason ?? 'Data tidak valid'}'
                                      : 'Verifikasi akun Anda agar dapat menerima pesanan.',
                                  style: AppTypography.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppButton(
                                  text: 'Mulai Verifikasi',
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const VerificationPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        
                        Text(
                          profile.bio ?? 'Belum ada bio.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Services Section
                  Padding(
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Layanan Saya', style: AppTypography.h6),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ServiceManagementPage(services: profile!.services),
                                  ),
                                );
                              },
                              child: const Text('Kelola'),
                            ),
                          ],
                        ),
                        if (profile.services.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            alignment: Alignment.center,
                            child: const Text('Belum ada layanan yang ditambahkan.'),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: profile.services.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final service = profile!.services[index];
                              return AppCard(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(service.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                    Text('Rp${service.basePrice}/${service.priceUnit}', style: AppTypography.bodyMedium),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(const LogoutRequested());
                      },
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text('Keluar', style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size(double.infinity, AppSizing.buttonHeightMd),
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                        ),
                        textStyle: AppTypography.buttonMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
