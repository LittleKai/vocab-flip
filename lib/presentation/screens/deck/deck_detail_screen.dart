import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../data/models/flashcard.dart';
import '../../../data/models/deck.dart';
import '../../../data/services/tts_service.dart';
import '../../../data/services/excel_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/sync/sync_badge.dart';
import '../../widgets/dialogs/tts_help_dialog.dart';
import '../deck/create_deck_screen.dart';
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
  final FocusNode _focusNode = FocusNode();
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<DeckProvider>().selectDeck(widget.deckId);
      if (!mounted) return;
      context.read<FlashcardProvider>().loadFlashcards(widget.deckId);
      context.read<SyncProvider>().checkForUpdates();
      _focusNode.requestFocus();

      if (mounted) {
        await _checkTtsForDeck();
      }
    });
  }

  Future<void> _checkTtsForDeck() async {
    final deck = context.read<DeckProvider>().selectedDeck;
    if (deck == null) return;

    final language = SupportedLanguage.fromCode(deck.sourceLanguage);

    if (!_ttsService.isInitialized) {
      await _ttsService.init();
    }

    if (context.mounted) {
      await TtsHelpDialog.checkAndShowWarningForLanguage(
        context,
        _ttsService,
        language,
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    return Consumer2<DeckProvider, FlashcardProvider>(
      builder: (context, deckProvider, flashcardProvider, child) {
        final deck = deckProvider.selectedDeck;

        if (deck == null || flashcardProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const LoadingWidget(),
          );
        }

        return KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
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
                  onSelected: (value) =>
                      _handleMenuAction(context, value, deck),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.editDeck)),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'export-excel',
                      child: Row(
                        children: [
                          const Icon(Icons.file_download, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.exportToExcel),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'import-excel',
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.importFromExcel),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    if (deck.isPublished)
                      PopupMenuItem(
                          value: 'manage-published',
                          child: Text(l10n.managePublished))
                    else if (deck.canPublish && isAuthenticated)
                      PopupMenuItem(
                          value: 'publish', child: Text(l10n.publishToLibrary)),
                    if (deck.isLinked)
                      PopupMenuItem(
                          value: 'unlink', child: Text(l10n.unlinkFromLibrary)),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Column(
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
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: flashcardProvider.flashcards.length,
                            buildDefaultDragHandles: false,
                            onReorder: (oldIndex, newIndex) {
                              flashcardProvider.reorderFlashcards(
                                  oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final card = flashcardProvider.flashcards[index];
                              return _FlashcardListItem(
                                key: ValueKey(card.id),
                                flashcard: card,
                                index: index,
                                onDoubleTap: () =>
                                    _navigateToBrowseAt(context, index),
                                onEdit: () =>
                                    _navigateToEditCard(context, card),
                                onDelete: () =>
                                    _confirmDeleteCard(context, card),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'deck_detail_fab',
              onPressed: () => _navigateToAddCard(context),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  void _navigateToBrowseAt(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FlashcardViewerScreen(deckId: widget.deckId, startIndex: index),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, Deck deck) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateDeckScreen(deck: deck),
          ),
        );
        break;
      case 'import-excel':
        _importFromExcel(context, deck);
        break;
      case 'export-excel':
        _exportToExcel(context, deck);
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

  Future<void> _importFromExcel(BuildContext context, Deck deck) async {
    final l10n = AppLocalizations.of(context)!;
    final excelService = ExcelService();
    final flashcardProvider = context.read<FlashcardProvider>();

    // Pick and import file
    final result = await excelService.pickAndImportExcel(
        deck, flashcardProvider.flashcards);

    if (!mounted) return;

    if (result == null) {
      // User cancelled or error occurred
      return;
    }

    // Check if file is from a different deck
    if (result.deckIdFromFile != null && result.deckIdFromFile != deck.id) {
      final continueImport = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.warning),
          content: Text(l10n
              .excelFromDifferentDeck(result.deckNameFromFile ?? 'Unknown')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.continueImport),
            ),
          ],
        ),
      );
      if (continueImport != true) return;
    }

    if (result.totalCards == 0 && result.errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noCardsToImport)),
      );
      return;
    }

    // Show confirmation dialog with results
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importFromExcel),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.importSummary),
              const SizedBox(height: 12),
              if (result.hasNewCards)
                _ImportSummaryRow(
                  icon: Icons.add_circle,
                  color: AppColors.success,
                  label: l10n.newCardsToAdd,
                  count: result.newCards.length,
                ),
              if (result.hasUpdatedCards) ...[
                const SizedBox(height: 8),
                _ImportSummaryRow(
                  icon: Icons.edit,
                  color: AppColors.info,
                  label: l10n.cardsToUpdate,
                  count: result.updatedCards.length,
                ),
              ],
              if (result.hasErrors) ...[
                const SizedBox(height: 8),
                _ImportSummaryRow(
                  icon: Icons.error,
                  color: AppColors.error,
                  label: l10n.errorsFound,
                  count: result.errors.length,
                ),
                ...result.errors.take(3).map((e) => Padding(
                      padding: const EdgeInsets.only(left: 32, top: 4),
                      child: Text(
                        e,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          if (result.totalCards > 0)
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.importN(result.totalCards)),
            ),
        ],
      ),
    );

    if (confirmed != true || result.totalCards == 0) return;

    // Import/Update cards
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.importingCards),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      int added = 0;
      int updated = 0;

      // Add new cards
      for (final card in result.newCards) {
        await flashcardProvider.createFlashcard(card);
        added++;
      }

      // Update existing cards
      for (final card in result.updatedCards) {
        await flashcardProvider.updateFlashcard(card);
        updated++;
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.importCompleted(added, updated)),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _exportToExcel(BuildContext context, Deck deck) async {
    final l10n = AppLocalizations.of(context)!;
    final excelService = ExcelService();
    final flashcardProvider = context.read<FlashcardProvider>();
    final locale = context.read<SettingsProvider>().locale;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final filePath = await excelService.exportDeckToExcel(
          deck, flashcardProvider.flashcards,
          locale: locale);
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.excelExportedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorExportingExcel)),
        );
      }
    } on ExcelFileInUseException {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.excelFileInUse),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e')),
      );
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
            onPressed: () async {
              await context.read<SyncProvider>().unlinkDeck(widget.deckId);
              if (context.mounted) {
                // Reload deck to reflect unlinked state
                context.read<DeckProvider>().selectDeck(widget.deckId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.deckUnlinked)),
                );
              }
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status badges (linked + published) inline
          if (deck.isLinked || deck.isPublished) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (deck.isLinked)
                  Consumer<SyncProvider>(
                    builder: (context, syncProvider, _) {
                      final hasUpdate = syncProvider.hasUpdateForDeck(deck.id);
                      final update = syncProvider.getUpdateForDeck(deck.id);
                      final isSyncing = syncProvider.syncingDeckId == deck.id;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LinkedDeckIndicator(
                            hasUpdate: hasUpdate,
                            onSyncTap: hasUpdate && !isSyncing
                                ? () => syncProvider.syncDeck(deck.id)
                                : null,
                          ),
                          if (isSyncing) ...[
                            const SizedBox(width: 6),
                            const SyncBadge(isSyncing: true),
                          ] else if (hasUpdate && update != null) ...[
                            const SizedBox(width: 6),
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
                if (deck.isPublished)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.public, size: 13, color: AppColors.success),
                        const SizedBox(width: 3),
                        Text(
                          l10n.published,
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Row 2: Description
          if (deck.description != null && deck.description!.isNotEmpty) ...[
            Text(
              deck.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],

          // Row 3: Stats as compact inline chips
          Row(
            children: [
              _StatChip(
                label: l10n.total,
                value: '${deck.cardCount}',
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: l10n.newCards,
                value: '${deck.newCount}',
                color: AppColors.info,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: l10n.learning,
                value: '${deck.learningCount}',
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              _StatChip(
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FlashcardListItem extends StatelessWidget {
  final Flashcard flashcard;
  final int index;
  final VoidCallback? onDoubleTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlashcardListItem({
    super.key,
    required this.flashcard,
    required this.index,
    this.onDoubleTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onDoubleTap: onDoubleTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Drag handle at start only
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.drag_handle,
                    color: AppColors.textSecondaryLight,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                    child: Text(l10n.delete,
                        style: const TextStyle(color: AppColors.error)),
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

class _ImportSummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _ImportSummaryRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
