import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../data/models/flashcard.dart';
import '../../../data/models/deck.dart';
import '../../../data/models/category.dart';
import '../../../data/services/tts_service.dart';
import '../../../data/services/excel_service.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/deck_card_header.dart';
import '../../widgets/sync/sync_badge.dart';
import '../../widgets/dialogs/tts_help_dialog.dart';
import '../../widgets/ai/ai_generate_bottom_sheet.dart';
import '../deck/create_deck_screen.dart';
import '../flashcard/flashcard_editor_screen.dart';
import '../flashcard/flashcard_viewer_screen.dart';
import '../study/study_screen.dart';
import '../ai/ai_draft_review_screen.dart';
import '../../widgets/dialogs/standard_dialog.dart';

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

    return Consumer3<DeckProvider, FlashcardProvider, AiProvider>(
      builder: (context, deckProvider, flashcardProvider, aiProvider, child) {
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
                    // Edit deck
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(l10n.editDeck),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    // Export to Excel
                    PopupMenuItem(
                      value: 'export-excel',
                      child: Row(
                        children: [
                          Icon(Icons.file_download_outlined, size: 20, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text(l10n.exportToExcel),
                        ],
                      ),
                    ),
                    // Import from Excel
                    PopupMenuItem(
                      value: 'import-excel',
                      child: Row(
                        children: [
                          Icon(Icons.upload_file_outlined, size: 20, color: AppColors.info),
                          const SizedBox(width: 8),
                          Text(l10n.importFromExcel),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    // Publish (only if canPublish and authenticated)
                    if (deck.canPublish && isAuthenticated)
                      PopupMenuItem(
                        value: 'publish',
                        child: Row(
                          children: [
                            Icon(Icons.public, size: 20, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text(l10n.publishToLibrary),
                          ],
                        ),
                      ),
                    // Unlink from library
                    if (deck.isLinked)
                      PopupMenuItem(
                        value: 'unlink',
                        child: Row(
                          children: [
                            Icon(Icons.link_off, size: 20, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Text(l10n.unlinkFromLibrary),
                          ],
                        ),
                      ),
                    // Share Deck ID (only if published)
                    if (deck.isPublished && deck.publishedDeckId != null)
                      PopupMenuItem(
                        value: 'share-id',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(l10n.shareDeckIdMenu),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    // Delete deck
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text(l10n.deleteDeckMenu, style: const TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  _buildAiStatusBanner(context, aiProvider),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                  // Deck header
                  SliverToBoxAdapter(
                    child: _DeckHeader(deck: deck),
                  ),

                  // Action buttons (pinned)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyActionButtonsDelegate(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: flashcardProvider.flashcards.isEmpty
                                        ? null
                                        : () => _navigateToViewer(context),
                                    icon: const Icon(Icons.visibility),
                                    label: Text(l10n.browse),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: deck.cardCount == 0
                                        ? null
                                        : () => _navigateToStudy(context),
                                    icon: const Icon(Icons.school),
                                    label: deck.dueCount > 0
                                        ? Text(l10n.studyN(deck.dueCount))
                                        : Text(l10n.studyAgain),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ),
                    ),
                  ),

                  // Flashcard list
                  if (flashcardProvider.flashcards.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        title: l10n.noFlashcardsYet,
                        subtitle: l10n.addFlashcardsToStart,
                        icon: Icons.style,
                        action: ElevatedButton.icon(
                          onPressed: () => _navigateToAddCard(context),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addFlashcard),
                        ),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: flashcardProvider.flashcards.length,
                      itemBuilder: (context, index) {
                        final card = flashcardProvider.flashcards[index];
                        return Padding(
                          key: ValueKey(card.id),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _FlashcardListItem(
                            flashcard: card,
                            index: index,
                            onDoubleTap: () => _navigateToBrowseAt(context, index),
                            onEdit: () => _navigateToEditCard(context, card),
                            onDelete: () => _confirmDeleteCard(context, card),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
            floatingActionButton: _buildFab(context, deck),
          ),
        );
      },
    );
  }

  Widget _buildAiStatusBanner(BuildContext context, AiProvider aiProvider) {
    if (aiProvider.currentDeckId != widget.deckId) {
      return const SizedBox.shrink();
    }
    if (aiProvider.state == AiState.idle) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    if (aiProvider.state == AiState.generating) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.primary.withOpacity(0.08),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.generatingCards,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (aiProvider.state == AiState.success && aiProvider.draftCards.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.success.withOpacity(0.08),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${l10n.success}: ${l10n.aiGeneratedCards} (${aiProvider.draftCards.length})',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AiDraftReviewScreen(deckId: widget.deckId),
                  ),
                );
              },
              child: Text(l10n.browse),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => aiProvider.reset(),
            ),
          ],
        ),
      );
    }

    if (aiProvider.state == AiState.error) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.error.withOpacity(0.08),
        child: Row(
          children: [
            const Icon(Icons.error, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                aiProvider.errorMessage ?? l10n.aiGenerationFailed,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => aiProvider.reset(),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// FAB with expandable options: Add Card + AI Generate
  Widget _buildFab(BuildContext context, Deck deck) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // AI Generate mini FAB
        FloatingActionButton.small(
          heroTag: 'deck_detail_ai_fab',
          onPressed: () => _showAiGenerateSheet(context, deck),
          backgroundColor: AppColors.secondary,
          child: const Icon(Icons.auto_awesome, size: 20),
        ),
        const SizedBox(height: 10),
        // Add card main FAB
        FloatingActionButton(
          heroTag: 'deck_detail_fab',
          onPressed: () => _navigateToAddCard(context),
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  void _showAiGenerateSheet(BuildContext context, Deck deck) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiGenerateBottomSheet(
        sourceLanguage: deck.sourceLanguage,
        targetLanguage: deck.targetLanguage,
        deckId: deck.id,
      ),
    );

    if (result == true && mounted) {
      // AI generation succeeded, navigate to draft review
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiDraftReviewScreen(deckId: deck.id),
        ),
      );
    }
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
      case 'unlink':
        _confirmUnlink(context);
        break;
      case 'share-id':
        _shareDeckId(context, deck);
        break;
      case 'delete':
        _confirmDeleteDeck(context, deck);
        break;
    }
  }

  void _shareDeckId(BuildContext context, Deck deck) {
    final id = deck.publishedDeckId ?? deck.id;
    Clipboard.setData(ClipboardData(text: id));
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.deckIdCopied)),
    );
  }

  void _confirmDeleteDeck(BuildContext context, Deck deck) {
    final l10n = AppLocalizations.of(context)!;

    showStandardDialog(
      context: context,
      title: l10n.deleteConfirmTitle(deck.name),
      content: l10n.deleteConfirmMessage(deck.name),
      primaryButtonText: l10n.delete,
      secondaryButtonText: l10n.cancel,
      isDestructive: true,
      onPrimaryPressed: () async {
        await context.read<DeckProvider>().deleteDeck(deck.id);
        if (context.mounted) {
          Navigator.pop(context); // go back from deck detail
        }
      },
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

class _StickyActionButtonsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyActionButtonsDelegate({required this.child});

  @override
  double get minExtent => 72.0; // 12 padding top + 48 button + 12 padding bottom
  @override
  double get maxExtent => 72.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: maxExtent,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: overlapsContent || shrinkOffset > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyActionButtonsDelegate oldDelegate) {
    return true;
  }
}

/// Deck header styled like the public library deck preview card.
/// Shows deck image, name, front/back field chips, language badges,
/// status badges, description, tags, category, and stats.
class _DeckHeader extends StatelessWidget {
  final Deck deck;

  const _DeckHeader({required this.deck});

  String _formatFields(List<CardFieldType> fields) {
    return fields.map((f) => f.displayName).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = deck.category != null ? Category.getById(deck.category!) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Row 1: Image + Info ===
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Deck image
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: DeckCardHeader.buildDeckImage(context, deck.imagePath),
                ),
                const SizedBox(width: 12),

                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        deck.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Front/back field chips + language badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (!deck.showBackFirst) ...[
                            DeckCardHeader.buildMiniChip(
                              context,
                              Icons.flip_to_front,
                              _formatFields(deck.frontFields),
                              AppColors.primary,
                            ),
                            DeckCardHeader.buildMiniChip(
                              context,
                              Icons.flip_to_back,
                              _formatFields(deck.backFields),
                              AppColors.secondary,
                            ),
                          ] else ...[
                            DeckCardHeader.buildMiniChip(
                              context,
                              Icons.flip_to_back,
                              _formatFields(deck.backFields),
                              AppColors.secondary,
                            ),
                            DeckCardHeader.buildMiniChip(
                              context,
                              Icons.flip_to_front,
                              _formatFields(deck.frontFields),
                              AppColors.primary,
                            ),
                          ],
                          // Language badges
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DeckCardHeader.buildLanguageBadge(context, deck.sourceLanguage),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2),
                                child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                              ),
                              DeckCardHeader.buildLanguageBadge(context, deck.targetLanguage),
                            ],
                          ),
                        ],
                      ),

                      // Description
                      if (deck.description != null && deck.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          deck.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // === Status badges row ===
            if (deck.isLinked || deck.isPublished) ...[
              const SizedBox(height: 8),
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

            // === Bottom row: Category + Stats ===
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
                          _getCategoryIcon(category.icon ?? 'category'),
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
                  const SizedBox(width: 8),
                ],

                const Spacer(),

                // Stats inline
                _StatChip(label: l10n.total, value: '${deck.cardCount}', color: AppColors.primary),
                const SizedBox(width: 10),
                _StatChip(label: l10n.newCards, value: '${deck.newCount}', color: AppColors.info),
                const SizedBox(width: 10),
                _StatChip(label: l10n.learning, value: '${deck.learningCount}', color: AppColors.warning),
                const SizedBox(width: 10),
                _StatChip(label: l10n.reviewCards, value: '${deck.reviewCount}', color: AppColors.secondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'flight': return Icons.flight;
      case 'business': return Icons.business;
      case 'home': return Icons.home;
      case 'menu_book': return Icons.menu_book;
      case 'chat_bubble': return Icons.chat_bubble;
      case 'school': return Icons.school;
      case 'translate': return Icons.translate;
      case 'more_horiz': return Icons.more_horiz;
      default: return Icons.category;
    }
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
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 10,
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
              // Remove drag handle since reordering is not supported
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
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(l10n.delete,
                            style: const TextStyle(color: AppColors.error)),
                      ],
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
