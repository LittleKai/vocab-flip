import 'dart:math' show min;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/deck_navigation.dart';
import '../../../data/models/deck.dart';
import '../../providers/deck_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/update_provider.dart';
import '../../widgets/dialogs/update_dialog.dart';
import '../../widgets/common/responsive_grid.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import '../../widgets/stats/study_heatmap.dart';
import '../../widgets/deck/deck_summary_card.dart';
import '../../widgets/common/deck_card_header.dart';
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
      UpdateDialog.show(
        context,
        version: updateProvider.availableUpdate!,
        isMandatory: updateProvider.availableUpdate!.isMandatory,
      );
    }
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0:
        return AppColors.primary; // Home - Indigo
      case 1:
        return const Color(0xFFF59E0B); // Decks - Amber
      case 2:
        return AppColors.success; // Library - Green
      case 3:
        return const Color(0xFF8B5CF6); // Dictionary - Purple
      case 4:
        return const Color(0xFFEC4899); // Stats - Pink
      case 5:
        return const Color(0xFF64748B); // Settings - BlueGrey
      default:
        return AppColors.primary;
    }
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return _HomeTab(
          onSeeAllDecks: () => setState(() => _currentIndex = 1),
        );
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
        return _HomeTab(
          onSeeAllDecks: () => setState(() => _currentIndex = 1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 450;
    
    final navBarHeight = isNarrow ? 62.0 : 70.0;
    final iconSize = isNarrow ? 22.0 : 26.0;
    final double fontSize = isNarrow ? 9.5 : 12.0;

    return Scaffold(
      extendBody: true,
      body: _buildScreen(_currentIndex),
      bottomNavigationBar: CurvedNavigationBar(
        height: navBarHeight,
        index: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        color: Color.lerp(
          Theme.of(context).colorScheme.surface,
          _getTabColor(_currentIndex),
          Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.06,
        )!,
        buttonBackgroundColor: _getTabColor(_currentIndex),
        animationCurve: Curves.easeOutQuart,
        animationDuration: const Duration(milliseconds: 300),
        items: [
          CurvedNavigationBarItem(
            child: Icon(
              _currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
              color: _currentIndex == 0 ? Colors.white : _getTabColor(0),
              size: iconSize,
            ),
            label: l10n.home.toUpperCase(),
            labelStyle: TextStyle(
              color: _currentIndex == 0 ? _getTabColor(0) : AppColors.textSecondary(context),
              fontSize: fontSize,
              fontWeight: _currentIndex == 0 ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              _currentIndex == 1 ? Icons.folder_rounded : Icons.folder_outlined,
              color: _currentIndex == 1 ? Colors.white : _getTabColor(1),
              size: iconSize,
            ),
            label: l10n.decks.toUpperCase(),
            labelStyle: TextStyle(
              color: _currentIndex == 1 ? _getTabColor(1) : AppColors.textSecondary(context),
              fontSize: fontSize,
              fontWeight: _currentIndex == 1 ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              _currentIndex == 2 ? Icons.public_rounded : Icons.public_outlined,
              color: _currentIndex == 2 ? Colors.white : _getTabColor(2),
              size: iconSize,
            ),
            label: l10n.library.toUpperCase(),
            labelStyle: TextStyle(
              color: _currentIndex == 2 ? _getTabColor(2) : AppColors.textSecondary(context),
              fontSize: fontSize,
              fontWeight: _currentIndex == 2 ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              _currentIndex == 3 ? Icons.search_rounded : Icons.search_outlined,
              color: _currentIndex == 3 ? Colors.white : _getTabColor(3),
              size: iconSize,
            ),
            label: l10n.dictionary.toUpperCase(),
            labelStyle: TextStyle(
              color: _currentIndex == 3 ? _getTabColor(3) : AppColors.textSecondary(context),
              fontSize: fontSize,
              fontWeight: _currentIndex == 3 ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              _currentIndex == 4 ? Icons.bar_chart_rounded : Icons.bar_chart_outlined,
              color: _currentIndex == 4 ? Colors.white : _getTabColor(4),
              size: iconSize,
            ),
            label: l10n.stats.toUpperCase(),
            labelStyle: TextStyle(
              color: _currentIndex == 4 ? _getTabColor(4) : AppColors.textSecondary(context),
              fontSize: fontSize,
              fontWeight: _currentIndex == 4 ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              _currentIndex == 5 ? Icons.settings_rounded : Icons.settings_outlined,
              color: _currentIndex == 5 ? Colors.white : _getTabColor(5),
              size: iconSize,
            ),
            label: l10n.settings.toUpperCase(),
            labelStyle: TextStyle(
              color: _currentIndex == 5 ? _getTabColor(5) : AppColors.textSecondary(context),
              fontSize: fontSize,
              fontWeight: _currentIndex == 5 ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home Tab - redesigned with CustomScrollView
// ---------------------------------------------------------------------------

class _HomeTab extends StatelessWidget {
  final VoidCallback? onSeeAllDecks;

  const _HomeTab({this.onSeeAllDecks});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DeckProvider, SettingsProvider>(
      builder: (context, deckProvider, settingsProvider, child) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Greeting header
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildHeaderRow(context, settingsProvider),
                ),
              ),
            ),
            // Hero card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildHeroCard(context, deckProvider),
              ),
            ),
            // Quick stats (2 + 1 asymmetric)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _buildQuickStats(context, deckProvider),
              ),
            ),
            // Study heatmap
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: StudyHeatmap(),
              ),
            ),
            // Due today (horizontal scroll - handles its own horizontal padding)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: _buildDueTodaySection(context, deckProvider),
              ),
            ),
            // Recent decks (vertical list)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
                child: _buildRecentDecks(context, deckProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  // -- Header: greeting + streak chip ------------------------------------

  Widget _buildHeaderRow(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.goodMorning
        : hour < 17
            ? l10n.goodAfternoon
            : l10n.goodEvening;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.readyToLearn,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
              ),
            ],
          ),
        ),
        _HeroMetricChip(
          icon: Icons.local_fire_department_rounded,
          label: l10n.dayStreak(settings.streak),
          color: AppColors.accent,
          bgColor: AppColors.accent.withValues(alpha: 0.12),
        ),
      ],
    );
  }

  // -- Hero card: gradient + decorative depth circles --------------------

  Widget _buildHeroCard(BuildContext context, DeckProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final dueDecks =
        provider.decks.where((deck) => deck.dueCount > 0).toList();
    final primaryDeck = dueDecks.isNotEmpty ? dueDecks.first : null;
    final hasDue = provider.totalDueCards > 0 && primaryDeck != null;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1, -0.8),
          end: Alignment(1, 0.8),
          colors: [
            Color(0xFF4C1D95), // Deep Purple 900
            Color(0xFF7C3AED), // Violet 600
            Color(0xFFEC4899), // Pink 500
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles for depth
          Positioned(
            top: -30,
            right: -20,
            child: _circle(120, 0.08),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: _circle(150, 0.05),
          ),
          Positioned(
            top: 50,
            right: 70,
            child: _circle(44, 0.07),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        hasDue
                            ? Icons.auto_stories_rounded
                            : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    if (hasDue)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 160),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          primaryDeck.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  hasDue ? '${provider.totalDueCards}' : '0',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasDue
                      ? l10n.cardsDue(provider.totalDueCards)
                      : l10n.allCaughtUp,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (hasDue) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => DeckNavigation.navigateToStudy(
                          context, primaryDeck.id),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(
                        l10n.startStudy,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7C3AED), // Violet match
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  // -- Quick stats: 2-column + full-width due banner ---------------------

  Widget _buildQuickStats(BuildContext context, DeckProvider deckProvider) {
    final l10n = AppLocalizations.of(context)!;
    final hasDue = deckProvider.totalDueCards > 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.folder_rounded,
                label: l10n.decks,
                value: '${deckProvider.totalDecks}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.style_rounded,
                label: l10n.cards,
                value: '${deckProvider.totalCards}',
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Full-width due banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: hasDue
                ? AppColors.accent.withValues(alpha: 0.10)
                : AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasDue
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.success.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (hasDue ? AppColors.accent : AppColors.success)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasDue
                      ? Icons.schedule_rounded
                      : Icons.check_circle_rounded,
                  color: hasDue ? AppColors.accent : AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${deckProvider.totalDueCards}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color:
                          hasDue ? AppColors.accentDark : AppColors.success,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.due,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(context),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -- Due today: horizontal scrollable cards ----------------------------

  Widget _buildDueTodaySection(BuildContext context, DeckProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final dueDecks =
        provider.decks.where((d) => d.dueCount > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dueToday,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              if (dueDecks.length > 3 && onSeeAllDecks != null)
                TextButton(
                  onPressed: onSeeAllDecks,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: Text(l10n.seeAll),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (dueDecks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildEmptyDueState(context),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: min(dueDecks.length, 8),
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final deck = dueDecks[index];
                return _DueDeckCard(
                  deck: deck,
                  dueLabel: l10n.cardsDue(deck.dueCount),
                  studyLabel: l10n.study,
                  onStudy: () =>
                      DeckNavigation.navigateToStudy(context, deck.id),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyDueState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.allCaughtUp,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.noCardsToReviewToday,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
          ),
        ],
      ),
    );
  }

  // -- Recent decks: vertical card list ----------------------------------

  Widget _buildRecentDecks(BuildContext context, DeckProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    if (provider.decks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentDecks,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            if (onSeeAllDecks != null)
              TextButton(
                onPressed: onSeeAllDecks,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: Text(l10n.seeAll),
              ),
          ],
        ),
        const SizedBox(height: 16),
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

// ---------------------------------------------------------------------------
// Stat card (horizontal layout: icon left, value + label right)
// ---------------------------------------------------------------------------

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
        color: color.withValues(alpha: 0.04), // Tinted background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak / metric chip (pill)
// ---------------------------------------------------------------------------

class _HeroMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? bgColor;

  const _HeroMetricChip({
    required this.icon,
    required this.label,
    required this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Due deck card (compact, used in horizontal scroll)
// ---------------------------------------------------------------------------

class _DueDeckCard extends StatelessWidget {
  final Deck deck;
  final String dueLabel;
  final String studyLabel;
  final VoidCallback onStudy;

  const _DueDeckCard({
    required this.deck,
    required this.dueLabel,
    required this.studyLabel,
    required this.onStudy,
  });

  @override
  Widget build(BuildContext context) {
    final langColor = DeckCardHeader.getLanguageColor(deck.sourceLanguage);

    return GestureDetector(
      onTap: onStudy,
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: langColor.withValues(alpha: 0.03), // Subtle lang tint
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: langColor.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: langColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DeckCardHeader.buildDeckImage(
                  context,
                  deck.imagePath,
                  size: 40,
                ),
                const Spacer(),
                DeckCardHeader.buildLanguageBadge(
                    context, deck.sourceLanguage),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              deck.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            DeckStatusChip(
              icon: Icons.schedule,
              label: dueLabel,
              color: AppColors.accent,
              emphasized: true,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton.icon(
                onPressed: onStudy,
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(studyLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Responsive card list (used by Recent Decks)
// ---------------------------------------------------------------------------

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
            mainAxisExtent: 140,
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
