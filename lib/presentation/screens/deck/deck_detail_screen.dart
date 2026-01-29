import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/flashcard.dart';
import '../../../data/remote/firebase/firebase_service.dart';
import '../../providers/deck_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/sync/sync_badge.dart';
import '../flashcard/flashcard_editor_screen.dart';
import '../flashcard/flashcard_viewer_screen.dart';
import '../study/study_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  final String deckId;

  const DeckDetailScreen({super.key, required this.deckId});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeckProvider>().selectDeck(widget.deckId);
      context.read<FlashcardProvider>().loadFlashcards(widget.deckId);
      // Check for sync updates if this is a linked deck
      context.read<SyncProvider>().checkForUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<DeckProvider, FlashcardProvider>(
      builder: (context, deckProvider, flashcardProvider, child) {
        final deck = deckProvider.selectedDeck;

        if (deck == null || flashcardProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const LoadingWidget(),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(deck.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Search within deck
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value, deck),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.editDeck)),
                  PopupMenuItem(value: 'export', child: Text(l10n.export)),
                  PopupMenuItem(value: 'import', child: Text(l10n.importCards)),
                  const PopupMenuDivider(),
                  if (deck.isPublished)
                    PopupMenuItem(value: 'manage-published', child: Text(l10n.managePublished))
                  else if (!deck.isLinked && FirebaseService().isSignedIn)
                    PopupMenuItem(value: 'publish', child: Text(l10n.publishToLibrary)),
                  if (deck.isLinked)
                    PopupMenuItem(value: 'unlink', child: Text(l10n.unlinkFromLibrary)),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Deck stats header
              _DeckHeader(deck: deck),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: flashcardProvider.flashcards.isEmpty
                            ? null
                            : () => _navigateToViewer(context),
                        icon: const Icon(Icons.visibility),
                        label: Text(l10n.browse),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: deck.dueCount == 0
                            ? null
                            : () => _navigateToStudy(context),
                        icon: const Icon(Icons.school),
                        label: Text(l10n.studyN(deck.dueCount)),
                      ),
                    ),
                  ],
                ),
              ),

              // Flashcard list
              Expanded(
                child: flashcardProvider.flashcards.isEmpty
                    ? EmptyStateWidget(
                        title: l10n.noFlashcardsYet,
                        subtitle: l10n.addFlashcardsToStart,
                        icon: Icons.style,
                        action: ElevatedButton.icon(
                          onPressed: () => _navigateToAddCard(context),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addFlashcard),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => flashcardProvider.loadFlashcards(widget.deckId),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: flashcardProvider.flashcards.length,
                          itemBuilder: (context, index) {
                            return _FlashcardListItem(
                              flashcard: flashcardProvider.flashcards[index],
                              onTap: () => _navigateToViewCard(
                                context,
                                flashcardProvider.flashcards[index],
                              ),
                              onEdit: () => _navigateToEditCard(
                                context,
                                flashcardProvider.flashcards[index],
                              ),
                              onDelete: () => _confirmDeleteCard(
                                context,
                                flashcardProvider.flashcards[index],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'deck_detail_fab',
            onPressed: () => _navigateToAddCard(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, String action, dynamic deck) {
    switch (action) {
      case 'edit':
        // Navigate to edit deck
        break;
      case 'export':
        // Export deck
        break;
      case 'import':
        // Import cards
        break;
      case 'publish':
        Navigator.pushNamed(context, '/publish', arguments: deck.id);
        break;
      case 'manage-published':
        Navigator.pushNamed(context, '/manage-published');
        break;
      case 'unlink':
        _confirmUnlink(context);
        break;
    }
  }

  void _confirmUnlink(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unlinkDeck),
        content: Text(l10n.unlinkDeckMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SyncProvider>().unlinkDeck(widget.deckId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.deckUnlinked)),
              );
            },
            child: Text(l10n.unlink),
          ),
        ],
      ),
    );
  }

  void _navigateToViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardViewerScreen(deckId: widget.deckId),
      ),
    );
  }

  void _navigateToStudy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(deckId: widget.deckId),
      ),
    );
  }

  void _navigateToAddCard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardEditorScreen(deckId: widget.deckId),
      ),
    );
  }

  void _navigateToViewCard(BuildContext context, Flashcard card) {
    // Navigate to card detail/viewer
  }

  void _navigateToEditCard(BuildContext context, Flashcard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardEditorScreen(
          deckId: widget.deckId,
          flashcard: card,
        ),
      ),
    );
  }

  void _confirmDeleteCard(BuildContext context, Flashcard card) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteFlashcard),
        content: Text(l10n.deleteConfirmMessage(card.front)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<FlashcardProvider>().deleteFlashcard(card.id);
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

class _DeckHeader extends StatelessWidget {
  final dynamic deck;

  const _DeckHeader({required this.deck});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show linked status and sync badge
          if (deck.isLinked) ...[
            Consumer<SyncProvider>(
              builder: (context, syncProvider, _) {
                final hasUpdate = syncProvider.hasUpdateForDeck(deck.id);
                final update = syncProvider.getUpdateForDeck(deck.id);
                final isSyncing = syncProvider.syncingDeckId == deck.id;

                return Row(
                  children: [
                    LinkedDeckIndicator(
                      hasUpdate: hasUpdate,
                      onSyncTap: hasUpdate && !isSyncing
                          ? () => syncProvider.syncDeck(deck.id)
                          : null,
                    ),
                    if (isSyncing) ...[
                      const SizedBox(width: 8),
                      const SyncBadge(isSyncing: true),
                    ] else if (hasUpdate && update != null) ...[
                      const SizedBox(width: 8),
                      SyncBadge(
                        hasUpdate: true,
                        versionsBehind: update.versionsBehind,
                        onTap: () => syncProvider.syncDeck(deck.id),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          // Show published status
          if (deck.isPublished) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    l10n.published,
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (deck.description != null && deck.description!.isNotEmpty) ...[
            Text(
              deck.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: l10n.total,
                value: '${deck.cardCount}',
                color: AppColors.primary,
              ),
              _StatItem(
                label: l10n.newCards,
                value: '${deck.newCount}',
                color: AppColors.info,
              ),
              _StatItem(
                label: l10n.learning,
                value: '${deck.learningCount}',
                color: AppColors.warning,
              ),
              _StatItem(
                label: l10n.reviewCards,
                value: '${deck.reviewCount}',
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
      ],
    );
  }
}

class _FlashcardListItem extends StatelessWidget {
  final Flashcard flashcard;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlashcardListItem({
    required this.flashcard,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flashcard.front,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (flashcard.frontPhonetic != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        flashcard.frontPhonetic!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      flashcard.back,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
              ),
              _buildStatusIndicator(context),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;

    if (flashcard.isNew) {
      color = AppColors.info;
      label = l10n.newCards;
    } else if (flashcard.isLearning) {
      color = AppColors.warning;
      label = l10n.learning;
    } else if (flashcard.isDue) {
      color = AppColors.error;
      label = l10n.due;
    } else {
      color = AppColors.success;
      label = l10n.done;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
