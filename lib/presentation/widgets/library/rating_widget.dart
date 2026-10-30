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
