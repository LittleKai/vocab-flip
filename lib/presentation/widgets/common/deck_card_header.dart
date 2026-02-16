import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Shared header widget for deck cards (used by both DeckCard and PublicDeckCard).
/// Displays: [Image 56x56] [Name + chips + lang badges] [trailing]
///           [subtitle]
///           [description]
class DeckCardHeader extends StatelessWidget {
  final String name;
  final String? description;
  final String? imagePath;
  final String frontFieldsLabel;
  final String backFieldsLabel;
  final String sourceLanguage;
  final String targetLanguage;
  final Widget? trailing;
  final Widget? subtitle;
  final bool reverseFieldOrder;

  const DeckCardHeader({
    super.key,
    required this.name,
    this.description,
    this.imagePath,
    required this.frontFieldsLabel,
    required this.backFieldsLabel,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.trailing,
    this.subtitle,
    this.reverseFieldOrder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildDeckImage(context, imagePath),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Name
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Row 2: front/back chips + language badges (wrap on narrow screens)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (!reverseFieldOrder) ...[
                    buildMiniChip(context, Icons.flip_to_front, frontFieldsLabel, AppColors.primary),
                    buildMiniChip(context, Icons.flip_to_back, backFieldsLabel, AppColors.secondary),
                  ] else ...[
                    buildMiniChip(context, Icons.flip_to_back, backFieldsLabel, AppColors.secondary),
                    buildMiniChip(context, Icons.flip_to_front, frontFieldsLabel, AppColors.primary),
                  ],
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildLanguageBadge(context, sourceLanguage),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                        ),
                        buildLanguageBadge(context, targetLanguage),
                      ],
                    ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                subtitle!,
              ],
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }

  static Widget buildLanguageBadge(BuildContext context, String langCode) {
    final color = getLanguageColor(langCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        langCode.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // --- Static helpers shared across widgets ---

  static Widget buildMiniChip(BuildContext context, IconData icon, String text, Color color) {
    if (Platform.isAndroid) {
      return Tooltip(
        message: text,
        child: Icon(icon, size: 15, color: color),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: color,
              ),
        ),
      ],
    );
  }

  static Widget buildDeckImage(BuildContext context, String? imagePath) {
    Widget fallback = Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Icon(Icons.style, color: AppColors.primary, size: 28),
    );

    Widget imageWidget;
    if (imagePath == null || imagePath.isEmpty) {
      imageWidget = fallback;
    } else if (imagePath.startsWith('http')) {
      imageWidget = Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      final file = File(imagePath);
      imageWidget = file.existsSync()
          ? Image.file(file, fit: BoxFit.cover)
          : fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageWidget,
      ),
    );
  }

  static Color getLanguageColor(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'en':
        return AppColors.englishBadge;
      case 'ja':
        return AppColors.japaneseBadge;
      case 'zh':
        return AppColors.chineseBadge;
      case 'vi':
        return AppColors.vietnameseBadge;
      default:
        return AppColors.primary;
    }
  }
}
