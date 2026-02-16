import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/deck_navigation.dart';
import '../../../data/models/deck.dart';
import '../../widgets/common/deck_card_header.dart';
import '../../providers/deck_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/update_provider.dart';
import '../../widgets/dialogs/update_dialog.dart';
import '../../widgets/common/responsive_grid.dart';
import '../deck/deck_list_screen.dart';
import '../statistics/statistics_screen.dart';
import '../settings/settings_screen.dart';
import '../dictionary/dictionary_search_screen.dart';
import '../library/library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _checkedForUpdates = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndCheckUpdates();
    });
  }

  Future<void> _initializeAndCheckUpdates() async {
    if (!mounted) return;
    // Load decks
    context.read<DeckProvider>().loadDecks();

    // Load settings first (required for update check)
    await context.read<SettingsProvider>().loadSettings();
    if (!mounted) return;

    // Then check for updates
    await _checkForUpdatesOnStartup();
  }

  Future<void> _checkForUpdatesOnStartup() async {
    if (_checkedForUpdates) return;
    _checkedForUpdates = true;

    // Skip on web
    if (kIsWeb) return;
    if (!mounted) return;

    final settings = context.read<SettingsProvider>();
    final updateProvider = context.read<UpdateProvider>();

    // Initialize update provider
    await updateProvider.init(settings.preferences);
    if (!mounted) return;

    // Check if should auto-check (respects 24h interval and user preference)
    if (!updateProvider.shouldAutoCheckOnStartup) return;

    await updateProvider.checkForUpdates(silent: true);

    if (updateProvider.hasUpdate && mounted) {
      // Show update dialog
      showDialog(
        context: context,
        barrierDismissible: !updateProvider.availableUpdate!.isMandatory,
        builder: (context) => UpdateDialog(
          version: updateProvider.availableUpdate!,
        ),
      );
    }
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const _HomeTab();
      case 1:
        return const DeckListScreen();
      case 2:
        return const LibraryScreen();
      case 3:
        return const DictionarySearchScreen();
      case 4:
        return const StatisticsScreen();
      case 5:
        return const SettingsScreen();
      default:
        return const _HomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _buildScreen(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_outlined),
            activeIcon: const Icon(Icons.folder),
            label: l10n.decks,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.public_outlined),
            activeIcon: const Icon(Icons.public),
            label: l10n.library,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            activeIcon: const Icon(Icons.search),
            label: l10n.dictionary,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: l10n.stats,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: Consumer2<DeckProvider, SettingsProvider>(
        builder: (context, deckProvider, settingsProvider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await deckProvider.loadDecks();
              settingsProvider.refreshStats();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome card
                  _buildWelcomeCard(context, settingsProvider),
                  const SizedBox(height: 24),

                  // Quick stats
                  _buildQuickStats(context, deckProvider, settingsProvider),
                  const SizedBox(height: 24),

                  // Due today section
                  _buildDueTodaySection(context, deckProvider),
                  const SizedBox(height: 24),

                  // Recent decks
                  _buildRecentDecks(context, deckProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = l10n.goodMorning;
    } else if (hour < 17) {
      greeting = l10n.goodAfternoon;
    } else {
      greeting = l10n.goodEvening;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.readyToLearn,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.orange.shade300,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.dayStreak(settings.streak),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    DeckProvider deckProvider,
    SettingsProvider settings,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.folder,
            label: l10n.decks,
            value: '${deckProvider.totalDecks}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.style,
            label: l10n.cards,
            value: '${deckProvider.totalCards}',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule,
            label: l10n.due,
            value: '${deckProvider.totalDueCards}',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildDueTodaySection(BuildContext context, DeckProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final dueDecks = provider.decks.where((d) => d.dueCount > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dueToday,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (dueDecks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.allCaughtUp,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  l10n.noCardsToReviewToday,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          )
        else
          _ResponsiveCardList(
            items: dueDecks.take(3).toList(),
            itemBuilder: (deck) => _DueDeckCard(deck: deck),
          ),
      ],
    );
  }

  Widget _buildRecentDecks(BuildContext context, DeckProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    if (provider.decks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentDecks,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _ResponsiveCardList(
          items: provider.decks.take(3).toList(),
          itemBuilder: (deck) => _RecentDeckCard(deck: deck),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
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
      ),
    );
  }
}

class _DueDeckCard extends StatelessWidget {
  final Deck deck;

  const _DueDeckCard({required this.deck});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => DeckNavigation.navigateToStudy(context, deck.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              DeckCardHeader.buildDeckImage(context, deck.imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deck name + language badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deck.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        DeckCardHeader.buildLanguageBadge(context, deck.sourceLanguage),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Due count + card count
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 15, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          l10n.cardsDue(deck.dueCount),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.style, size: 15, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(
                          l10n.nCards(deck.cardCount),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: () => DeckNavigation.navigateToStudy(context, deck.id),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(l10n.study),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDeckCard extends StatelessWidget {
  final Deck deck;

  const _RecentDeckCard({required this.deck});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => DeckNavigation.navigateToBrowse(context, deck.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              DeckCardHeader.buildDeckImage(context, deck.imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deck name + language badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deck.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        DeckCardHeader.buildLanguageBadge(context, deck.sourceLanguage),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Card count + due info
                    Row(
                      children: [
                        Icon(Icons.style, size: 15, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(
                          l10n.nCards(deck.cardCount),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                        ),
                        if (deck.dueCount > 0) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.schedule, size: 15, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            l10n.cardsDue(deck.dueCount),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppColors.textSecondary(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays out items in a responsive grid inside a non-scrollable context.
/// Uses shrinkWrap GridView for multi-column, or Column for single column.
class _ResponsiveCardList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T) itemBuilder;

  const _ResponsiveCardList({
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ResponsiveGrid.columnCount(constraints.maxWidth);

        if (columns == 1) {
          return Column(
            children: items.map((item) => itemBuilder(item)).toList(),
          );
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisExtent: 100,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(items[index]),
        );
      },
    );
  }
}
