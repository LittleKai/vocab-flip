import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/deck.dart';
import '../../providers/deck_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'create_deck_screen.dart';
import 'deck_detail_screen.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Decks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Consumer<DeckProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingWidget(message: 'Loading decks...');
          }

          if (provider.decks.isEmpty) {
            return EmptyStateWidget(
              title: 'No decks yet',
              subtitle: 'Create your first deck to start learning!',
              icon: Icons.folder_open,
              action: ElevatedButton.icon(
                onPressed: () => _navigateToCreateDeck(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Deck'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadDecks(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.decks.length,
              itemBuilder: (context, index) {
                return _DeckCard(deck: provider.decks[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateDeck(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateDeck(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateDeckScreen()),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final Deck deck;

  const _DeckCard({required this.deck});

  @override
  Widget build(BuildContext context) {
    final langColor = _getLanguageColor(deck.sourceLanguage);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDeckDetail(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: langColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deck.sourceLanguage.toUpperCase(),
                      style: TextStyle(
                        color: langColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.vietnameseBadge.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'VI',
                      style: TextStyle(
                        color: AppColors.vietnameseBadge,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'export', child: Text('Export')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deck.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  // Show linked/published indicators
                  if (deck.isLinked)
                    Consumer<SyncProvider>(
                      builder: (context, syncProvider, _) {
                        final hasUpdate = syncProvider.hasUpdateForDeck(deck.id);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link, size: 16, color: AppColors.secondary),
                            if (hasUpdate) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  if (deck.isPublished)
                    Icon(Icons.public, size: 16, color: AppColors.success),
                ],
              ),
              if (deck.description != null && deck.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  deck.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.style,
                    label: '${deck.cardCount} cards',
                  ),
                  const SizedBox(width: 12),
                  if (deck.newCount > 0)
                    _StatChip(
                      icon: Icons.fiber_new,
                      label: '${deck.newCount} new',
                      color: AppColors.info,
                    ),
                  if (deck.reviewCount > 0) ...[
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.replay,
                      label: '${deck.reviewCount} review',
                      color: AppColors.warning,
                    ),
                  ],
                  const Spacer(),
                  if (deck.dueCount > 0)
                    ElevatedButton(
                      onPressed: () => _navigateToStudy(context),
                      child: const Text('Study'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLanguageColor(String langCode) {
    switch (langCode) {
      case 'en':
        return AppColors.englishBadge;
      case 'ja':
        return AppColors.japaneseBadge;
      case 'zh':
        return AppColors.chineseBadge;
      default:
        return AppColors.primary;
    }
  }

  void _navigateToDeckDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeckDetailScreen(deckId: deck.id),
      ),
    );
  }

  void _navigateToStudy(BuildContext context) {
    Navigator.pushNamed(context, '/study', arguments: deck.id);
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateDeckScreen(deck: deck),
          ),
        );
        break;
      case 'export':
        // TODO: Implement export
        break;
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: Text('Are you sure you want to delete "${deck.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DeckProvider>().deleteDeck(deck.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondaryLight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}
