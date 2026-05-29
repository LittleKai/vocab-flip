import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/deck.dart';
import '../common/deck_card_header.dart';

class DeckSummaryCard extends StatelessWidget {
  final Deck deck;
  final String cardCountLabel;
  final String? dueLabel;
  final String? studyLabel;
  final VoidCallback onTap;
  final VoidCallback? onStudy;
  final Widget? trailing;
  final bool compact;

  const DeckSummaryCard({
    super.key,
    required this.deck,
    required this.cardCountLabel,
    required this.onTap,
    this.dueLabel,
    this.studyLabel,
    this.onStudy,
    this.trailing,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final showStudyButton =
        onStudy != null && studyLabel != null && studyLabel!.isNotEmpty;
    final titleStyle = compact
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.titleMedium;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 8 : 10,
          ),
          child: Row(
            children: [
              DeckCardHeader.buildDeckImage(context, deck.imagePath),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deck.name,
                            style: titleStyle?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        DeckCardHeader.buildLanguageBadge(
                          context,
                          deck.sourceLanguage,
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Wrap(
                      spacing: compact ? 8 : 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DeckStatusChip(
                          icon: Icons.style,
                          label: cardCountLabel,
                          color: AppColors.info,
                        ),
                        if (dueLabel != null && dueLabel!.isNotEmpty)
                          DeckStatusChip(
                            icon: Icons.schedule,
                            label: dueLabel!,
                            color: AppColors.accent,
                            emphasized: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showStudyButton) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: compact ? 32 : 34,
                  child: ElevatedButton(
                    onPressed: onStudy,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 16,
                      ),
                      textStyle: TextStyle(fontSize: compact ? 13 : 14),
                    ),
                    child: Text(studyLabel!),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DeckStatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool emphasized;

  const DeckStatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: emphasized ? color : AppColors.textSecondary(context),
          fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: emphasized ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}
