import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/public_library_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/publish_provider.dart';
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
      _tabController = TabController(length: 5, vsync: this);
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
              Tab(text: l10n.myPublishedDecks),
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
            _MyDecksTab(),
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
  final _deckIdController = TextEditingController();

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
    _deckIdController.dispose();
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
            // Import by ID
            _buildImportByIdRow(context),

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

  Widget _buildImportByIdRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _deckIdController,
              decoration: InputDecoration(
                hintText: l10n.enterDeckId,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _importById(context),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: l10n.importById,
            onPressed: () => _importById(context),
          ),
        ],
      ),
    );
  }

  void _importById(BuildContext context) {
    final id = _deckIdController.text.trim();
    if (id.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicDeckDetailScreen(deckId: id),
        ),
      );
    }
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

class _MyDecksTab extends StatefulWidget {
  @override
  State<_MyDecksTab> createState() => _MyDecksTabState();
}

class _MyDecksTabState extends State<_MyDecksTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublishProvider>().loadMyPublishedDecks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Consumer<PublishProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.myPublishedDecks.isEmpty) {
              return _buildEmptyState(context, l10n.noPublishedDecks);
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadMyPublishedDecks(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.myPublishedDecks.length,
                itemBuilder: (context, index) {
                  final deck = provider.myPublishedDecks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PublicDeckCard(
                      deck: deck,
                      onTap: () => _showDeckOptions(context, deck.id),
                    ),
                  );
                },
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _showPublishDeckPicker(context),
            tooltip: l10n.publishToLibrary,
            child: const Icon(Icons.cloud_upload),
          ),
        ),
      ],
    );
  }

  void _showPublishDeckPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deckProvider = context.read<DeckProvider>();
    final publishProvider = context.read<PublishProvider>();
    final navigator = Navigator.of(context);
    final unpublishedDecks = deckProvider.decks
        .where((d) => !d.isPublished)
        .toList();

    if (unpublishedDecks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.allDecksPublished)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.selectDeckToPublish,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...unpublishedDecks.map((deck) => ListTile(
                leading: const Icon(Icons.style),
                title: Text(deck.name),
                subtitle: Text(l10n.cardsCount(deck.cardCount)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  navigator.pushNamed('/publish', arguments: deck.id).then((_) {
                    publishProvider.loadMyPublishedDecks();
                  });
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showDeckOptions(BuildContext context, String publicDeckId) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.shareDeckId),
                subtitle: Text(l10n.copyDeckIdToShare),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: publicDeckId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.deckIdCopied)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: Text(l10n.pushUpdate),
                subtitle: Text(l10n.syncChanges),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.updatingDeck)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: Text(l10n.unpublish),
                subtitle: Text(l10n.removeFromLibrary),
                onTap: () {
                  Navigator.pop(context);
                  _confirmUnpublish(context, publicDeckId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: Text(l10n.viewAnalytics),
                subtitle: Text(l10n.analyticsComingSoon),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.analyticsComingSoon)),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmUnpublish(BuildContext context, String publicDeckId) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unpublishConfirm),
        content: Text(l10n.unpublishDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.deckUnpublished)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.unpublish),
          ),
        ],
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
