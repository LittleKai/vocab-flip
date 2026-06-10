import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/deck.dart';
import '../../../data/repositories/study_analytics_repository.dart';
import '../../providers/deck_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/stats/study_heatmap.dart';
import '../../widgets/stats/deck_pie_chart.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stats),
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
                  _StatsHero(
                    deckProvider: deckProvider,
                    settingsProvider: settingsProvider,
                  ),
                  const SizedBox(height: 18),
                  _SummarySection(
                    deckProvider: deckProvider,
                    settingsProvider: settingsProvider,
                  ),
                  const SizedBox(height: 24),
                  StudyHeatmap(),
                  const SizedBox(height: 24),
                  _ProgressChart(repository: StudyAnalyticsRepository()),
                  const SizedBox(height: 24),
                  DeckPieChart(),
                  const SizedBox(height: 24),
                  _DeckBreakdown(decks: deckProvider.decks),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatsHero extends StatelessWidget {
  final DeckProvider deckProvider;
  final SettingsProvider settingsProvider;

  const _StatsHero({
    required this.deckProvider,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalCards = deckProvider.totalCards;
    final learned = deckProvider.decks.fold<int>(
      0,
      (sum, deck) => sum + (deck.cardCount - deck.newCount),
    );
    final progress = totalCards == 0 ? 0.0 : learned / totalCards;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondaryDark,
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 620;
          final headline = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.overview,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                settingsProvider.formattedStudyTime,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.studyTime,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentLight,
                  ),
                ),
              ),
            ],
          );

          final focus = Container(
            constraints: const BoxConstraints(minWidth: 180),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment:
                  isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                const Icon(Icons.insights, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  '${deckProvider.totalDueCards}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  l10n.due,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headline,
                const SizedBox(height: 18),
                focus,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: headline),
              const SizedBox(width: 20),
              focus,
            ],
          );
        },
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final DeckProvider deckProvider;
  final SettingsProvider settingsProvider;

  const _SummarySection({
    required this.deckProvider,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                label: l10n.streak,
                value: '${settingsProvider.streak}',
                unit: l10n.days,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.timer,
                label: l10n.studyTime,
                value: settingsProvider.formattedStudyTime,
                unit: l10n.total,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.folder,
                label: l10n.decks,
                value: '${deckProvider.totalDecks}',
                unit: l10n.created,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.style,
                label: l10n.cards,
                value: '${deckProvider.totalCards}',
                unit: l10n.total,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
          ),
          Text(
            '$label ($unit)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProgressChart extends StatelessWidget {
  final StudyAnalyticsRepository repository;

  const _ProgressChart({required this.repository});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<DailyStudyActivity>>(
      future: repository.getWeeklyActivity(),
      builder: (context, snapshot) {
        final rawData = snapshot.data ?? const <DailyStudyActivity>[];
        final data = rawData.isEmpty
            ? List<DailyStudyActivity>.generate(
                7,
                (index) => DailyStudyActivity(
                  day: DateTime.now().subtract(Duration(days: 6 - index)),
                  cardsStudied: 0,
                  cardsCorrect: 0,
                  cardsIncorrect: 0,
                  totalTimeSeconds: 0,
                ),
              )
            : rawData;

        final maxCards = data.fold<int>(
          0,
          (max, item) => item.cardsStudied > max ? item.cardsStudied : max,
        );
        final maxY = maxCards <= 0 ? 10.0 : (maxCards + 5).toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.weeklyActivity,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            _dayLabel(l10n, data[index].day.weekday),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color:
                          AppColors.textSecondaryLight.withValues(alpha: 0.12),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: _barGroups(data),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<BarChartGroupData> _barGroups(List<DailyStudyActivity> data) {
    return List.generate(data.length, (index) {
      final activity = data[index];
      final color = activity.cardsStudied == 0
          ? AppColors.primary.withValues(alpha: 0.25)
          : AppColors.primary;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: activity.cardsStudied.toDouble(),
            color: color,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }

  String _dayLabel(AppLocalizations l10n, int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return l10n.mon;
      case DateTime.tuesday:
        return l10n.tue;
      case DateTime.wednesday:
        return l10n.wed;
      case DateTime.thursday:
        return l10n.thu;
      case DateTime.friday:
        return l10n.fri;
      case DateTime.saturday:
        return l10n.sat;
      case DateTime.sunday:
      default:
        return l10n.sun;
    }
  }
}

class _DeckBreakdown extends StatelessWidget {
  final List<Deck> decks;

  const _DeckBreakdown({required this.decks});

  @override
  Widget build(BuildContext context) {
    if (decks.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.deckProgress,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        ...decks.map((deck) => _DeckProgressCard(deck: deck)),
      ],
    );
  }
}

class _DeckProgressCard extends StatelessWidget {
  final Deck deck;

  const _DeckProgressCard({required this.deck});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = deck.cardCount;
    final learned = total - deck.newCount;
    final progress = total > 0 ? learned / total : 0.0;
    final accent = deck.dueCount > 0 ? AppColors.accent : AppColors.secondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: deck.dueCount > 0 ? 2 : 0,
      color: accent.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.06,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    deck.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: accent.withValues(alpha: 0.16),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.cardsLearnedCount(learned, total),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (deck.dueCount > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    l10n.dueCount(deck.dueCount),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
