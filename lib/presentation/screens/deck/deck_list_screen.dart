import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/deck_navigation.dart';
import '../../../data/models/category.dart';
import '../../../data/models/deck.dart';
import '../../providers/deck_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/common/deck_card_header.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/responsive_grid.dart';
import '../../widgets/deck/deck_filter_sheet.dart';
import '../../widgets/deck/deck_summary_card.dart';
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
                        color: AppColors.textSecondary(context),
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
                          decoration: const BoxDecoration(
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
                                color: AppColors.textSecondary(context),
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
                : ResponsiveGrid(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    mainAxisExtent: 188,
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
    final visibleTags = deck.tags.take(3).toList();
    final hiddenTagCount = deck.tags.length - visibleTags.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToBrowse(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 6, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Image + (Name, chips, lang) + indicators + Menu
              DeckCardHeader(
                name: deck.name,
                imagePath: deck.imagePath,
                frontFieldsLabel: _formatFields(deck.frontFields),
                backFieldsLabel: _formatFields(deck.backFields),
                sourceLanguage: deck.sourceLanguage,
                targetLanguage: 'vi',
                reverseFieldOrder: deck.showBackFirst,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Linked indicator
                    if (deck.isLinked)
                      Consumer<SyncProvider>(
                        builder: (context, syncProvider, _) {
                          final hasUpdate = syncProvider.hasUpdateForDeck(deck.id);
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.link,
                                  size: 16,
                                  color: AppColors.secondary,
                                ),
                                if (hasUpdate) ...[
                                  const SizedBox(width: 2),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
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
                    // Published indicator
                    if (deck.isPublished)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.public, size: 16, color: AppColors.success),
                      ),
                    // Menu button
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(context, value),
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'info', child: Text(l10n.deckDetails)),
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Description row
              if (deck.description != null && deck.description!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    deck.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              // Row 2: Tags
              if (deck.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...visibleTags.map(
                        (tag) => _TagChip(label: '#$tag'),
                      ),
                      if (hiddenTagCount > 0)
                        _TagChip(label: '+$hiddenTagCount'),
                    ],
                  ),
                ),
              ],
              // Row 3: Category, Stats, Study button
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stats = Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (deck.category != null)
                          _CategoryChip(categoryId: deck.category!),
                        DeckStatusChip(
                          icon: Icons.style,
                          label: l10n.nCards(deck.cardCount),
                          color: AppColors.info,
                        ),
                        if (deck.newCount > 0)
                          DeckStatusChip(
                            icon: Icons.fiber_new,
                            label: l10n.nNew(deck.newCount),
                            color: AppColors.error,
                            emphasized: true,
                          ),
                        if (deck.reviewCount > 0)
                          DeckStatusChip(
                            icon: Icons.replay,
                            label: l10n.nReview(deck.reviewCount),
                            color: AppColors.warning,
                            emphasized: true,
                          ),
                      ],
                    );

                    final studyButton = deck.dueCount > 0
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: 32,
                              child: ElevatedButton.icon(
                                onPressed: () => _navigateToStudy(context),
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: Text(l10n.study),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          )
                        : null;

                    if (studyButton == null) {
                      return stats;
                    }

                    if (constraints.maxWidth >= 360) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: stats),
                          const SizedBox(width: 8),
                          studyButton,
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        stats,
                        const SizedBox(height: 8),
                        studyButton,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFields(List<CardFieldType> fields) {
    return fields.map((f) => f.displayName).join(', ');
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

class _CategoryChip extends StatelessWidget {
  final String categoryId;

  const _CategoryChip({required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final category = Category.predefined.where((c) => c.id == categoryId).firstOrNull;
    final categoryName = category?.getLocalizedName(
          Localizations.localeOf(context).languageCode,
        ) ??
        categoryId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _categoryIcon(category?.icon),
            size: 13,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              categoryName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _categoryIcon(String? iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'translate':
        return Icons.translate;
      case 'flight':
        return Icons.flight;
      case 'business':
        return Icons.business;
      case 'home':
        return Icons.home;
      case 'menu_book':
        return Icons.menu_book;
      case 'chat_bubble':
        return Icons.chat_bubble;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade700
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary(context),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
