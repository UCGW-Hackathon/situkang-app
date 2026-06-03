import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/entities/user.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import 'edit_profile_page.dart';

/// Page displaying the current user's profile information.
///
/// Shows name, email, phone, avatar, and address.
/// Provides navigation to edit profile, update avatar, and update location.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return switch (state) {
            ProfileInitial() => const LoadingIndicator(
                message: 'Memuat profil...',
              ),
            ProfileLoading() => const LoadingIndicator(
                message: 'Memuat profil...',
              ),
            ProfileLoaded(:final user) => _ProfileContent(user: user),
            ProfileUpdating(:final user) => _ProfileContent(
                user: user,
                isUpdating: true,
              ),
            ProfileError(:final failure, :final user) => user != null
                ? _ProfileContent(
                    user: user,
                    errorMessage: failure.message,
                  )
                : AppErrorWidget(
                    message: failure.message,
                    onRetry: () => context
                        .read<ProfileBloc>()
                        .add(const FetchProfile()),
                  ),
          };
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.user,
    this.isUpdating = false,
    this.errorMessage,
  });

  final User user;
  final bool isUpdating;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProfileBloc>().add(const FetchProfile());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            if (errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                ),
                child: Text(
                  errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (isUpdating) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
            ],
            // Avatar section
            _AvatarSection(avatarUrl: user.avatarUrl),
            const SizedBox(height: AppSpacing.lg),
            // User name
            Text(
              user.fullName,
              style: AppTypography.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              user.email,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            // Profile info cards
            _ProfileInfoCard(
              icon: Icons.person_outline,
              label: 'Nama Lengkap',
              value: user.fullName,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileInfoCard(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileInfoCard(
              icon: Icons.phone_outlined,
              label: 'Telepon',
              value: user.phone,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileInfoCard(
              icon: Icons.location_on_outlined,
              label: 'Alamat',
              value: user.address ?? 'Belum diatur',
            ),
            const SizedBox(height: AppSpacing.xl),
            // Edit profile button
            AppButton(
              text: 'Edit Profil',
              onPressed: () {
                final currentState = context.read<ProfileBloc>().state;
                User? currentUser;
                if (currentState is ProfileLoaded) {
                  currentUser = currentState.user;
                } else if (currentState is ProfileUpdating) {
                  currentUser = currentState.user;
                }
                if (currentUser != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<ProfileBloc>(),
                        child: EditProfilePage(user: currentUser!),
                      ),
                    ),
                  );
                }
              },
              icon: Icons.edit,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleAvatar(
        radius: 56,
        backgroundColor: AppColors.surfaceVariant,
        backgroundImage: avatarUrl != null
            ? CachedNetworkImageProvider(avatarUrl!)
            : null,
        child: avatarUrl == null
            ? const Icon(
                Icons.person,
                size: 56,
                color: AppColors.textSecondary,
              )
            : null,
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: AppSizing.iconMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
