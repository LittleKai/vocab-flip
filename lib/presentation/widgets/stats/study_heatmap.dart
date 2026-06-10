import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/database/study_analytics_dao.dart';

import 'package:vocabflip/l10n/app_localizations.dart';

class StudyHeatmap extends StatefulWidget {
  const StudyHeatmap({super.key});

  @override
  State<StudyHeatmap> createState() => _StudyHeatmapState();
}

class _StudyHeatmapState extends State<StudyHeatmap> {
  final StudyAnalyticsDao _dao = StudyAnalyticsDao();
  late Future<Map<DateTime, int>> _heatmapFuture;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    // Show 1 year (365 days) so it fully populates large screens
    // and allows horizontal scroll on mobile devices.
    _startDate = _endDate.subtract(const Duration(days: 364));
    _heatmapFuture = _dao.getHeatmapData(_startDate);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<DateTime, int>>(
      future: _heatmapFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
              height: 220, child: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.studyHeatmap,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildHeatmapGrid(context, data, _startDate, _endDate),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeatmapGrid(BuildContext context, Map<DateTime, int> data, DateTime start, DateTime end) {
    // Align start to the nearest sunday or monday depending on locale, for simplicity we just make a flat list of items
    // Since we have 70 days, we can arrange them in columns of 7.
    List<Widget> columns = [];
    
    // Normalize start and end
    var current = DateTime(start.year, start.month, start.day);
    // Align to Sunday
    while (current.weekday != DateTime.sunday) {
      current = DateTime(current.year, current.month, current.day - 1);
    }

    final endDay = DateTime(end.year, end.month, end.day);
    
    List<Widget> currentColumn = [];
    
    while (current.isBefore(endDay) || current.isAtSameMomentAs(endDay)) {
      final val = data[current] ?? 0;
      currentColumn.add(_buildSquare(val));
      
      if (current.weekday == DateTime.saturday) {
        columns.add(Column(mainAxisSize: MainAxisSize.min, children: currentColumn));
        currentColumn = [];
      }
      current = DateTime(current.year, current.month, current.day + 1);
    }
    
    if (currentColumn.isNotEmpty) {
      columns.add(Column(mainAxisSize: MainAxisSize.min, children: currentColumn));
    }

    return Align(
      alignment: Alignment.centerRight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true, // Auto scroll to the right (latest)
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columns.map((col) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: col,
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildSquare(int count) {
    Color color;
    if (count == 0) {
      color = AppColors.textSecondaryLight.withOpacity(0.1);
    } else if (count < 10) {
      color = AppColors.primary.withOpacity(0.2);
    } else if (count < 30) {
      color = AppColors.primary.withOpacity(0.4);
    } else if (count < 60) {
      color = AppColors.primary.withOpacity(0.7);
    } else {
      color = AppColors.primary;
    }

    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
