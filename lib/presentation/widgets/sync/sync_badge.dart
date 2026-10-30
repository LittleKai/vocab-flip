import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Badge indicating sync status or available updates
class SyncBadge extends StatelessWidget {
  final bool hasUpdate;
  final bool isSyncing;
  final int? versionsBehind;
  final VoidCallback? onTap;

  const SyncBadge({
    super.key,
    this.hasUpdate = false,
    this.isSyncing = false,
    this.versionsBehind,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isSyncing) {
      return _buildSyncingBadge(context);
    }

    if (hasUpdate) {
      return _buildUpdateBadge(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildSyncingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Syncing...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateBadge(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync,
              size: 14,
              color: AppColors.accent,
            ),
            const SizedBox(width: 4),
            Text(
              versionsBehind != null
                  ? 'Update available (v+$versionsBehind)'
                  : 'Update available',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linked deck indicator showing it's imported from library
class LinkedDeckIndicator extends StatelessWidget {
  final String? authorName;
  final bool hasUpdate;
  final VoidCallback? onSyncTap;

  const LinkedDeckIndicator({
    super.key,
    this.authorName,
    this.hasUpdate = false,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.link,
                size: 14,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                authorName != null ? 'by $authorName' : 'Linked',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        if (hasUpdate) ...[
          const SizedBox(width: 8),
          SyncBadge(
            hasUpdate: true,
            onTap: onSyncTap,
          ),
        ],
      ],
    );
  }
}
