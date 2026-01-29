import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/public_library_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/library/public_deck_card.dart';
import '../../widgets/library/filter_sheet.dart';
import '../../widgets/sync/sync_badge.dart';
import 'public_deck_detail_screen.dart';
import 'library_search_screen.dart';

/// Main library browse screen
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    try {
      _tabController = TabController(length: 4, vsync: this);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeLibrary();
      });
    } catch (e, stack) {
      debugPrint('Error in initState: $e');
      debugPrint('Stack: $stack');
      _hasError = true;
      _errorMessage = e.toString();
    }
  }

  Future<void> _initializeLibrary() async {
    if (!mounted) return;

    try {
      debugPrint('Initializing PublicLibraryProvider...');
      await context.read<PublicLibraryProvider>().initialize();
      debugPrint('PublicLibraryProvider initialized');
    } catch (e, stack) {
      debugPrint('Error initializing library: $e');
      debugPrint('Stack: $stack');
    }

    if (!mounted) return;

    try {
      debugPrint('Checking sync updates...');
      await context.read<SyncProvider>().checkForUpdates();
      await context.read<SyncProvider>().loadNotifications();
      debugPrint('Sync check complete');
    } catch (e, stack) {
      debugPrint('Error checking sync: $e');
      debugPrint('Stack: $stack');
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building LibraryScreen...');
    final l10n = AppLocalizations.of(context)!;

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.library)),
        body: Center(
          child: Text('${l10n.error}: $_errorMessage'),
        ),
      );
    }

    if (_tabController == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.library)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.library),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LibrarySearchScreen(),
                  ),
                );
              },
            ),
            Consumer<SyncProvider>(
              builder: (context, syncProvider, _) {
                return SyncNotificationBadge(
                  unreadCount: syncProvider.unreadCount,
                  onTap: () => _showSyncNotifications(context),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(text: l10n.featured),
              Tab(text: l10n.topRated),
              Tab(text: l10n.newDecks),
              Tab(text: l10n.browse),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _FeaturedTab(),
            _TopRatedTab(),
            _NewestTab(),
            _BrowseTab(),
          ],
        ),
      );
    } catch (e, stack) {
      debugPrint('Error building LibraryScreen: $e');
      debugPrint('Stack: $stack');
      return Scaffold(
        appBar: AppBar(title: Text(l10n.library)),
        body: Center(
          child: Text('${l10n.error}: $e'),
        ),
      );
    }
  }

  void _showSyncNotifications(BuildContext context) {
    Navigator.pushNamed(context, '/sync-notifications');
  }
}

class _FeaturedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PublicLibraryProvider>(
      builder: (context, provider, _) {
        if (provider.error != null) {
          return _buildErrorState(context, provider.error!, () {
            provider.initialize();
          });
        }

        if (provider.isLoading && provider.featuredDecks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.featuredDecks.isEmpty) {
          return _buildEmptyState(context, l10n.noFeaturedDecks);
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadFeaturedDecks(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.featuredDecks.length,
            itemBuilder: (context, index) {
              final deck = provider.featuredDecks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PublicDeckCard(
                  deck: deck,
                  onTap: () => _openDeckDetail(context, deck.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TopRatedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PublicLibraryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.topRatedDecks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.topRatedDecks.isEmpty) {
          return _buildEmptyState(context, l10n.noRatedDecks);
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadTopRatedDecks(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.topRatedDecks.length,
            itemBuilder: (context, index) {
              final deck = provider.topRatedDecks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PublicDeckCard(
                  deck: deck,
                  onTap: () => _openDeckDetail(context, deck.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _NewestTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PublicLibraryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.newestDecks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.newestDecks.isEmpty) {
          return _buildEmptyState(context, l10n.noDecksFound);
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadNewestDecks(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.newestDecks.length,
            itemBuilder: (context, index) {
              final deck = provider.newestDecks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PublicDeckCard(
                  deck: deck,
                  onTap: () => _openDeckDetail(context, deck.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _BrowseTab extends StatefulWidget {
  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PublicLibraryProvider>();
      if (provider.decks.isEmpty) {
        provider.browse(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<PublicLibraryProvider>();
      if (!provider.isLoading && !provider.isLoadingMore && provider.hasMoreDecks) {
        provider.browse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PublicLibraryProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Filter bar
            _buildFilterBar(context, provider),

            // Category chips
            if (provider.categories.isNotEmpty)
              _buildCategoryChips(context, provider),

            // Deck list
            Expanded(
              child: _buildDeckList(context, provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, PublicLibraryProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.decksCount(provider.decks.length),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.filter_list, size: 18),
            label: Text(l10n.filter),
            onPressed: () {
              FilterSheet.show(
                context: context,
                currentFilter: provider.filter,
                categories: provider.categories,
                onApply: provider.setFilter,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(
      BuildContext context, PublicLibraryProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: provider.categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(l10n.all),
                selected: provider.filter.categoryId == null,
                onSelected: (_) => provider.setCategory(null),
              ),
            );
          }

          final category = provider.categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category.name),
              selected: provider.filter.categoryId == category.id,
              onSelected: (_) => provider.setCategory(category.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeckList(BuildContext context, PublicLibraryProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    if (provider.isLoading && provider.decks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.decks.isEmpty) {
      return _buildEmptyState(context, l10n.noDecksFound);
    }

    return RefreshIndicator(
      onRefresh: () => provider.browse(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: provider.decks.length + (provider.hasMoreDecks ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.decks.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final deck = provider.decks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PublicDeckCard(
              deck: deck,
              onTap: () => _openDeckDetail(context, deck.id),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildEmptyState(BuildContext context, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.library_books_outlined,
          size: 64,
          color: AppColors.textSecondaryLight,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
      ],
    ),
  );
}

Widget _buildErrorState(BuildContext context, String error, VoidCallback onRetry) {
  final l10n = AppLocalizations.of(context)!;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.unableToConnect,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    ),
  );
}

void _openDeckDetail(BuildContext context, String deckId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PublicDeckDetailScreen(deckId: deckId),
    ),
  );
}
