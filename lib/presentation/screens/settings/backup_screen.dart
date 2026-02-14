import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/backup_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/backup/backup_progress_dialog.dart';

/// Screen for managing Google Drive backups
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  void initState() {
    super.initState();
    // Try to connect on screen open if not connected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BackupProvider>();
      if (!provider.isConnected && provider.status == BackupStatus.idle) {
        _checkConnection();
      }
    });
  }

  Future<void> _checkConnection() async {
    final provider = context.read<BackupProvider>();
    if (!provider.isConnected) {
      // Don't auto-connect, just show disconnected state
      return;
    }
    await provider.checkConnection();
  }

  Future<void> _connect() async {
    final provider = context.read<BackupProvider>();
    await provider.connect();
  }

  Future<void> _disconnect() async {
    final provider = context.read<BackupProvider>();
    await provider.disconnect();
  }

  Future<void> _createBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<BackupProvider>();

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<BackupProvider>(
        builder: (context, provider, _) => BackupProgressDialog(
          title: l10n.creatingBackup,
          message: provider.statusMessage,
          progress: provider.progress,
        ),
      ),
    );

    final result = await provider.createBackup();

    if (!mounted) return;
    Navigator.of(context).pop(); // Close progress dialog

    if (result != null) {
      BackupResultDialog.show(
        context,
        success: true,
        title: l10n.backupComplete,
        message: l10n.backupSuccessMessage(result.deckCount, result.cardCount),
        onDismiss: () {
          // Refresh deck list
          context.read<DeckProvider>().loadDecks();
        },
      );
    } else if (provider.error != null) {
      BackupResultDialog.show(
        context,
        success: false,
        title: l10n.backupFailed,
        message: provider.error!,
      );
      provider.clearError();
    }
  }

  Future<void> _restoreBackup(String backupId, String date, int deckCount, int cardCount) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<BackupProvider>();

    // Show confirmation dialog
    final mode = await RestoreConfirmDialog.show(
      context,
      backupDate: date,
      deckCount: deckCount,
      cardCount: cardCount,
    );

    if (mode == null || !mounted) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<BackupProvider>(
        builder: (context, provider, _) => BackupProgressDialog(
          title: l10n.restoringBackup,
          message: provider.statusMessage,
          progress: provider.progress,
        ),
      ),
    );

    final result = await provider.restoreBackup(
      backupId,
      replaceExisting: mode == RestoreMode.replace,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // Close progress dialog

    if (result != null && result.success) {
      BackupResultDialog.show(
        context,
        success: true,
        title: l10n.restoreComplete,
        message: l10n.restoreSuccessMessage(result.decksRestored, result.cardsRestored),
        details: result.decksSkipped > 0
            ? l10n.decksSkipped(result.decksSkipped)
            : null,
        onDismiss: () {
          // Refresh deck list
          context.read<DeckProvider>().loadDecks();
        },
      );
    } else if (provider.error != null) {
      BackupResultDialog.show(
        context,
        success: false,
        title: l10n.restoreFailed,
        message: provider.error!,
      );
      provider.clearError();
    }
  }

  Future<void> _deleteBackup(String backupId, String date) async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteBackup),
        content: Text(l10n.deleteBackupConfirm(date)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<BackupProvider>();
    final success = await provider.deleteBackup(backupId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupDeleted)),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppColors.error,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.googleDriveBackup),
      ),
      body: Consumer<BackupProvider>(
        builder: (context, provider, _) {
          if (provider.status == BackupStatus.connecting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!provider.isConnected) {
            return _buildDisconnectedView(context, provider, l10n);
          }

          return _buildConnectedView(context, provider, l10n);
        },
      ),
    );
  }

  Widget _buildDisconnectedView(BuildContext context, BackupProvider provider, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.notConnectedToGoogleDrive,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.connectToBackupData,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (provider.error != null) ...[
              const SizedBox(height: 16),
              Text(
                provider.error!,
                style: TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: provider.isBusy ? null : _connect,
              icon: const Icon(Icons.login),
              label: Text(l10n.connectGoogleDrive),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedView(BuildContext context, BackupProvider provider, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: () => provider.loadBackups(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.connectedAs,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          provider.userEmail ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _disconnect,
                    child: Text(l10n.disconnect),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Create backup button
          FilledButton.icon(
            onPressed: provider.isBusy ? null : _createBackup,
            icon: const Icon(Icons.backup),
            label: Text(l10n.createBackup),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),

          const SizedBox(height: 24),

          // Backups list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.availableBackups,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (provider.status == BackupStatus.listing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Backups list
          if (provider.backups.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_queue,
                      size: 48,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noBackupsYet,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.createFirstBackup,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...provider.backups.map((backup) => _buildBackupCard(context, backup, l10n)),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBackupCard(BuildContext context, backup, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(Icons.backup, color: AppColors.primary),
        ),
        title: Text(backup.formattedDate),
        subtitle: Text(
          l10n.backupSummary(backup.deckCount, backup.cardCount, backup.formattedSize),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'restore':
                _restoreBackup(
                  backup.id,
                  backup.formattedDate,
                  backup.deckCount,
                  backup.cardCount,
                );
                break;
              case 'delete':
                _deleteBackup(backup.id, backup.formattedDate);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  const Icon(Icons.restore),
                  const SizedBox(width: 8),
                  Text(l10n.restore),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(l10n.delete, style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
