import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/public_deck.dart';
import '../../../data/models/category.dart';
import '../../providers/public_library_provider.dart';
import '../common/deck_card_header.dart';

/// Card widget for displaying a public deck in the library
class PublicDeckCard extends StatelessWidget {
  final PublicDeck deck;
  final VoidCallback? onTap;
  final bool showCategory;
  final bool compact;
  final bool showDeckId;

  const PublicDeckCard({
    super.key,
    required this.deck,
    this.onTap,
    this.showCategory = true,
    this.compact = false,
    this.showDeckId = true,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildFullCard(BuildContext context) {
    final category = Category.getById(deck.categoryId);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Row 1: Image + Info + Deck ID ===
              DeckCardHeader(
                name: deck.name,
                imagePath: deck.imageUrl,
                frontFieldsLabel: _formatFields(deck.frontFields ?? 'word'),
                backFieldsLabel: _formatFields(deck.backFields ?? 'meaning'),
                sourceLanguage: deck.sourceLanguage,
                targetLanguage: deck.targetLanguage,
                reverseFieldOrder: deck.showBackFirst,
                trailing: showDeckId ? _buildDeckIdBadge(context) : null,
              ),

              // Author row
              const SizedBox(height: 6),
              _buildAuthorDate(context),

              // Description row
              if (deck.description != null && deck.description!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  deck.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // === Tags (before category+stats) ===
              if (deck.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: deck.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$tag',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary(context),
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 8),

              // === Category, rate, card count, download count ===
              Row(
                children: [
                  // Category chip with icon
                  if (showCategory && category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(category.icon),
                            size: 12,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            category.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Rating (always show)
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '${deck.averageRating.toStringAsFixed(1)}(${deck.ratingCount})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),

                  const Spacer(),

                  // Card count
                  Icon(Icons.style_outlined, size: 13, color: AppColors.info),
                  const SizedBox(width: 2),
                  Text(
                    '${deck.cardCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                          fontSize: 11,
                        ),
                  ),

                  const SizedBox(width: 8),

                  // Download count
                  Icon(Icons.download_outlined, size: 13, color: AppColors.secondary),
                  const SizedBox(width: 2),
                  Text(
                    _formatCount(deck.downloadCount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Author + date row used as subtitle in header
  Widget _buildAuthorDate(BuildContext context) {
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
        Icon(Icons.calendar_today, size: 11, color: AppColors.textSecondary(context)),
        const SizedBox(width: 3),
        Text(
          _formatDate(deck.publishedAt ?? deck.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary(context),
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  /// Deck ID badge at top-right corner, bold, framed, large font, tappable to copy
  Widget _buildDeckIdBadge(BuildContext context) {
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

  Widget _buildCompactCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DeckCardHeader.buildDeckImage(context, deck.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Builder(builder: (context) {
                      final compactAuthorName = context.read<PublicLibraryProvider>()
                          .getCachedAuthorProfile(deck.authorId)?.nickname ?? deck.authorName;
                      return Text(
                        '${deck.cardCount} cards • by $compactAuthorName',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                      );
                    }),
                  ],
                ),
              ),
              if (deck.hasRatings) ...[
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  deck.averageRating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
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
