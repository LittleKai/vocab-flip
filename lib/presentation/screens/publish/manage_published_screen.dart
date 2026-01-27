import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/publish_provider.dart';
import '../../widgets/library/public_deck_card.dart';
import '../../widgets/library/rating_widget.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Published Decks'),
      ),
      body: Consumer<PublishProvider>(
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
                                    deck.isActive ? 'Active' : 'Inactive',
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
                                  '${deck.downloadCount} downloads',
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            'No Published Decks',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Share your decks with the community',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }

  void _showDeckOptions(BuildContext context, String publicDeckId) {
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
                title: const Text('Push Update'),
                subtitle: const Text('Sync changes from local deck'),
                onTap: () {
                  Navigator.pop(context);
                  _pushUpdate(context, publicDeckId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text('Unpublish'),
                subtitle: const Text('Remove from public library'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmUnpublish(context, publicDeckId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('View Analytics'),
                subtitle: const Text('See download and rating stats'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Analytics coming soon')),
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
    // TODO: Implement push update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updating published deck...')),
    );
  }

  void _confirmUnpublish(BuildContext context, String publicDeckId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpublish Deck?'),
        content: const Text(
          'This will remove the deck from the public library. '
          'Users who already imported it will still have their copies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement unpublish with local deck ID
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deck unpublished')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Unpublish'),
          ),
        ],
      ),
    );
  }
}
