import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/feedback_item.dart';
import '../../providers/admin_feedback_provider.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminFeedbackProvider>();
      provider.loadFeedback();
      provider.markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminFeedback),
      ),
      body: Consumer<AdminFeedbackProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => provider.loadFeedback(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (provider.feedbackList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 64,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noFeedbackYet,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadFeedback();
              await provider.markAllRead();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.feedbackList.length,
              itemBuilder: (context, index) {
                return _FeedbackCard(
                  item: provider.feedbackList[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final FeedbackItem item;

  const _FeedbackCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();

    IconData categoryIcon;
    Color categoryColor;
    switch (item.category) {
      case 'bug':
        categoryIcon = Icons.bug_report;
        categoryColor = AppColors.error;
        break;
      case 'feature':
        categoryIcon = Icons.lightbulb;
        categoryColor = Colors.amber;
        break;
      case 'general':
        categoryIcon = Icons.chat_bubble;
        categoryColor = AppColors.primary;
        break;
      default:
        categoryIcon = Icons.help_outline;
        categoryColor = AppColors.textSecondaryLight;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: categoryColor.withValues(alpha: 0.1),
          child: Icon(categoryIcon, color: categoryColor, size: 20),
        ),
        title: Text(
          item.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.platform} | v${item.appVersion} | ${dateFormat.format(item.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
                fontSize: 11,
              ),
        ),
        isThreeLine: true,
        onTap: () => _showDetails(context),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              item.category.toUpperCase(),
              style: const TextStyle(fontSize: 14),
            ),
            const Spacer(),
            Text(
              item.platform,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.message),
              const SizedBox(height: 16),
              if (item.email != null && item.email!.isNotEmpty) ...[
                Text(
                  'Email: ${item.email}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Version: ${item.appVersion}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(item.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              if (item.userId != null) ...[
                const SizedBox(height: 4),
                Text(
                  'User: ${item.userId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
