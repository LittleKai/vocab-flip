import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/update_provider.dart';

/// Dialog showing update download and installation progress
class UpdateProgressDialog extends StatefulWidget {
  const UpdateProgressDialog({super.key});

  /// Show the progress dialog and start download
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UpdateProgressDialog(),
    );
  }

  @override
  State<UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  @override
  void initState() {
    super.initState();
    // Start download after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDownload();
    });
  }

  Future<void> _startDownload() async {
    final provider = context.read<UpdateProvider>();
    final success = await provider.downloadUpdate();

    if (success && mounted) {
      // Show install confirmation
      final shouldInstall = await _showInstallConfirmation();
      if (shouldInstall && mounted) {
        await provider.installAndRestart();
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool> _showInstallConfirmation() async {
    final l10n = AppLocalizations.of(context)!;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(l10n.installing),
            content: Text(l10n.restartToApply),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.updateLater),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.restartNow),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<UpdateProvider>(
      builder: (context, provider, child) {
        return PopScope(
          canPop: provider.hasError,
          child: AlertDialog(
            title: Row(
              children: [
                if (provider.isDownloading || provider.isExtracting)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (provider.hasError)
                  const Icon(Icons.error, color: AppColors.error)
                else
                  const Icon(Icons.download, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(_getTitle(provider, l10n)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.isDownloading) ...[
                  // Download progress bar
                  LinearProgressIndicator(
                    value: provider.downloadProgress != null
                        ? provider.downloadProgress!.percentage / 100
                        : null,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12),

                  // Progress details
                  if (provider.downloadProgress != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${provider.downloadProgress!.percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${provider.downloadProgress!.downloadedFormatted} / ${provider.downloadProgress!.totalFormatted}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.downloadProgress!.speedFormatted,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ] else if (provider.isExtracting) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l10n.extractingUpdate),
                ] else if (provider.isInstalling) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l10n.installing),
                ] else if (provider.hasError) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.error ?? l10n.updateFailed,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (provider.hasError) ...[
                TextButton(
                  onPressed: () {
                    provider.resetState();
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    provider.resetState();
                    _startDownload();
                  },
                  child: Text(l10n.tryAgain),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getTitle(UpdateProvider provider, AppLocalizations l10n) {
    if (provider.isDownloading) return l10n.downloadingUpdate;
    if (provider.isExtracting) return l10n.extractingUpdate;
    if (provider.isInstalling) return l10n.installing;
    if (provider.hasError) return l10n.updateFailed;
    return l10n.downloadUpdate;
  }
}
