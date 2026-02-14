import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/deck_navigation.dart';
import '../../../data/models/category.dart';
import '../../../data/models/deck.dart';
import '../../providers/deck_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/deck/deck_filter_sheet.dart';
import 'create_deck_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch(DeckProvider provider) {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        provider.setSearchQuery('');
      }
    });
  }

  void _showFilterSheet(BuildContext context, DeckProvider provider) {
    DeckFilterSheet.show(
      context: context,
      currentCategory: provider.filterCategory,
      currentLanguage: provider.filterLanguage,
      currentSortBy: provider.sortBy,
      onApply: (category, language, sortBy) {
        provider.setDeckFilter(
          category: category,
          language: language,
          sortBy: sortBy,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<DeckProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.searchDecks,
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _toggleSearch(provider),
                      ),
                    ),
                    onChanged: (value) => provider.setSearchQuery(value),
                  )
                : Text(l10n.myDecks),
            actions: [
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _toggleSearch(provider),
                ),
            ],
          ),
          body: _buildBody(context, provider, l10n),
          floatingActionButton: FloatingActionButton(
            heroTag: 'deck_list_fab',
            onPressed: () => _navigateToCreateDeck(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DeckProvider provider, AppLocalizations l10n) {
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

    final filtered = provider.filteredDecks;

    return RefreshIndicator(
      onRefresh: () => provider.loadDecks(),
      child: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Row(
              children: [
                Text(
                  l10n.decksCount(filtered.length),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
                const Spacer(),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: () => _showFilterSheet(context, provider),
                      tooltip: l10n.filter,
                    ),
                    if (provider.hasActiveFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Deck list or no results
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noMatchingDecks,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            provider.clearDeckFilters();
                            setState(() => _isSearching = false);
                          },
                          icon: const Icon(Icons.clear_all),
                          label: Text(l10n.clearFilters),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _DeckCard(deck: filtered[index]);
                    },
                  ),
          ),
        ],
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

    final hasImage = deck.imagePath != null && File(deck.imagePath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToBrowse(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Image + (Name, Description)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(deck.imagePath!),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              // Deck name, language, linked icon, menu
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
                  // Front/Back mode icon
                  Icon(
                    deck.showBackFirst ? Icons.flip_to_back : Icons.flip_to_front,
                    size: 16,
                    color: deck.showBackFirst ? AppColors.secondary : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
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
                        Text(
                          deck.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondaryLight,
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
              // Row 2: Category, Tags, Stats, Study button
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                children: [
                  // Category
                  if (deck.category != null) ...[
                    _StatChip(
                      icon: Icons.category,
                      label: Category.predefined
                          .where((c) => c.id == deck.category)
                          .map((c) => c.getLocalizedName(
                              Localizations.localeOf(context).languageCode))
                          .firstOrNull ?? deck.category!,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Tags
                  ...deck.tags.take(3).map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  )),
                  if (deck.tags.length > 3)
                    Text(
                      '+${deck.tags.length - 3}',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  if (deck.category != null || deck.tags.isNotEmpty)
                    const SizedBox(width: 8),
                  // Card stats
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
