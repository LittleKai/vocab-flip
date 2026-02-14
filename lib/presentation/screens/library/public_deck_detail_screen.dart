import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/deck_navigation.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PublicLibraryProvider>(
      builder: (context, provider, _) {
        final deck = provider.selectedDeck;

        return Scaffold(
          appBar: AppBar(
            title: Text(deck?.name ?? l10n.deckDetails),
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
    final l10n = AppLocalizations.of(context)!;
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
                    // Deck image + title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Deck image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: (deck.imageUrl != null && deck.imageUrl!.isNotEmpty)
                                ? (deck.imageUrl!.startsWith('http')
                                    ? Image.network(
                                        deck.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppColors.primary.withOpacity(0.1),
                                          child: Icon(Icons.style, color: AppColors.primary, size: 36),
                                        ),
                                      )
                                    : (File(deck.imageUrl!).existsSync()
                                        ? Image.file(File(deck.imageUrl!), fit: BoxFit.cover)
                                        : Container(
                                            color: AppColors.primary.withOpacity(0.1),
                                            child: Icon(Icons.style, color: AppColors.primary, size: 36),
                                          )))
                                : Container(
                                    color: AppColors.primary.withOpacity(0.1),
                                    child: Icon(Icons.style, color: AppColors.primary, size: 36),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deck.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: Text(
                                      deck.authorName.isNotEmpty
                                          ? deck.authorName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    deck.authorName,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Rating stars
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        RatingWidget(
                          rating: deck.averageRating,
                          ratingCount: deck.ratingCount,
                          size: 18,
                        ),
                        if (deck.hasRatings) ...[
                          const SizedBox(width: 8),
                          Text(
                            deck.averageRating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ],
                    ),

                    if (deck.description != null &&
                        deck.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        deck.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Upload date
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(deck.publishedAt ?? deck.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Stats row
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.style,
                          label: l10n.cardsCount(deck.cardCount),
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          icon: Icons.download,
                          label: l10n.downloadsCount(deck.downloadCount),
                        ),
                      ],
                    ),

                    // Front/Back fields
                    if (deck.frontFields != null || deck.backFields != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (deck.frontFields != null) ...[
                            Icon(Icons.flip_to_front, size: 14, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 4),
                            Text(
                              _formatFields(deck.frontFields!),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (deck.backFields != null) ...[
                            Icon(Icons.flip_to_back, size: 14, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 4),
                            Text(
                              _formatFields(deck.backFields!),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Deck ID
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.fingerprint, size: 14, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            deck.id,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondaryLight,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
              l10n.ratingsReviews,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildRatingSection(context, provider),

            const SizedBox(height: 24),

            // Preview section
            Text(
              l10n.previewCards,
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
    final l10n = AppLocalizations.of(context)!;
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
                      l10n.reviewsCount(deck.ratingCount),
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
                    provider.userRating != null ? l10n.editReview : l10n.rate,
                  ),
                ),
              ],
            ),

            // User's rating
            if (provider.userRating != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Text('${l10n.yourRating}: '),
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
                            rating.userName ?? l10n.anonymous,
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
    final l10n = AppLocalizations.of(context)!;
    final flashcards = provider.previewFlashcards;

    if (flashcards.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              l10n.noCardsPreview,
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
    final l10n = AppLocalizations.of(context)!;

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
        child: Row(
          children: [
            // Browse button (only if already imported)
            if (_isImported)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _browseDeck(context),
                  icon: const Icon(Icons.visibility),
                  label: Text(l10n.browse),
                ),
              ),
            if (_isImported)
              const SizedBox(width: 12),
            // Import button
            Expanded(
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
                    : Text(_isImported ? l10n.alreadyImported : l10n.importDeck),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _browseDeck(BuildContext context) async {
    // Find local deck linked to this public deck
    final deckProvider = context.read<DeckProvider>();
    final localDeck = deckProvider.decks.firstWhere(
      (d) => d.linkedPublicDeckId == widget.deckId,
      orElse: () => deckProvider.decks.first,
    );
    Navigator.popUntil(context, (route) => route.isFirst);
    DeckNavigation.navigateToBrowse(context, localDeck.id);
  }

  Widget _buildErrorState(BuildContext context, String? error) {
    final l10n = AppLocalizations.of(context)!;

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
            error ?? l10n.failedToLoad,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<PublicLibraryProvider>().selectDeck(widget.deckId);
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  void _shareDeck(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: widget.deckId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.deckIdCopied)),
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
    final l10n = AppLocalizations.of(context)!;
    final deck = await provider.importDeck(widget.deckId);

    if (deck != null && mounted) {
      // Refresh local decks
      context.read<DeckProvider>().loadDecks();

      setState(() => _isImported = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.successfullyImported(deck.name)),
          action: SnackBarAction(
            label: l10n.view,
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              DeckNavigation.navigateToBrowse(context, deck.id);
            },
          ),
        ),
      );
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToImport(provider.error!)),
          backgroundColor: AppColors.error,
        ),
      );
      provider.clearError();
    }
  }

  String _formatFields(String fields) {
    return fields.split(',').map((f) {
      switch (f.trim()) {
        case 'word': return 'Word';
        case 'phonetic': return 'Phonetic';
        case 'meaning': return 'Meaning';
        case 'example': return 'Example';
        case 'notes': return 'Notes';
        default: return f.trim();
      }
    }).join(', ');
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
