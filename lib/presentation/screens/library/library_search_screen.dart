import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/public_library_provider.dart';
import '../../widgets/library/public_deck_card.dart';
import 'public_deck_detail_screen.dart';

/// Search screen for the public library
class LibrarySearchScreen extends StatefulWidget {
  const LibrarySearchScreen({super.key});

  @override
  State<LibrarySearchScreen> createState() => _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends State<LibrarySearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: l10n.searchDecks,
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<PublicLibraryProvider>().search('');
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            setState(() {}); // Update clear button visibility
          },
          onSubmitted: (value) {
            context.read<PublicLibraryProvider>().search(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              context
                  .read<PublicLibraryProvider>()
                  .search(_searchController.text);
            },
            child: Text(l10n.search),
          ),
        ],
      ),
      body: Consumer<PublicLibraryProvider>(
        builder: (context, provider, _) {
          if (provider.searchQuery.isEmpty && provider.decks.isEmpty) {
            return _buildSearchSuggestions(context);
          }

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.decks.isEmpty) {
            return _buildNoResults(context, provider.searchQuery);
          }

          return _buildSearchResults(context, provider);
        },
      ),
    );
  }

  Widget _buildSearchSuggestions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = [
      'TOEIC vocabulary',
      'IELTS speaking',
      'Japanese N5',
      'Travel phrases',
      'Business English',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.popularSearches,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return ActionChip(
                label: Text(suggestion),
                onPressed: () {
                  _searchController.text = suggestion;
                  context.read<PublicLibraryProvider>().search(suggestion);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.browseByCategory,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Consumer<PublicLibraryProvider>(
            builder: (context, provider, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.categories.map<Widget>((category) {
                  return ActionChip(
                    avatar: Icon(
                      _getCategoryIcon(category.id),
                      size: 18,
                    ),
                    label: Text(category.name),
                    onPressed: () {
                      provider.setCategory(category.id);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context, String query) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noResultsFor(query),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tryDifferentKeywords,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, PublicLibraryProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.resultsFor(provider.decks.length, provider.searchQuery),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: provider.decks.length,
            itemBuilder: (context, index) {
              final deck = provider.decks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PublicDeckCard(
                  deck: deck,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicDeckDetailScreen(deckId: deck.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'toeic':
      case 'ielts':
      case 'toefl':
        return Icons.school;
      case 'jlpt':
      case 'hsk':
        return Icons.translate;
      case 'travel':
        return Icons.flight;
      case 'business':
        return Icons.business;
      case 'daily':
        return Icons.home;
      case 'academic':
        return Icons.menu_book;
      case 'slang':
        return Icons.chat_bubble;
      default:
        return Icons.folder;
    }
  }
}
