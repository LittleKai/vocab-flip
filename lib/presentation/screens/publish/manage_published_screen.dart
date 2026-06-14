import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/deck_provider.dart';
import '../../providers/publish_provider.dart';
import '../../widgets/library/rating_widget.dart';
import '../../widgets/dialogs/standard_dialog.dart';

/// Screen for managing user's published decks
class ManagePublishedScreen extends StatefulWidget {
  const ManagePublishedScreen({super.key});

  @override
  State<ManagePublishedScreen> createState() => _ManagePublishedScreenState();
}

class _ManagePublishedScreenState extends State<ManagePublishedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublishProvider>().loadMyPublishedDecks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myPublishedDecks),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<PublishProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.myPublishedDecks.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadMyPublishedDecks(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.myPublishedDecks.length,
              itemBuilder: (context, index) {
                final deck = provider.myPublishedDecks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _showDeckOptions(context, deck.id),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    deck.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: deck.isActive
                                        ? AppColors.success.withOpacity(0.1)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    deck.isActive ? l10n.active : l10n.inactive,
                                    style: TextStyle(
                                      color: deck.isActive
                                          ? AppColors.success
                                          : AppColors.textSecondaryLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Description
                            if (deck.description != null &&
                                deck.description!.isNotEmpty)
                              Text(
                                deck.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                            const SizedBox(height: 12),

                            // Stats row
                            Row(
                              children: [
                                // Rating
                                if (deck.hasRatings) ...[
                                  RatingWidget(
                                    rating: deck.averageRating,
                                    ratingCount: deck.ratingCount,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 16),
                                ],

                                // Downloads
                                Icon(
                                  Icons.download,
                                  size: 16,
                                  color: AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.downloadsCount(deck.downloadCount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                ),

                                const Spacer(),

                                // Version
                                Text(
                                  'v${deck.version}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 64,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noPublishedDecks,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.shareWithCommunity,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }

  void _showDeckOptions(BuildContext context, String publicDeckId) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: Text(l10n.pushUpdate),
                subtitle: Text(l10n.syncChanges),
                onTap: () {
                  Navigator.pop(context);
                  _pushUpdate(context, publicDeckId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: Text(l10n.unpublish),
                subtitle: Text(l10n.removeFromLibrary),
                onTap: () {
                  Navigator.pop(context);
                  _confirmUnpublish(context, publicDeckId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: Text(l10n.viewAnalytics),
                subtitle: Text(l10n.analyticsComingSoon),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.analyticsComingSoon)),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _pushUpdate(BuildContext context, String publicDeckId) {
    final l10n = AppLocalizations.of(context)!;
    // TODO: Implement push update
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.updatingDeck)),
    );
  }

  void _confirmUnpublish(BuildContext context, String publicDeckId) {
    final l10n = AppLocalizations.of(context)!;
    final publishProvider = context.read<PublishProvider>();
    final messenger = ScaffoldMessenger.of(context);

    showStandardDialog(
      context: context,
      title: l10n.unpublishConfirm,
      content: l10n.unpublishDescription,
      isDestructive: true,
      secondaryButtonText: l10n.cancel,
      primaryButtonText: l10n.unpublish,
      onPrimaryPressed: () async {
        final localDeckExists = context.read<DeckProvider>().decks.any(
          (d) => d.publishedDeckId == publicDeckId || d.linkedPublicDeckId == publicDeckId,
        );

        if (!localDeckExists) {
          // Show second confirmation dialog warning the user they will lose the deck permanently
          showStandardDialog(
            context: context,
            title: l10n.localCopyMissing,
            content: l10n.unpublishLocalMissingWarning,
            isDestructive: true,
            secondaryButtonText: l10n.cancel,
            primaryButtonText: l10n.unpublish,
            onPrimaryPressed: () async {
              final success = await publishProvider.unpublishByPublicId(publicDeckId);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success
                      ? l10n.deckUnpublished
                      : publishProvider.error ?? 'Failed to unpublish'),
                ),
              );
            },
          );
        } else {
          // Local copy exists, proceed normally
          final success = await publishProvider.unpublishByPublicId(publicDeckId);
          messenger.showSnackBar(
            SnackBar(
              content: Text(success
                  ? l10n.deckUnpublished
                  : publishProvider.error ?? 'Failed to unpublish'),
            ),
          );
        }
      },
    );
  }
}
