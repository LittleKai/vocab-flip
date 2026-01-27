import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Widget for inputting and displaying tags
class TagInput extends StatefulWidget {
  final List<String> tags;
  final List<String>? suggestions;
  final ValueChanged<List<String>> onTagsChanged;
  final int maxTags;
  final String hintText;

  const TagInput({
    super.key,
    required this.tags,
    this.suggestions,
    required this.onTagsChanged,
    this.maxTags = 10,
    this.hintText = 'Add tags...',
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.toLowerCase().trim();

    if (text.isEmpty || widget.suggestions == null) {
      setState(() {
        _filteredSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _filteredSuggestions = widget.suggestions!
          .where((s) => s.toLowerCase().contains(text))
          .where((s) => !widget.tags.contains(s))
          .take(5)
          .toList();
      _showSuggestions = _filteredSuggestions.isNotEmpty;
    });
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() => _showSuggestions = false);
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    if (widget.tags.contains(trimmed)) return;
    if (widget.tags.length >= widget.maxTags) return;

    widget.onTagsChanged([...widget.tags, trimmed]);
    _controller.clear();
    setState(() {
      _filteredSuggestions = [];
      _showSuggestions = false;
    });
  }

  void _removeTag(String tag) {
    widget.onTagsChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags display
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tag) {
              return Chip(
                label: Text('#$tag'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeTag(tag),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Input field
        if (widget.tags.length < widget.maxTags)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTag(_controller.text),
                  ),
                ),
                onSubmitted: _addTag,
              ),

              // Suggestions
              if (_showSuggestions) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _filteredSuggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text('#$suggestion'),
                        onTap: () => _addTag(suggestion),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),

        // Helper text
        if (widget.tags.length >= widget.maxTags)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Maximum ${widget.maxTags} tags allowed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ),
      ],
    );
  }
}

/// Simple tag display (read-only)
class TagList extends StatelessWidget {
  final List<String> tags;
  final int maxVisible;
  final VoidCallback? onMoreTap;

  const TagList({
    super.key,
    required this.tags,
    this.maxVisible = 5,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleTags = tags.take(maxVisible).toList();
    final hiddenCount = tags.length - maxVisible;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...visibleTags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#$tag',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          );
        }),
        if (hiddenCount > 0)
          GestureDetector(
            onTap: onMoreTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+$hiddenCount more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
