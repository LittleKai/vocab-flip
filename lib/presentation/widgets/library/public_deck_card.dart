import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/public_deck.dart';
import '../../../data/models/category.dart';

/// Card widget for displaying a public deck in the library
class PublicDeckCard extends StatelessWidget {
  final PublicDeck deck;
  final VoidCallback? onTap;
  final bool showCategory;
  final bool compact;

  const PublicDeckCard({
    super.key,
    required this.deck,
    this.onTap,
    this.showCategory = true,
    this.compact = false,
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
    final l10n = AppLocalizations.of(context)!;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Col 1: Deck image
                  _buildDeckImage(context),
                  const SizedBox(width: 10),

                  // Col 2: Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: name, front/back, language
                        Text(
                          deck.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // Front/Back + Language chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Front/Back fields
                            if (deck.frontFields != null)
                              _buildMiniChip(
                                context,
                                Icons.flip_to_front,
                                _formatFields(deck.frontFields!),
                                AppColors.textSecondaryLight,
                              ),
                            if (deck.backFields != null)
                              _buildMiniChip(
                                context,
                                Icons.flip_to_back,
                                _formatFields(deck.backFields!),
                                AppColors.textSecondaryLight,
                              ),
                            // Language
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${deck.sourceLanguage.toUpperCase()} → ${deck.targetLanguage.toUpperCase()}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Row 2: Author + date
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'by ${deck.authorName}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today, size: 11, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 3),
                            Text(
                              _formatDate(deck.publishedAt ?? deck.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),

                        // Row 3: Description
                        if (deck.description != null && deck.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            deck.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Deck ID - top right corner
                  _buildDeckIdBadge(context),
                ],
              ),

              const SizedBox(height: 8),

              // === Row 2: category, tags, rate, card count, download count ===
              Row(
                children: [
                  // Category chip
                  if (showCategory && category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Tags (show first 2)
                  ...deck.tags.take(2).map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$tag',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: AppColors.textSecondaryLight,
                              ),
                        ),
                      ),
                    );
                  }),

                  // Rating
                  if (deck.hasRatings) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${deck.averageRating.toStringAsFixed(1)}(${deck.ratingCount})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ],

                  const Spacer(),

                  // Card count
                  Icon(Icons.style_outlined, size: 13, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 2),
                  Text(
                    '${deck.cardCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: 11,
                        ),
                  ),

                  const SizedBox(width: 8),

                  // Download count
                  Icon(Icons.download_outlined, size: 13, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 2),
                  Text(
                    _formatCount(deck.downloadCount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
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

  /// Deck ID badge at top-right corner, bold, framed, large font, tappable to copy
  Widget _buildDeckIdBadge(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: deck.id));
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
          deck.id,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(BuildContext context, IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildDeckImage(BuildContext context) {
    final hasImage = deck.imageUrl != null && deck.imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: hasImage
            ? _buildImageWidget(deck.imageUrl!)
            : Container(
                color: AppColors.primary.withOpacity(0.1),
                child: Icon(Icons.style, color: AppColors.primary, size: 28),
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
          child: Icon(Icons.style, color: AppColors.primary, size: 28),
        ),
      );
    }
    final file = File(imageUrl);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Icon(Icons.style, color: AppColors.primary, size: 28),
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
              _buildDeckImage(context),
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
                    Text(
                      '${deck.cardCount} cards • by ${deck.authorName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
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
