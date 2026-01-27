import 'package:flutter/material.dart' hide Category;
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../data/models/category.dart';
import '../../../data/remote/firebase/public_library_service.dart';

/// Bottom sheet for filtering library results
class FilterSheet extends StatefulWidget {
  final LibraryFilter currentFilter;
  final List<Category> categories;
  final ValueChanged<LibraryFilter> onApply;

  const FilterSheet({
    super.key,
    required this.currentFilter,
    required this.categories,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required LibraryFilter currentFilter,
    required List<Category> categories,
    required ValueChanged<LibraryFilter> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterSheet(
        currentFilter: currentFilter,
        categories: categories,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String? _categoryId;
  late String? _sourceLanguage;
  late String? _targetLanguage;
  late LibrarySortBy _sortBy;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.currentFilter.categoryId;
    _sourceLanguage = widget.currentFilter.sourceLanguage;
    _targetLanguage = widget.currentFilter.targetLanguage;
    _sortBy = widget.currentFilter.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
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
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset'),
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
                  _buildSectionTitle('Sort by'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LibrarySortBy.values.map((sort) {
                      return ChoiceChip(
                        label: Text(_getSortLabel(sort)),
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
                  _buildSectionTitle('Category'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _categoryId == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _categoryId = null);
                          }
                        },
                      ),
                      ...widget.categories.map((category) {
                        return ChoiceChip(
                          label: Text(category.name),
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
                  _buildSectionTitle('Source Language'),
                  const SizedBox(height: 8),
                  _buildLanguageDropdown(
                    value: _sourceLanguage,
                    onChanged: (value) {
                      setState(() => _sourceLanguage = value);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Target language
                  _buildSectionTitle('Target Language'),
                  const SizedBox(height: 8),
                  _buildLanguageDropdown(
                    value: _targetLanguage,
                    onChanged: (value) {
                      setState(() => _targetLanguage = value);
                    },
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
                  child: const Text('Apply Filters'),
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

  Widget _buildLanguageDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('All languages'),
        ),
        ...SupportedLanguage.values.map((lang) {
          return DropdownMenuItem(
            value: lang.code,
            child: Row(
              children: [
                Text(lang.flag),
                const SizedBox(width: 8),
                Text(lang.nativeName),
              ],
            ),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }

  String _getSortLabel(LibrarySortBy sort) {
    switch (sort) {
      case LibrarySortBy.popular:
        return 'Most Popular';
      case LibrarySortBy.rating:
        return 'Highest Rated';
      case LibrarySortBy.newest:
        return 'Newest';
      case LibrarySortBy.updated:
        return 'Recently Updated';
    }
  }

  void _resetFilters() {
    setState(() {
      _categoryId = null;
      _sourceLanguage = null;
      _targetLanguage = null;
      _sortBy = LibrarySortBy.popular;
    });
  }

  void _applyFilters() {
    widget.onApply(LibraryFilter(
      categoryId: _categoryId,
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
      sortBy: _sortBy,
    ));
    Navigator.pop(context);
  }
}
