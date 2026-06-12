import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../dialogs/standard_dialog.dart';

/// Dialog showing backup/restore progress
class BackupProgressContent extends StatelessWidget {
  final String? message;
  final double progress;

  const BackupProgressContent({
    super.key,
    this.message,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                strokeWidth: 4,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              ),
              if (progress > 0)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Dialog showing backup/restore result
class BackupResultDialog {
  static Future<void> show(
    BuildContext context, {
    required bool success,
    required String title,
    required String message,
    String? details,
    VoidCallback? onDismiss,
  }) {
    final l10n = AppLocalizations.of(context)!;
    
    return showStandardDialog(
      context: context,
      title: title,
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Icon(
            success ? Icons.check_circle : Icons.error,
            size: 64,
            color: success ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (details != null) ...[
            const SizedBox(height: 8),
            Text(
              details,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      primaryButtonText: l10n.done,
      onPrimaryPressed: onDismiss,
    );
  }
}

/// Confirmation dialog for restore options
class RestoreConfirmDialog {
  static Future<RestoreMode?> show(
    BuildContext context, {
    required String backupDate,
    required int deckCount,
    required int cardCount,
  }) {
    final l10n = AppLocalizations.of(context)!;
    RestoreMode selectedMode = RestoreMode.merge;
    
    return showStandardDialog<RestoreMode>(
      context: context,
      title: l10n.restoreBackup,
      customContent: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.backupInfo(backupDate, deckCount, cardCount)),
            const SizedBox(height: 16),
            Text(
              l10n.selectRestoreMode,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            RadioListTile<RestoreMode>(
              title: Text(l10n.restoreModeMerge),
              subtitle: Text(l10n.restoreModeMergeDesc),
              value: RestoreMode.merge,
              groupValue: selectedMode,
              onChanged: (value) => setState(() => selectedMode = value!),
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppColors.primary,
            ),
            RadioListTile<RestoreMode>(
              title: Text(l10n.restoreModeReplace),
              subtitle: Text(l10n.restoreModeReplaceDesc),
              value: RestoreMode.replace,
              groupValue: selectedMode,
              onChanged: (value) => setState(() => selectedMode = value!),
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
      secondaryButtonText: l10n.cancel,
      primaryButtonText: l10n.restore,
      onPrimaryPressed: () {
        Navigator.of(context).pop(selectedMode);
      },
    );
  }
}

enum RestoreMode {
  merge,
  replace,
}
