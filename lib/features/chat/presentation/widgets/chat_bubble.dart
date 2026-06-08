import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/chat_message.dart';

/// A chat message bubble widget.
///
/// Renders differently based on sender (sent vs received),
/// message type (text, image, system), and delivery status.
///
/// Validates: Requirements 11.1, 11.2, 11.3, 11.9
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message, required this.isMe, super.key,
    this.onRetry,
  });

  /// The chat message to display.
  final ChatMessage message;

  /// Whether this message was sent by the current user.
  final bool isMe;

  /// Callback to retry sending a failed message.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // System messages
    if (message.type == MessageType.system) {
      return _buildSystemMessage();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) const SizedBox(width: AppSpacing.xl),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSizing.radiusMd),
                  topRight: const Radius.circular(AppSizing.radiusMd),
                  bottomLeft: Radius.circular(
                    isMe ? AppSizing.radiusMd : AppSizing.radiusXs,
                  ),
                  bottomRight: Radius.circular(
                    isMe ? AppSizing.radiusXs : AppSizing.radiusMd,
                  ),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Message content
                  if (message.type == MessageType.image)
                    _buildImageContent()
                  else
                    _buildTextContent(),

                  const SizedBox(height: AppSpacing.xs),

                  // Time + delivery status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: AppTypography.overline.copyWith(
                          color: isMe
                              ? AppColors.onPrimary.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildDeliveryIcon(),
                      ],
                    ],
                  ),

                  // Retry button for failed messages
                  if (message.deliveryStatus == MessageDeliveryStatus.failed &&
                      onRetry != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: GestureDetector(
                        onTap: onRetry,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.refresh,
                              size: 12,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Coba lagi',
                              style: AppTypography.overline.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Text(
      message.content,
      style: AppTypography.bodyMedium.copyWith(
        color: isMe ? AppColors.onPrimary : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildImageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.mediaUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
            child: Image.network(
              message.mediaUrl!,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 200,
                height: 100,
                color: AppColors.surfaceVariant,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined),
                    Text('Gagal memuat gambar'),
                  ],
                ),
              ),
              loadingBuilder: (_, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          ),
        if (message.caption != null && message.caption!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            message.caption!,
            style: AppTypography.bodySmall.copyWith(
              color: isMe ? AppColors.onPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          ),
          child: Text(
            message.content,
            style: AppTypography.caption.copyWith(
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryIcon() {
    switch (message.deliveryStatus) {
      case MessageDeliveryStatus.sending:
        return Icon(
          Icons.access_time,
          size: 12,
          color: AppColors.onPrimary.withValues(alpha: 0.5),
        );
      case MessageDeliveryStatus.sent:
        return Icon(
          Icons.check,
          size: 12,
          color: AppColors.onPrimary.withValues(alpha: 0.7),
        );
      case MessageDeliveryStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 12,
          color: AppColors.onPrimary.withValues(alpha: 0.7),
        );
      case MessageDeliveryStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 12,
          color: AppColors.error,
        );
    }
  }
}
