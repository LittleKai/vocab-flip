import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/database/flashcard_dao.dart';

import 'package:vocabflip/l10n/app_localizations.dart';

class DeckPieChart extends StatelessWidget {
  final FlashcardDao _dao = FlashcardDao();

  DeckPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, int>>(
      future: _dao.getDeckBreakdown(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!;
        final newCards = data['new'] ?? 0;
        final learningCards = data['learning'] ?? 0;
        final matureCards = data['mature'] ?? 0;
        final total = newCards + learningCards + matureCards;

        if (total == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                l10n.noFlashcardsYet,
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cardMastery,
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
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: Colors.blueAccent,
                            value: newCards.toDouble(),
                            title: '',
                            radius: 20,
                          ),
                          PieChartSectionData(
                            color: Colors.orangeAccent,
                            value: learningCards.toDouble(),
                            title: '',
                            radius: 25,
                          ),
                          PieChartSectionData(
                            color: Colors.greenAccent,
                            value: matureCards.toDouble(),
                            title: '',
                            radius: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(l10n.newCards, newCards, Colors.blueAccent),
                        const SizedBox(height: 8),
                        _buildLegendItem(l10n.learningCards, learningCards, Colors.orangeAccent),
                        const SizedBox(height: 8),
                        _buildLegendItem(l10n.matureCards, matureCards, Colors.greenAccent),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(String title, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text('$title: $value', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
