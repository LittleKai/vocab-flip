import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/deck_navigation.dart';
import '../../../data/models/deck.dart';
import '../../providers/deck_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'create_deck_screen.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myDecks),
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
            return LoadingWidget(message: l10n.loadingDecks);
          }

          if (provider.decks.isEmpty) {
            return EmptyStateWidget(
              title: l10n.noDecksYet,
              subtitle: l10n.createFirstDeck,
              icon: Icons.folder_open,
              action: ElevatedButton.icon(
                onPressed: () => _navigateToCreateDeck(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.createDeck),
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
        heroTag: 'deck_list_fab',
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
    final l10n = AppLocalizations.of(context)!;
    final langColor = _getLanguageColor(deck.sourceLanguage);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToBrowse(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: Deck name, language, linked icon, menu
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deck.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Language badges
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: langColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      deck.sourceLanguage.toUpperCase(),
                      style: TextStyle(
                        color: langColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.vietnameseBadge.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'VI',
                      style: TextStyle(
                        color: AppColors.vietnameseBadge,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  // Linked/Published indicators
                  if (deck.isLinked)
                    Consumer<SyncProvider>(
                      builder: (context, syncProvider, _) {
                        final hasUpdate = syncProvider.hasUpdateForDeck(deck.id);
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link, size: 16, color: AppColors.secondary),
                              if (hasUpdate) ...[
                                const SizedBox(width: 2),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  if (deck.isPublished)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.public, size: 16, color: AppColors.success),
                    ),
                  // Menu button
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'info', child: Text(l10n.deckDetails)),
                      PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                      PopupMenuItem(value: 'export', child: Text(l10n.export)),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                ],
              ),
              if (deck.description != null && deck.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  deck.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.style,
                    label: l10n.nCards(deck.cardCount),
                  ),
                  const SizedBox(width: 12),
                  if (deck.newCount > 0)
                    _StatChip(
                      icon: Icons.fiber_new,
                      label: l10n.nNew(deck.newCount),
                      color: AppColors.info,
                    ),
                  if (deck.reviewCount > 0) ...[
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.replay,
                      label: l10n.nReview(deck.reviewCount),
                      color: AppColors.warning,
                    ),
                  ],
                  const Spacer(),
                  if (deck.dueCount > 0)
                    ElevatedButton(
                      onPressed: () => _navigateToStudy(context),
                      child: Text(l10n.study),
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

  void _navigateToBrowse(BuildContext context) {
    DeckNavigation.navigateToBrowse(context, deck.id);
  }

  void _navigateToDeckDetail(BuildContext context) {
    DeckNavigation.navigateToDeckDetail(context, deck.id);
  }

  void _navigateToStudy(BuildContext context) {
    DeckNavigation.navigateToStudy(context, deck.id);
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'info':
        _navigateToDeckDetail(context);
        break;
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
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDeck),
        content: Text(l10n.deleteConfirmMessage(deck.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DeckProvider>().deleteDeck(deck.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.delete),
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
