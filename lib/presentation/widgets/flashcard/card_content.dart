import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/flashcard.dart';

class CardContent extends StatelessWidget {
  final Flashcard flashcard;
  final bool showBack;
  final VoidCallback? onAudioPlay;

  const CardContent({
    super.key,
    required this.flashcard,
    this.showBack = false,
    this.onAudioPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Front content (always visible)
          _buildSection(
            context,
            label: 'Word',
            content: flashcard.front,
            phonetic: flashcard.frontPhonetic,
            isMain: true,
          ),

          if (showBack) ...[
            const Divider(height: 32),

            // Back content
            _buildSection(
              context,
              label: 'Meaning',
              content: flashcard.back,
              isMain: true,
            ),

            if (flashcard.example != null && flashcard.example!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSection(
                context,
                label: 'Example',
                content: flashcard.example!,
              ),
            ],

            if (flashcard.notes != null && flashcard.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSection(
                context,
                label: 'Notes',
                content: flashcard.notes!,
              ),
            ],
          ],

          if (flashcard.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: flashcard.tags.map((tag) => Chip(
                label: Text(tag),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ],

          const Spacer(),

          if (onAudioPlay != null)
            IconButton(
              onPressed: onAudioPlay,
              icon: const Icon(Icons.volume_up),
              iconSize: 32,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String label,
    required String content,
    String? phonetic,
    bool isMain = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          textAlign: TextAlign.center,
          style: isMain
              ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
        if (phonetic != null && phonetic.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            phonetic,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ],
    );
  }
}

class RatingButtons extends StatelessWidget {
  final Map<String, int> intervals;
  final ValueChanged<int> onRating;

  const RatingButtons({
    super.key,
    required this.intervals,
    required this.onRating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton(
          context,
          label: 'Again',
          interval: intervals['again'] ?? 1,
          color: AppColors.ratingAgain,
          quality: 0,
        ),
        _buildButton(
          context,
          label: 'Hard',
          interval: intervals['hard'] ?? 1,
          color: AppColors.ratingHard,
          quality: 3,
        ),
        _buildButton(
          context,
          label: 'Good',
          interval: intervals['good'] ?? 1,
          color: AppColors.ratingGood,
          quality: 4,
        ),
        _buildButton(
          context,
          label: 'Easy',
          interval: intervals['easy'] ?? 1,
          color: AppColors.ratingEasy,
          quality: 5,
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required int interval,
    required Color color,
    required int quality,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => onRating(quality),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _formatInterval(interval),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatInterval(int days) {
    if (days < 1) return '<1d';
    if (days == 1) return '1d';
    if (days < 30) return '${days}d';
    if (days < 365) return '${(days / 30).round()}mo';
    return '${(days / 365).round()}y';
  }
}
