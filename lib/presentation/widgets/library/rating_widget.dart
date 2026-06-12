import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

/// Widget for displaying and selecting star ratings
class RatingWidget extends StatelessWidget {
  final double rating;
  final int? ratingCount;
  final bool readOnly;
  final double size;
  final ValueChanged<double>? onRatingChanged;

  const RatingWidget({
    super.key,
    required this.rating,
    this.ratingCount,
    this.readOnly = true,
    this.size = 20,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBar.builder(
          initialRating: rating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: readOnly,
          itemCount: 5,
          itemSize: size,
          ignoreGestures: readOnly,
          itemPadding: const EdgeInsets.symmetric(horizontal: 1),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          unratedColor: Colors.grey.shade300,
          onRatingUpdate: onRatingChanged ?? (_) {},
        ),
        if (ratingCount != null) ...[
          const SizedBox(width: 8),
          Text(
            '($ratingCount)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ],
    );
  }
}

/// Large rating display with average and count
class RatingSummary extends StatelessWidget {
  final double averageRating;
  final int ratingCount;
  final Map<int, int>? distribution;

  const RatingSummary({
    super.key,
    required this.averageRating,
    required this.ratingCount,
    this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average rating
        Column(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            RatingWidget(
              rating: averageRating,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.reviewsCount(ratingCount),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),

        // Distribution bars
        if (distribution != null) ...[
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = distribution![star] ?? 0;
                final percentage = ratingCount > 0 ? count / ratingCount : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.amber,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$count',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

/// Dialog for submitting a rating with optional review
class RatingDialog extends StatefulWidget {
  final double? initialRating;
  final String? initialReview;
  final ValueChanged<({int rating, String? review})> onSubmit;

  const RatingDialog({
    super.key,
    this.initialRating,
    this.initialReview,
    required this.onSubmit,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double _rating;
  late TextEditingController _reviewController;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _reviewController = TextEditingController(text: widget.initialReview);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingWidget(
          rating: _rating,
          readOnly: false,
          size: 36,
          onRatingChanged: (value) {
            setState(() => _rating = value);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _reviewController,
          decoration: InputDecoration(
            labelText: l10n.reviewOptional,
            hintText: l10n.shareThoughts,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          maxLength: 500,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _rating > 0
                  ? () {
                      widget.onSubmit((
                        rating: _rating.round(),
                        review: _reviewController.text.isNotEmpty
                            ? _reviewController.text
                            : null,
                      ));
                      Navigator.pop(context);
                    }
                  : null,
              child: Text(l10n.submit),
            ),
          ],
        ),
      ],
    );
  }
}
