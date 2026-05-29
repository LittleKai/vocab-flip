import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/deck_navigation.dart';
import '../../providers/deck_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/update_provider.dart';
import '../../widgets/dialogs/update_dialog.dart';
import '../../widgets/common/responsive_grid.dart';
import '../../widgets/deck/deck_summary_card.dart';
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
                  _buildDashboardHeader(context, settingsProvider),
                  const SizedBox(height: 16),
                  _buildDueFocusPanel(context, deckProvider),
                  const SizedBox(height: 16),
                  _buildQuickStats(context, deckProvider, settingsProvider),
                  const SizedBox(height: 24),
                  _buildDueTodaySection(context, deckProvider),
                  const SizedBox(height: 24),
                  _buildRecentDecks(context, deckProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardHeader(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.goodMorning
        : hour < 17
            ? l10n.goodAfternoon
            : l10n.goodEvening;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.readyToLearn,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.dayStreak(settings.streak),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDueFocusPanel(BuildContext context, DeckProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final dueDecks = provider.decks.where((deck) => deck.dueCount > 0).toList();
    final primaryDeck = dueDecks.isNotEmpty ? dueDecks.first : null;
    final hasDue = provider.totalDueCards > 0 && primaryDeck != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.20
                  : 0.55,
            ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.today,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            hasDue ? l10n.cardsDue(provider.totalDueCards) : l10n.allCaughtUp,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            hasDue ? primaryDeck.name : l10n.noCardsToReviewToday,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasDue) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => DeckNavigation.navigateToStudy(
                  context,
                  primaryDeck.id,
                ),
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.startStudy),
              ),
            ),
          ],
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
              color: AppColors.success.withValues(alpha: 0.1),
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
            itemBuilder: (deck) => DeckSummaryCard(
              deck: deck,
              cardCountLabel: l10n.nCards(deck.cardCount),
              dueLabel: l10n.cardsDue(deck.dueCount),
              studyLabel: l10n.study,
              onTap: () => DeckNavigation.navigateToStudy(context, deck.id),
              onStudy: () => DeckNavigation.navigateToStudy(context, deck.id),
              compact: true,
            ),
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
          itemBuilder: (deck) => DeckSummaryCard(
            deck: deck,
            cardCountLabel: l10n.nCards(deck.cardCount),
            dueLabel: deck.dueCount > 0 ? l10n.cardsDue(deck.dueCount) : null,
            onTap: () => DeckNavigation.navigateToBrowse(context, deck.id),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary(context),
            ),
            compact: true,
          ),
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
        color: color.withValues(alpha: 0.1),
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
            mainAxisExtent: 124,
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
