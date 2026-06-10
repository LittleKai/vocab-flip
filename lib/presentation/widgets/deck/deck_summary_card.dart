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
    final hasDue =
        dueLabel != null && dueLabel!.isNotEmpty && deck.dueCount > 0;
    final progress = deck.cardCount == 0
        ? 0.0
        : (1.0 - (deck.dueCount / deck.cardCount)).clamp(0.0, 1.0);
    final titleStyle = compact
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.titleMedium;
    final accentColor = hasDue ? AppColors.accent : AppColors.primary;
    final surfaceTint = Theme.of(context).brightness == Brightness.dark
        ? accentColor.withValues(alpha: hasDue ? 0.14 : 0.08)
        : accentColor.withValues(alpha: hasDue ? 0.09 : 0.04);

    return Card(
      elevation: hasDue ? 2 : 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceTint,
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: compact ? 108 : 124,
                color: accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 14,
                    vertical: compact ? 10 : 12,
                  ),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: DeckCardHeader.buildDeckImage(
                            context,
                            deck.imagePath,
                          ),
                        ),
                      ),
                      SizedBox(width: compact ? 12 : 14),
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
                                      fontWeight: FontWeight.w800,
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
                            SizedBox(height: compact ? 7 : 9),
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
                            if (hasDue) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor:
                                      accentColor.withValues(alpha: 0.16),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (showStudyButton) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: compact ? 36 : 38,
                          child: ElevatedButton.icon(
                            onPressed: onStudy,
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 18,
                            ),
                            label: Text(studyLabel!),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 12 : 16,
                              ),
                              textStyle: TextStyle(fontSize: compact ? 13 : 14),
                            ),
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
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
        );

    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized ? color.withValues(alpha: 0.13) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              emphasized ? color.withValues(alpha: 0.20) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
