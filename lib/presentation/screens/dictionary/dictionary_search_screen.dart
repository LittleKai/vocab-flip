import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../data/models/dictionary_result.dart';
import '../../providers/dictionary_provider.dart';
import '../../widgets/common/loading_widget.dart';

class DictionarySearchScreen extends StatefulWidget {
  const DictionarySearchScreen({super.key});

  @override
  State<DictionarySearchScreen> createState() => _DictionarySearchScreenState();
}

class _DictionarySearchScreenState extends State<DictionarySearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictionary'),
      ),
      body: Consumer<DictionaryProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Language selector
                    Row(
                      children: [
                        const Text('Source Language:'),
                        const SizedBox(width: 12),
                        DropdownButton<SupportedLanguage>(
                          value: provider.selectedLanguage,
                          items: [
                            SupportedLanguage.english,
                            SupportedLanguage.japanese,
                            SupportedLanguage.chinese,
                          ].map((lang) {
                            return DropdownMenuItem(
                              value: lang,
                              child: Text(lang.nameEn),
                            );
                          }).toList(),
                          onChanged: (lang) {
                            if (lang != null) {
                              provider.setLanguage(lang);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Search for a word...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.clearResults();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _search(provider),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),

              // Search button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : () => _search(provider),
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Look Up'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Results
              Expanded(
                child: _buildResults(context, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  void _search(DictionaryProvider provider) {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      provider.lookup(query);
      _focusNode.unfocus();
    }
  }

  Widget _buildResults(BuildContext context, DictionaryProvider provider) {
    if (provider.isLoading) {
      return const LoadingWidget(message: 'Looking up...');
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: AppColors.primary.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter a word to look up',
              style: TextStyle(color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      );
    }

    return _DictionaryResultView(result: provider.result!);
  }
}

class _DictionaryResultView extends StatelessWidget {
  final DictionaryResult result;

  const _DictionaryResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.word,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (result.phonetic != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.phonetic!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (result.audioUrl != null)
                        IconButton(
                          onPressed: () {
                            // TODO: Play audio
                          },
                          icon: const Icon(Icons.volume_up),
                          color: AppColors.primary,
                        ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Add to deck
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add to Deck'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Meanings
          ...result.meanings.map((meaning) => _MeaningCard(meaning: meaning)),
        ],
      ),
    );
  }
}

class _MeaningCard extends StatelessWidget {
  final DictionaryMeaning meaning;

  const _MeaningCard({required this.meaning});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Part of speech
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                meaning.partOfSpeech,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Definitions
            ...meaning.definitions.asMap().entries.map((entry) {
              final index = entry.key;
              final definition = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(definition.definition),
                        ),
                      ],
                    ),
                    if (definition.example != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          '"${definition.example}"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            // Synonyms
            if (meaning.synonyms.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Synonyms',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: meaning.synonyms.take(10).map((syn) {
                  return Chip(
                    label: Text(syn),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
