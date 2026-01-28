import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/category.dart';
import '../../providers/public_library_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/library/rating_widget.dart';
import '../../widgets/library/tag_input.dart';

/// Screen showing public deck details with preview and import option
class PublicDeckDetailScreen extends StatefulWidget {
  final String deckId;

  const PublicDeckDetailScreen({
    super.key,
    required this.deckId,
  });

  @override
  State<PublicDeckDetailScreen> createState() => _PublicDeckDetailScreenState();
}

class _PublicDeckDetailScreenState extends State<PublicDeckDetailScreen> {
  bool _isImported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PublicLibraryProvider>();
      provider.selectDeck(widget.deckId);
      _checkImportStatus();
    });
  }

  Future<void> _checkImportStatus() async {
    final provider = context.read<PublicLibraryProvider>();
    final imported = await provider.isImported(widget.deckId);
    if (mounted) {
      setState(() => _isImported = imported);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PublicLibraryProvider>(
      builder: (context, provider, _) {
        final deck = provider.selectedDeck;

        return Scaffold(
          appBar: AppBar(
            title: Text(deck?.name ?? 'Deck Details'),
            actions: [
              if (deck != null)
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareDeck(context),
                ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : deck == null
                  ? _buildErrorState(context, provider.error)
                  : _buildContent(context, provider),
          bottomNavigationBar: deck != null ? _buildBottomBar(context, provider) : null,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, PublicLibraryProvider provider) {
    final deck = provider.selectedDeck!;
    final category = Category.getById(deck.categoryId);

    return RefreshIndicator(
      onRefresh: () => provider.selectDeck(widget.deckId),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and author
                    Text(
                      deck.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            deck.authorName.isNotEmpty
                                ? deck.authorName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          deck.authorName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),

                    if (deck.description != null &&
                        deck.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        deck.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.style,
                          label: '${deck.cardCount} cards',
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          icon: Icons.download,
                          label: '${deck.downloadCount} downloads',
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Category and languages
                    Row(
                      children: [
                        if (category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${deck.sourceLanguage.toUpperCase()} → ${deck.targetLanguage.toUpperCase()}',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Tags
                    if (deck.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TagList(tags: deck.tags),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Rating section
            Text(
              'Ratings & Reviews',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildRatingSection(context, provider),

            const SizedBox(height: 24),

            // Preview section
            Text(
              'Preview Cards',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildPreviewSection(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(
      BuildContext context, PublicLibraryProvider provider) {
    final deck = provider.selectedDeck!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary
            Row(
              children: [
                Text(
                  deck.averageRating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingWidget(rating: deck.averageRating, size: 18),
                    Text(
                      '${deck.ratingCount} reviews',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => _showRatingDialog(context, provider),
                  child: Text(
                    provider.userRating != null ? 'Edit Review' : 'Rate',
                  ),
                ),
              ],
            ),

            // User's rating
            if (provider.userRating != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Text('Your rating: '),
                  RatingWidget(
                    rating: provider.userRating!.rating.toDouble(),
                    size: 16,
                  ),
                ],
              ),
              if (provider.userRating!.review != null) ...[
                const SizedBox(height: 8),
                Text(
                  provider.userRating!.review!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],

            // Recent reviews
            if (provider.deckRatings.isNotEmpty) ...[
              const Divider(height: 24),
              ...provider.deckRatings.take(3).map((rating) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            rating.userName ?? 'Anonymous',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          RatingWidget(
                            rating: rating.rating.toDouble(),
                            size: 14,
                          ),
                        ],
                      ),
                      if (rating.review != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          rating.review!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(
      BuildContext context, PublicLibraryProvider provider) {
    final flashcards = provider.previewFlashcards;

    if (flashcards.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No cards to preview',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: flashcards.take(5).map((card) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              card.front,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(card.back),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(BuildContext context, PublicLibraryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isImported
                ? null
                : provider.isImporting
                    ? null
                    : () => _importDeck(context, provider),
            child: provider.isImporting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isImported ? 'Already Imported' : 'Import Deck'),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            error ?? 'Failed to load deck',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<PublicLibraryProvider>().selectDeck(widget.deckId);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _shareDeck(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  void _showRatingDialog(BuildContext context, PublicLibraryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        initialRating: provider.userRating?.rating.toDouble(),
        initialReview: provider.userRating?.review,
        onSubmit: (result) {
          provider.rateDeck(result.rating, review: result.review);
        },
      ),
    );
  }

  Future<void> _importDeck(
      BuildContext context, PublicLibraryProvider provider) async {
    final deck = await provider.importDeck(widget.deckId);

    if (deck != null && mounted) {
      // Refresh local decks
      context.read<DeckProvider>().loadDecks();

      setState(() => _isImported = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported "${deck.name}"'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/deck',
                (route) => route.isFirst,
                arguments: deck.id,
              );
            },
          ),
        ),
      );
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import: ${provider.error}'),
          backgroundColor: AppColors.error,
        ),
      );
      provider.clearError();
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondaryLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }
}
