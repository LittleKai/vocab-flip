import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/deck_navigation.dart';
import '../../../data/models/category.dart';
import '../../../data/models/deck.dart';
import '../../../data/models/deck_rating.dart';
import '../../../data/models/public_deck.dart';
import '../../providers/auth_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/public_library_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/library/rating_widget.dart';
import '../flashcard/flashcard_viewer_screen.dart';

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
    final isAndroid = kIsWeb ? false : Platform.isAndroid;

    return RefreshIndicator(
      onRefresh: () => provider.selectDeck(widget.deckId),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card — same structure as PublicDeckCard but larger
            Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Row 1: Image + Info + Deck ID badge ===
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Deck image + Deck ID below on Android
                        if (isAndroid)
                          Column(
                            children: [
                              _buildDeckImage(deck),
                              const SizedBox(height: 6),
                              _buildDeckIdBadge(context, deck),
                            ],
                          )
                        else
                          _buildDeckImage(deck),
                        const SizedBox(width: 12),

                        // Info column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + front/back fields + language badges
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    deck.name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (!deck.showBackFirst) ...[
                                    _buildMiniChip(
                                      context,
                                      Icons.flip_to_front,
                                      _formatFields(deck.frontFields ?? 'word'),
                                      AppColors.primary,
                                    ),
                                    _buildMiniChip(
                                      context,
                                      Icons.flip_to_back,
                                      _formatFields(deck.backFields ?? 'meaning'),
                                      AppColors.secondary,
                                    ),
                                  ] else ...[
                                    _buildMiniChip(
                                      context,
                                      Icons.flip_to_back,
                                      _formatFields(deck.backFields ?? 'meaning'),
                                      AppColors.secondary,
                                    ),
                                    _buildMiniChip(
                                      context,
                                      Icons.flip_to_front,
                                      _formatFields(deck.frontFields ?? 'word'),
                                      AppColors.primary,
                                    ),
                                  ],
                                  // Language badges
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getLanguageColor(deck.sourceLanguage).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          deck.sourceLanguage.toUpperCase(),
                                          style: TextStyle(
                                            color: _getLanguageColor(deck.sourceLanguage),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getLanguageColor(deck.targetLanguage).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          deck.targetLanguage.toUpperCase(),
                                          style: TextStyle(
                                            color: _getLanguageColor(deck.targetLanguage),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Author + date (inside header on Windows)
                              if (!isAndroid) ...[
                                const SizedBox(height: 6),
                                _buildAuthorDateRow(context, deck),
                              ],

                              // Description (inside header on Windows)
                              if (!isAndroid && deck.description != null && deck.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  deck.description!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary(context),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Deck ID badge (top right on Windows)
                        if (!isAndroid) ...[
                          const SizedBox(width: 8),
                          _buildDeckIdBadge(context, deck),
                        ],
                      ],
                    ),

                    // Author + date (outside header on Android)
                    if (isAndroid) ...[
                      const SizedBox(height: 6),
                      _buildAuthorDateRow(context, deck),
                    ],

                    // Description (outside header on Android)
                    if (isAndroid && deck.description != null && deck.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        deck.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                      ),
                    ],

                    // === Tags ===
                    if (deck.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: deck.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$tag',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary(context),
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // === Category + Card count + Download count (last row) ===
                    Row(
                      children: [
                        // Category chip
                        if (category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(category.icon),
                                  size: 13,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category.name,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],

                        const Spacer(),

                        // Card count
                        Icon(Icons.style_outlined, size: 14, color: AppColors.info),
                        const SizedBox(width: 3),
                        Text(
                          '${deck.cardCount}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.info,
                                fontSize: 12,
                              ),
                        ),

                        const SizedBox(width: 10),

                        // Download count
                        Icon(Icons.download_outlined, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 3),
                        Text(
                          _formatCount(deck.downloadCount),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.secondary,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
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

            // Flashcards section
            Row(
              children: [
                Text(
                  l10n.flashcards,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${provider.previewFlashcards.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFlashcardsSection(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckImage(PublicDeck deck) {
    final hasImage = deck.imageUrl != null && deck.imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 80,
        height: 80,
        child: hasImage
            ? _buildImageWidget(deck.imageUrl!)
            : Container(
                color: AppColors.primary.withOpacity(0.1),
                child: Icon(Icons.style, color: AppColors.primary, size: 36),
              ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.primary.withOpacity(0.1),
          child: Icon(Icons.style, color: AppColors.primary, size: 36),
        ),
      );
    }
    final file = !kIsWeb ? File(imageUrl) : null;
    if (file != null && file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Icon(Icons.style, color: AppColors.primary, size: 36),
    );
  }

  Widget _buildDeckIdBadge(BuildContext context, PublicDeck deck) {
    return GestureDetector(
      onTap: () {
        final displayId = deck.shortId ?? deck.id;
        Clipboard.setData(ClipboardData(text: displayId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deckIdCopied),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(6),
          color: AppColors.primary.withOpacity(0.05),
        ),
        child: Text(
          deck.shortId ?? deck.id,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
        ),
      ),
    );
  }

  Widget _buildAuthorDateRow(BuildContext context, PublicDeck deck) {
    final authorName = context.read<PublicLibraryProvider>()
        .getCachedAuthorProfile(deck.authorId)?.nickname ?? deck.authorName;

    return Row(
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'by ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                ),
                TextSpan(
                  text: authorName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary(context)),
        const SizedBox(width: 3),
        Text(
          DateFormat('dd/MM/yyyy').format(deck.publishedAt ?? deck.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary(context),
                fontSize: 12,
              ),
        ),
      ],
    );
  }

  Widget _buildMiniChip(BuildContext context, IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: color,
              ),
        ),
      ],
    );
  }

  Color _getLanguageColor(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'en': return AppColors.englishBadge;
      case 'ja': return AppColors.japaneseBadge;
      case 'zh': return AppColors.chineseBadge;
      case 'vi': return AppColors.vietnameseBadge;
      default: return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'school': return Icons.school;
      case 'translate': return Icons.translate;
      case 'flight': return Icons.flight;
      case 'business': return Icons.business;
      case 'home': return Icons.home;
      case 'menu_book': return Icons.menu_book;
      case 'chat_bubble': return Icons.chat_bubble;
      case 'more_horiz': return Icons.more_horiz;
      default: return Icons.category;
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
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
            // Summary row
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
              ],
            ),

            // User's rating
            if (provider.userRating != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Text('${l10n.yourRating} '),
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

            const SizedBox(height: 16),

            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final isSignedIn = auth.isAuthenticated;
                      return OutlinedButton.icon(
                        onPressed: isSignedIn
                            ? () => _showRatingDialog(context, provider)
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.signInToRate)),
                                );
                              },
                        icon: Icon(
                          provider.userRating != null ? Icons.edit : Icons.star_border,
                          size: 18,
                        ),
                        label: Text(
                          provider.userRating != null ? l10n.editReview : l10n.rate,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReviewsDialog(context, provider),
                    icon: const Icon(Icons.reviews_outlined, size: 18),
                    label: Text(l10n.viewReviews),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardsSection(
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
      children: flashcards.map((card) {
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
            // Browse button (always visible)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _browseDeck(context, provider),
                icon: const Icon(Icons.visibility),
                label: Text(l10n.browse),
              ),
            ),
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

  void _browseDeck(BuildContext context, PublicLibraryProvider provider) async {
    final deckProvider = context.read<DeckProvider>();
    final flashcardProvider = context.read<FlashcardProvider>();

    if (_isImported) {
      // Browse local deck
      final localDeck = deckProvider.decks.firstWhere(
        (d) => d.linkedPublicDeckId == widget.deckId,
        orElse: () => deckProvider.decks.first,
      );
      Navigator.popUntil(context, (route) => route.isFirst);
      DeckNavigation.navigateToBrowse(context, localDeck.id);
    } else {
      // Browse online — convert public flashcards to local format
      final publicDeck = provider.selectedDeck!;
      final cards = provider.previewFlashcards.map((pf) => pf.toFlashcard()).toList();
      if (cards.isEmpty) return;

      // Parse front/back fields from PublicDeck
      List<CardFieldType>? parsedFrontFields;
      List<CardFieldType>? parsedBackFields;
      try {
        if (publicDeck.frontFields != null) {
          parsedFrontFields = publicDeck.frontFields!
              .split(',')
              .map((s) => CardFieldType.values.firstWhere((f) => f.name == s))
              .toList();
        }
        if (publicDeck.backFields != null) {
          parsedBackFields = publicDeck.backFields!
              .split(',')
              .map((s) => CardFieldType.values.firstWhere((f) => f.name == s))
              .toList();
        }
      } catch (_) {
        // Use defaults if parsing fails
      }

      final tempDeck = Deck(
        id: publicDeck.id,
        name: publicDeck.name,
        description: publicDeck.description,
        sourceLanguage: publicDeck.sourceLanguage,
        targetLanguage: publicDeck.targetLanguage,
        cardCount: cards.length,
        imagePath: publicDeck.imageUrl,
        frontFields: parsedFrontFields,
        backFields: parsedBackFields,
      );

      flashcardProvider.setFlashcards(cards, deckId: publicDeck.id);
      deckProvider.setTemporaryDeck(tempDeck);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlashcardViewerScreen(deckId: publicDeck.id),
          ),
        );
      }
    }
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
    final nickname = context.read<ProfileProvider>().nickname
        ?? context.read<AuthProvider>().displayName;
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        initialRating: provider.userRating?.rating.toDouble(),
        initialReview: provider.userRating?.review,
        onSubmit: (result) {
          provider.rateDeck(
            result.rating,
            review: result.review,
            nickname: nickname,
          );
        },
      ),
    );
  }

  void _showReviewsDialog(BuildContext context, PublicLibraryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _ReviewsDialog(
        ratings: provider.deckRatings,
      ),
    );
  }

  Future<void> _importDeck(
      BuildContext context, PublicLibraryProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final deckProvider = context.read<DeckProvider>();
    final deck = await provider.importDeck(widget.deckId);

    if (deck != null && mounted) {
      // Refresh local decks
      deckProvider.loadDecks();

      setState(() => _isImported = true);

      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.successfullyImported(deck.name)),
          action: SnackBarAction(
            label: l10n.view,
            onPressed: () {
              navigator.popUntil((route) => route.isFirst);
              DeckNavigation.navigateToBrowse(navigator.context, deck.id);
            },
          ),
        ),
      );
    } else if (provider.error != null && mounted) {
      messenger.showSnackBar(
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

/// Dialog to show all reviews with star-based filtering
class _ReviewsDialog extends StatefulWidget {
  final List<DeckRating> ratings;

  const _ReviewsDialog({required this.ratings});

  @override
  State<_ReviewsDialog> createState() => _ReviewsDialogState();
}

class _ReviewsDialogState extends State<_ReviewsDialog> {
  int? _filterStar; // null = all

  List<DeckRating> get _filteredRatings {
    if (_filterStar == null) return widget.ratings;
    return widget.ratings.where((r) => r.rating == _filterStar).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Text(
                  l10n.ratingsReviews,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.allRatings),
                  selected: _filterStar == null,
                  onSelected: (_) => setState(() => _filterStar = null),
                ),
                const SizedBox(width: 6),
                for (int star = 5; star >= 1; star--) ...[
                  FilterChip(
                    label: Text(l10n.nStarRating(star)),
                    selected: _filterStar == star,
                    onSelected: (_) => setState(() =>
                        _filterStar = _filterStar == star ? null : star),
                  ),
                  if (star > 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Reviews list
          Flexible(
            child: _filteredRatings.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.noReviewsYet,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRatings.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final rating = _filteredRatings[index];
                      return _buildReviewItem(context, rating);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, DeckRating rating) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                rating.userName ?? l10n.anonymous,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            RatingWidget(
              rating: rating.rating.toDouble(),
              size: 14,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('dd/MM/yyyy').format(rating.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
                fontSize: 11,
              ),
        ),
        if (rating.review != null && rating.review!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            rating.review!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
