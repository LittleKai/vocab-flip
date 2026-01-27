import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/sync_provider.dart';

/// Screen showing sync update notifications
class SyncNotificationsScreen extends StatefulWidget {
  const SyncNotificationsScreen({super.key});

  @override
  State<SyncNotificationsScreen> createState() =>
      _SyncNotificationsScreenState();
}

class _SyncNotificationsScreenState extends State<SyncNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Updates'),
        actions: [
          Consumer<SyncProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () => provider.markAllNotificationsRead(),
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<SyncProvider>(
        builder: (context, provider, _) {
          if (provider.isChecking) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show available updates first
          if (provider.availableUpdates.isNotEmpty) {
            return _buildUpdatesList(context, provider);
          }

          // Then show notification history
          if (provider.notifications.isNotEmpty) {
            return _buildNotificationsList(context, provider);
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildUpdatesList(BuildContext context, SyncProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        await provider.checkForUpdates();
        await provider.loadNotifications();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Available updates section
          Text(
            'Available Updates',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.availableUpdates.length} decks have updates',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 16),

          // Sync all button
          if (provider.availableUpdates.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text('Sync All'),
                onPressed:
                    provider.isSyncing ? null : () => provider.syncAll(),
              ),
            ),

          // Update cards
          ...provider.availableUpdates.map((update) {
            final isSyncing = provider.syncingDeckId == update.link.localDeckId;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  child: Icon(Icons.sync, color: AppColors.accent),
                ),
                title: Text(update.publicDeck.name),
                subtitle: Text(
                  'v${update.link.importedVersion} → v${update.publicDeck.version}',
                ),
                trailing: isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : ElevatedButton(
                        onPressed: () => provider.syncDeck(update.link.localDeckId),
                        child: const Text('Sync'),
                      ),
              ),
            );
          }),

          // Notification history
          if (provider.notifications.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ..._buildNotificationItems(context, provider),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context, SyncProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        await provider.checkForUpdates();
        await provider.loadNotifications();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _buildNotificationItems(context, provider),
      ),
    );
  }

  List<Widget> _buildNotificationItems(
      BuildContext context, SyncProvider provider) {
    return provider.notifications.map((notification) {
      final dateFormat = DateFormat.yMMMd().add_jm();

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: notification.isRead ? null : AppColors.primary.withOpacity(0.05),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: notification.isRead
                ? Colors.grey.shade200
                : AppColors.primary.withOpacity(0.1),
            child: Icon(
              Icons.update,
              color: notification.isRead
                  ? AppColors.textSecondaryLight
                  : AppColors.primary,
            ),
          ),
          title: Text(notification.deckName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Updated to v${notification.newVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                dateFormat.format(notification.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            if (!notification.isRead) {
              provider.markNotificationRead(notification.id);
            }
          },
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'No updates available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Check for Updates'),
            onPressed: () => context.read<SyncProvider>().checkForUpdates(),
          ),
        ],
      ),
    );
  }
}
