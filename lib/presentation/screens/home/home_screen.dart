import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/deck_provider.dart';
import '../../providers/settings_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeckProvider>().loadDecks();
      context.read<SettingsProvider>().loadSettings();
    });
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
    return Scaffold(
      body: _buildScreen(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Decks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public_outlined),
            activeIcon: Icon(Icons.public),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Dictionary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('VocabFlip'),
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
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning!';
    } else if (hour < 17) {
      greeting = 'Good afternoon!';
    } else {
      greeting = 'Good evening!';
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
            'Ready to learn some new words?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.1),
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
                '${settings.streak} day streak',
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
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.folder,
            label: 'Decks',
            value: '${deckProvider.totalDecks}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.style,
            label: 'Cards',
            value: '${deckProvider.totalCards}',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule,
            label: 'Due',
            value: '${deckProvider.totalDueCards}',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildDueTodaySection(BuildContext context, DeckProvider provider) {
    final dueDecks = provider.decks.where((d) => d.dueCount > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Today',
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
                  'All caught up!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'No cards to review today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          )
        else
          ...dueDecks.take(3).map((deck) => _DueDeckCard(deck: deck)),
      ],
    );
  }

  Widget _buildRecentDecks(BuildContext context, DeckProvider provider) {
    if (provider.decks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Decks',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...provider.decks.take(3).map((deck) => _RecentDeckCard(deck: deck)),
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
  final dynamic deck;

  const _DueDeckCard({required this.deck});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withOpacity(0.1),
          child: const Icon(Icons.schedule, color: AppColors.accent),
        ),
        title: Text(deck.name),
        subtitle: Text('${deck.dueCount} cards due'),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/study', arguments: deck.id);
          },
          child: const Text('Study'),
        ),
      ),
    );
  }
}

class _RecentDeckCard extends StatelessWidget {
  final dynamic deck;

  const _RecentDeckCard({required this.deck});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.folder, color: AppColors.primary),
        ),
        title: Text(deck.name),
        subtitle: Text('${deck.cardCount} cards'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(context, '/deck', arguments: deck.id);
        },
      ),
    );
  }
}
