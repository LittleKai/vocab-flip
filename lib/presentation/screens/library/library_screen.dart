import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/public_library_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/publish_provider.dart';
import '../../providers/sync_provider.dart';
import '../../../data/local/database/deck_dao.dart';
import '../../widgets/library/public_deck_card.dart';
import '../../widgets/library/filter_sheet.dart';
import '../../widgets/sync/sync_badge.dart';
import '../../widgets/common/responsive_grid.dart';
import '../../widgets/dialogs/standard_dialog.dart';
import 'public_deck_detail_screen.dart';

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
      _tabController = TabController(length: 3, vsync: this);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeLibrary();
      });
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
    }
  }

  Future<void> _initializeLibrary() async {
    if (!mounted) return;

    try {
      await context.read<PublicLibraryProvider>().initialize();
    } catch (e) {
      debugPrint('Error initializing library: $e');
    }

    if (!mounted) return;

    try {
      await context.read<SyncProvider>().checkForUpdates();
      if (!mounted) return;
      await context.read<SyncProvider>().loadNotifications();
    } catch (e) {
      debugPrint('Error checking sync: $e');
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore_rounded,
                        color: Colors.blue, size: 18),
                    const SizedBox(width: 6),
                    Text(l10n.browse),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.new_releases_rounded,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 6),
                    Text(l10n.newDecks),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_done_rounded,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(l10n.myPublishedDecks),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _BrowseTab(),
            _NewestTab(),
            _MyDecksTab(),
          ],
        ),
      );
    } catch (e) {
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

class _NewestTab extends StatefulWidget {
  @override
  State<_NewestTab> createState() => _NewestTabState();
}

class _NewestTabState extends State<_NewestTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      if (!provider.isLoading &&
          !provider.isLoadingMore &&
          provider.hasMoreNewestDecks) {
        provider.loadNewestDecks();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PublicLibraryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.newestDecks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.newestDecks.isEmpty) {
          return _buildEmptyState(context, l10n.noDecksFound);
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => provider.loadNewestDecks(refresh: true),
              child: ResponsiveGrid(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: provider.newestDecks.length,
                mainAxisExtent: 180,
                trailing: provider.isLoadingMore
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : null,
                itemBuilder: (context, index) {
                  final deck = provider.newestDecks[index];
                  return PublicDeckCard(
                    deck: deck,
                    onTap: () => _openDeckDetail(context, deck.id),
                    showDeckId: false,
                  );
                },
              ),
            ),
            // Floating Refresh Button for Web/Desktop
            if (kIsWeb ||
                (!kIsWeb &&
                    (Platform.isWindows ||
                        Platform.isMacOS ||
                        Platform.isLinux)))
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: 'refreshNewest',
                  onPressed: () => provider.loadNewestDecks(refresh: true),
                  tooltip: 'Refresh',
                  child: const Icon(Icons.refresh),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BrowseTab extends StatefulWidget {
  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

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
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<PublicLibraryProvider>();
      debugPrint(
          '[_BrowseTab] onScroll triggered near bottom. isLoading: ${provider.isLoading}, isLoadingMore: ${provider.isLoadingMore}, hasMoreDecks: ${provider.hasMoreDecks}');
      if (!provider.isLoading &&
          !provider.isLoadingMore &&
          provider.hasMoreDecks) {
        if (provider.searchQuery.isEmpty) {
          debugPrint('[_BrowseTab] calling provider.browse() from scroll');
          provider.browse();
        } else {
          debugPrint('[_BrowseTab] calling provider.search() from scroll');
          provider.search(provider.searchQuery);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<PublicLibraryProvider>(
      builder: (context, provider, _) {
        return Stack(
          children: [
            Column(
              children: [
                // Search + count + filter in one row
                _buildSearchFilterBar(context, provider),

                // Deck list
                Expanded(
                  child: _buildDeckList(context, provider),
                ),
              ],
            ),
            // Import by ID FAB
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (kIsWeb ||
                      (!kIsWeb &&
                          (Platform.isWindows ||
                              Platform.isMacOS ||
                              Platform.isLinux))) ...[
                    FloatingActionButton.small(
                      heroTag: 'refreshBrowse',
                      onPressed: () => provider.browse(refresh: true),
                      tooltip: 'Refresh',
                      child: const Icon(Icons.refresh),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FloatingActionButton.small(
                    heroTag: 'importById',
                    onPressed: () => _showImportByIdDialog(context),
                    tooltip: l10n.importById,
                    child: const Icon(Icons.pin),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  late final l10n = AppLocalizations.of(context)!;

  Widget _buildSearchFilterBar(
      BuildContext context, PublicLibraryProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchDecks,
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.primary.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            provider.search('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                onSubmitted: (value) {
                  provider.search(value.trim());
                },
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                l10n.decksCount(provider.decks.length),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.tune_rounded, size: 20),
              color: AppColors.primary,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                FilterSheet.show(
                  context: context,
                  currentFilter: provider.filter,
                  categories: provider.categories,
                  onApply: provider.setFilter,
                );
              },
              tooltip: l10n.filter,
            ),
          ],
        ),
      ),
    );
  }

  void _showImportByIdDialog(BuildContext context) {
    final idController = TextEditingController();
    final navigator = Navigator.of(context);

    showStandardDialog(
      context: context,
      title: l10n.importById,
      customContent: TextField(
        controller: idController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.enterDeckId,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          final id = value.trim();
          if (id.isNotEmpty) {
            Navigator.of(context, rootNavigator: true).pop();
            navigator.push(
              MaterialPageRoute(
                builder: (_) => PublicDeckDetailScreen(deckId: id),
              ),
            );
          }
        },
      ),
      secondaryButtonText: l10n.cancel,
      primaryButtonText: l10n.go,
      onPrimaryPressed: () {
        final id = idController.text.trim();
        if (id.isNotEmpty) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => PublicDeckDetailScreen(deckId: id),
            ),
          );
        }
      },
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
      child: ResponsiveGrid(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: provider.decks.length,
        mainAxisExtent: 180,
        trailing: provider.isLoadingMore
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            : null,
        itemBuilder: (context, index) {
          final deck = provider.decks[index];
          return PublicDeckCard(
            deck: deck,
            onTap: () => _openDeckDetail(context, deck.id),
            showDeckId: false,
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

class _MyDecksTabState extends State<_MyDecksTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PublishProvider>();
      if (!provider.hasLoadedMyDecks) {
        provider.loadMyPublishedDecks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              child: ResponsiveGrid(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: provider.myPublishedDecks.length,
                mainAxisExtent: 180,
                itemBuilder: (context, index) {
                  final deck = provider.myPublishedDecks[index];
                  return PublicDeckCard(
                    deck: deck,
                    onTap: () => _showDeckOptions(context, deck.id),
                  );
                },
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kIsWeb ||
                  (!kIsWeb &&
                      (Platform.isWindows ||
                          Platform.isMacOS ||
                          Platform.isLinux))) ...[
                FloatingActionButton.small(
                  heroTag: 'refreshPublished',
                  onPressed: () =>
                      context.read<PublishProvider>().loadMyPublishedDecks(),
                  tooltip: 'Refresh',
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 8),
              ],
              FloatingActionButton(
                onPressed: () => _showPublishDeckPicker(context),
                tooltip: l10n.publishToLibrary,
                child: const Icon(Icons.cloud_upload),
              ),
            ],
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
    final unpublishedDecks =
        deckProvider.decks.where((d) => !d.isPublished).toList();

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      navigator
                          .pushNamed('/publish', arguments: deck.id)
                          .then((_) {
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
    final publishProvider = context.read<PublishProvider>();
    final deckProvider = context.read<DeckProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Check if local deck still exists
    final localDeckExists = deckProvider.decks.any(
      (d) => d.publishedDeckId == publicDeckId,
    );

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
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.shareDeckId),
                subtitle: Text(l10n.copyDeckIdToShare),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Clipboard.setData(ClipboardData(text: publicDeckId));
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.deckIdCopied)),
                  );
                },
              ),
              if (localDeckExists)
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: Text(l10n.pushUpdate),
                  subtitle: Text(l10n.syncChanges),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pushUpdate(context, publicDeckId);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(l10n.reimportDeck),
                  subtitle: Text(l10n.reimportDescription),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _reimportDeck(context, publicDeckId);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: Text(l10n.unpublish),
                subtitle: Text(l10n.removeFromLibrary),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmUnpublish(
                      context, publicDeckId, publishProvider, messenger, l10n);
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: Text(l10n.viewAnalytics),
                subtitle: Text(l10n.analyticsComingSoon),
                onTap: () {
                  Navigator.pop(sheetContext);
                  messenger.showSnackBar(
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

  Future<void> _reimportDeck(BuildContext context, String publicDeckId) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final libraryProvider = context.read<PublicLibraryProvider>();
    final deckProvider = context.read<DeckProvider>();
    final publishProvider = context.read<PublishProvider>();

    messenger.showSnackBar(
      SnackBar(content: Text(l10n.loading)),
    );

    try {
      final importedDeck = await libraryProvider.importDeck(publicDeckId);
      if (importedDeck != null) {
        // Mark the imported deck as published and link it
        final deckDao = DeckDao();
        await deckDao.updateFields(importedDeck.id, {
          'is_published': 1,
          'published_deck_id': publicDeckId,
        });

        // Refresh local deck list
        await deckProvider.loadDecks();
        await publishProvider.loadMyPublishedDecks();

        if (context.mounted) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.reimportSuccess)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.failedToImport(e.toString()))),
        );
      }
    }
  }

  Future<void> _pushUpdate(BuildContext context, String publicDeckId) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final deckProvider = context.read<DeckProvider>();
    final publishProvider = context.read<PublishProvider>();

    // Find local deck linked to this public deck
    final localDeck = deckProvider.decks.firstWhere(
      (d) => d.publishedDeckId == publicDeckId,
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.updatingDeck),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      final success = await publishProvider.updatePublishedDeck(localDeck.id);
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              success ? l10n.deckUpdated : publishProvider.error ?? l10n.error),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e')),
      );
    }
  }

  void _confirmUnpublish(
    BuildContext context,
    String publicDeckId,
    PublishProvider publishProvider,
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
  ) {
    showStandardDialog(
      context: context,
      title: l10n.unpublishConfirm,
      content: l10n.unpublishDescription,
      isDestructive: true,
      secondaryButtonText: l10n.cancel,
      primaryButtonText: l10n.unpublish,
      onPrimaryPressed: () async {
        final localDeckExists = context.read<DeckProvider>().decks.any(
              (d) =>
                  d.publishedDeckId == publicDeckId ||
                  d.linkedPublicDeckId == publicDeckId,
            );

        if (!localDeckExists) {
          // Show second confirmation dialog warning the user they will lose the deck permanently
          showStandardDialog(
            context: context,
            title: l10n.localCopyMissing,
            content: l10n.unpublishLocalMissingWarning,
            isDestructive: true,
            secondaryButtonText: l10n.cancel,
            primaryButtonText: l10n.unpublish,
            onPrimaryPressed: () async {
              final success =
                  await publishProvider.unpublishByPublicId(publicDeckId);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success
                      ? l10n.deckUnpublished
                      : publishProvider.error ?? 'Failed to unpublish'),
                ),
              );
            },
          );
        } else {
          // Local copy exists, proceed normally
          final success =
              await publishProvider.unpublishByPublicId(publicDeckId);
          messenger.showSnackBar(
            SnackBar(
              content: Text(success
                  ? l10n.deckUnpublished
                  : publishProvider.error ?? 'Failed to unpublish'),
            ),
          );
        }
      },
    );
  }
}

Widget _buildEmptyState(BuildContext context, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
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

void _openDeckDetail(BuildContext context, String deckId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PublicDeckDetailScreen(deckId: deckId),
    ),
  );
}
