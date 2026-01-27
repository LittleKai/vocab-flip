import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/deck.dart';
import '../../providers/publish_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/library/tag_input.dart';

/// Screen for publishing a deck to the public library
class PublishDeckScreen extends StatefulWidget {
  final String deckId;

  const PublishDeckScreen({
    super.key,
    required this.deckId,
  });

  @override
  State<PublishDeckScreen> createState() => _PublishDeckScreenState();
}

class _PublishDeckScreenState extends State<PublishDeckScreen> {
  Deck? _deck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublishProvider>().initialize();
      _loadDeck();
    });
  }

  Future<void> _loadDeck() async {
    final deck = await context.read<DeckProvider>().getDeckById(widget.deckId);
    if (mounted) {
      setState(() => _deck = deck);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish Deck'),
      ),
      body: Consumer<PublishProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_deck == null) {
            return const Center(child: Text('Deck not found'));
          }

          return _buildForm(context, provider);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, PublishProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deck info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _deck!.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_deck!.description != null &&
                      _deck!.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_deck!.description!),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.style, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(
                        '${_deck!.cardCount} cards',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.translate, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(
                        '${_deck!.sourceLanguage.toUpperCase()} → ${_deck!.targetLanguage.toUpperCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Category selection
          Text(
            'Category *',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: provider.selectedCategoryId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select a category',
            ),
            items: provider.categories.map<DropdownMenuItem<String>>((category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) => provider.setCategory(value),
            validator: (value) =>
                value == null ? 'Please select a category' : null,
          ),

          const SizedBox(height: 24),

          // Tags
          Text(
            'Tags',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add tags to help users find your deck',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 12),
          TagInput(
            tags: provider.selectedTags,
            suggestions: _getTagSuggestions(),
            onTagsChanged: (tags) {
              provider.clearTags();
              for (final tag in tags) {
                provider.addTag(tag);
              }
            },
          ),

          const SizedBox(height: 24),

          // Guidelines
          Card(
            color: AppColors.primary.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Publishing Guidelines',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuideline('Make sure your deck has quality content'),
                  _buildGuideline('Use appropriate categories and tags'),
                  _buildGuideline('Avoid copyrighted material'),
                  _buildGuideline('You can update or unpublish anytime'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Error message
          if (provider.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Publish button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.isPublishing
                  ? null
                  : () => _publishDeck(context, provider),
              child: provider.isPublishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publish to Library'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: AppColors.primary)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getTagSuggestions() {
    return [
      'beginner',
      'intermediate',
      'advanced',
      'vocabulary',
      'grammar',
      'speaking',
      'listening',
      'reading',
      'writing',
      'exam prep',
      'conversation',
      'business',
      'travel',
      'academic',
    ];
  }

  Future<void> _publishDeck(BuildContext context, PublishProvider provider) async {
    final success = await provider.publishDeck(widget.deckId);

    if (success && mounted) {
      // Refresh local deck to update isPublished status
      context.read<DeckProvider>().loadDecks();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck published successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    }
  }
}
