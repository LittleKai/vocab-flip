import 'package:flutter/material.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../data/models/category.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/deck_provider.dart';

/// Bottom sheet for filtering local deck list
class DeckFilterSheet extends StatefulWidget {
  final String? currentCategory;
  final String? currentLanguage;
  final DeckSortBy currentSortBy;
  final void Function(String? category, String? language, DeckSortBy sortBy) onApply;

  const DeckFilterSheet({
    super.key,
    required this.currentCategory,
    required this.currentLanguage,
    required this.currentSortBy,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required String? currentCategory,
    required String? currentLanguage,
    required DeckSortBy currentSortBy,
    required void Function(String? category, String? language, DeckSortBy sortBy) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DeckFilterSheet(
        currentCategory: currentCategory,
        currentLanguage: currentLanguage,
        currentSortBy: currentSortBy,
        onApply: onApply,
      ),
    );
  }

  @override
  State<DeckFilterSheet> createState() => _DeckFilterSheetState();
}

class _DeckFilterSheetState extends State<DeckFilterSheet> {
  late String? _categoryId;
  late String? _sourceLanguage;
  late DeckSortBy _sortBy;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.currentCategory;
    _sourceLanguage = widget.currentLanguage;
    _sortBy = widget.currentSortBy;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.filter,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: Text(l10n.reset),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Filter options
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Sort by
                  _buildSectionTitle(l10n.sortBy),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DeckSortBy.values.map((sort) {
                      return ChoiceChip(
                        label: Text(_getSortLabel(sort, l10n)),
                        selected: _sortBy == sort,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortBy = sort);
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Category
                  _buildSectionTitle(l10n.category),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.all),
                        selected: _categoryId == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _categoryId = null);
                          }
                        },
                      ),
                      ...Category.predefined.map((category) {
                        return ChoiceChip(
                          label: Text(category.getLocalizedName(locale)),
                          selected: _categoryId == category.id,
                          onSelected: (selected) {
                            setState(() {
                              _categoryId = selected ? category.id : null;
                            });
                          },
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Source language
                  _buildSectionTitle(l10n.sourceLanguage),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.all),
                        selected: _sourceLanguage == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sourceLanguage = null);
                          }
                        },
                      ),
                      ...SupportedLanguage.values.map((lang) {
                        return ChoiceChip(
                          label: Text('${lang.flag} ${lang.getName(locale)}'),
                          selected: _sourceLanguage == lang.code,
                          onSelected: (selected) {
                            setState(() {
                              _sourceLanguage = selected ? lang.code : null;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: Text(l10n.filter),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  String _getSortLabel(DeckSortBy sort, AppLocalizations l10n) {
    switch (sort) {
      case DeckSortBy.recentlyUpdated:
        return l10n.sortRecentlyUpdated;
      case DeckSortBy.nameAZ:
        return l10n.sortNameAZ;
      case DeckSortBy.nameZA:
        return l10n.sortNameZA;
      case DeckSortBy.mostCards:
        return l10n.sortMostCards;
      case DeckSortBy.mostDue:
        return l10n.sortMostDue;
      case DeckSortBy.oldest:
        return l10n.sortOldest;
    }
  }

  void _resetFilters() {
    setState(() {
      _categoryId = null;
      _sourceLanguage = null;
      _sortBy = DeckSortBy.recentlyUpdated;
    });
  }

  void _applyFilters() {
    widget.onApply(_categoryId, _sourceLanguage, _sortBy);
    Navigator.pop(context);
  }
}
