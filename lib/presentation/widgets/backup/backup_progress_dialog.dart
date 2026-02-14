import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Dialog showing backup/restore progress
class BackupProgressDialog extends StatelessWidget {
  final String title;
  final String? message;
  final double progress;
  final bool canCancel;
  final VoidCallback? onCancel;

  const BackupProgressDialog({
    super.key,
    required this.title,
    this.message,
    required this.progress,
    this.canCancel = false,
    this.onCancel,
  });

  /// Show the progress dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    double progress = 0.0,
    bool canCancel = false,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackupProgressDialog(
        title: title,
        message: message,
        progress: progress,
        canCancel: canCancel,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      content: Column(
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
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
      ),
      actions: canCancel
          ? [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
                child: Text(l10n.cancel),
              ),
            ]
          : null,
    );
  }
}

/// Dialog showing backup/restore result
class BackupResultDialog extends StatelessWidget {
  final bool success;
  final String title;
  final String message;
  final String? details;
  final VoidCallback? onDismiss;

  const BackupResultDialog({
    super.key,
    required this.success,
    required this.title,
    required this.message,
    this.details,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required bool success,
    required String title,
    required String message,
    String? details,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => BackupResultDialog(
        success: success,
        title: title,
        message: message,
        details: details,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      content: Column(
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
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (details != null) ...[
            const SizedBox(height: 8),
            Text(
              details!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: Text(l10n.done),
        ),
      ],
    );
  }
}

/// Confirmation dialog for restore options
class RestoreConfirmDialog extends StatefulWidget {
  final String backupDate;
  final int deckCount;
  final int cardCount;

  const RestoreConfirmDialog({
    super.key,
    required this.backupDate,
    required this.deckCount,
    required this.cardCount,
  });

  static Future<RestoreMode?> show(
    BuildContext context, {
    required String backupDate,
    required int deckCount,
    required int cardCount,
  }) {
    return showDialog<RestoreMode>(
      context: context,
      builder: (context) => RestoreConfirmDialog(
        backupDate: backupDate,
        deckCount: deckCount,
        cardCount: cardCount,
      ),
    );
  }

  @override
  State<RestoreConfirmDialog> createState() => _RestoreConfirmDialogState();
}

class _RestoreConfirmDialogState extends State<RestoreConfirmDialog> {
  RestoreMode _selectedMode = RestoreMode.merge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.restoreBackup),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.backupInfo(widget.backupDate, widget.deckCount, widget.cardCount)),
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
            groupValue: _selectedMode,
            onChanged: (value) => setState(() => _selectedMode = value!),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          RadioListTile<RestoreMode>(
            title: Text(l10n.restoreModeReplace),
            subtitle: Text(l10n.restoreModeReplaceDesc),
            value: RestoreMode.replace,
            groupValue: _selectedMode,
            onChanged: (value) => setState(() => _selectedMode = value!),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedMode),
          child: Text(l10n.restore),
        ),
      ],
    );
  }
}

enum RestoreMode {
  merge,
  replace,
}
