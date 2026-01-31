import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../core/utils/romaji_converter.dart';
import '../../../data/models/dictionary_result.dart';
import '../../providers/dictionary_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/common/loading_widget.dart';

class DictionarySearchScreen extends StatefulWidget {
  const DictionarySearchScreen({super.key});

  @override
  State<DictionarySearchScreen> createState() => _DictionarySearchScreenState();
}

class _DictionarySearchScreenState extends State<DictionarySearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  int _resultLimit = 10;
  List<String> _kanjiSuggestions = [];
  bool _loadingKanji = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dictionary),
      ),
      body: Consumer<DictionaryProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search bar and options
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Language selector + conversion buttons + settings
                    Row(
                      children: [
                        // Language dropdown
                        DropdownButton<SupportedLanguage>(
                          value: provider.selectedLanguage,
                          underline: const SizedBox(),
                          isDense: true,
                          items: [
                            SupportedLanguage.english,
                            SupportedLanguage.japanese,
                            SupportedLanguage.chinese,
                          ].map((lang) {
                            return DropdownMenuItem(
                              value: lang,
                              child: Text(lang.nameEn, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (lang) {
                            if (lang != null) {
                              provider.setLanguage(lang);
                            }
                          },
                        ),

                        // Conversion buttons for Japanese
                        if (provider.selectedLanguage == SupportedLanguage.japanese) ...[
                          const SizedBox(width: 8),
                          _ConversionButton(
                            label: 'あ',
                            tooltip: 'Hiragana',
                            onPressed: _searchController.text.isNotEmpty
                                ? () => _convertToKana(toKatakana: false)
                                : null,
                          ),
                          const SizedBox(width: 4),
                          _ConversionButton(
                            label: 'ア',
                            tooltip: 'Katakana',
                            onPressed: _searchController.text.isNotEmpty
                                ? () => _convertToKana(toKatakana: true)
                                : null,
                          ),
                          const SizedBox(width: 4),
                          _ConversionButton(
                            label: '漢',
                            tooltip: 'Kanji',
                            isLoading: _loadingKanji,
                            onPressed: _searchController.text.isNotEmpty
                                ? () => _showKanjiSuggestions(context, provider, _resultLimit)
                                : null,
                          ),
                        ],

                        const Spacer(),

                        // Settings button with result count
                        InkWell(
                          onTap: () => _showSettingsDialog(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.textSecondaryLight),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune, size: 16),
                                const SizedBox(width: 4),
                                Text('$_resultLimit', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: l10n.searchForWord,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.clearResults();
                                  setState(() {
                                    _kanjiSuggestions = [];
                                  });
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _search(provider),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),

                    // Kanji suggestions
                    if (_kanjiSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _kanjiSuggestions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final kanji = _kanjiSuggestions[index];
                            return ActionChip(
                              label: Text(kanji, style: const TextStyle(fontSize: 16)),
                              onPressed: () {
                                _searchController.text = kanji;
                                _searchController.selection = TextSelection.collapsed(
                                  offset: kanji.length,
                                );
                                setState(() {
                                  _kanjiSuggestions = [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
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
                    label: Text(l10n.lookUp),
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

  /// Convert text to hiragana or katakana
  /// Supports: romaji → kana, hiragana ↔ katakana
  void _convertToKana({required bool toKatakana}) {
    final value = _searchController.text;
    if (value.isEmpty) return;

    final converted = RomajiConverter.convertToKana(value, toKatakana: toKatakana);
    if (converted != value) {
      _searchController.value = TextEditingValue(
        text: converted,
        selection: TextSelection.collapsed(offset: converted.length),
      );
      setState(() {});
    }
  }

  /// Show Kanji suggestions from dictionary search
  Future<void> _showKanjiSuggestions(BuildContext context, DictionaryProvider provider, int limit) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loadingKanji = true;
      _kanjiSuggestions = [];
    });

    try {
      // Search for kanji using Mazii API
      final results = await provider.searchKanjiSuggestions(query, limit: limit);
      setState(() {
        _kanjiSuggestions = results;
        _loadingKanji = false;
      });
    } catch (e) {
      setState(() {
        _loadingKanji = false;
      });
    }
  }

  /// Show settings dialog for dictionary options
  void _showSettingsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<DictionaryProvider>();

    showDialog(
      context: context,
      builder: (context) {
        int tempLimit = _resultLimit;
        String tempFilterMode = provider.filterMode;
        bool tempFallback = provider.fallbackToEnglish;

        return AlertDialog(
          title: Text(l10n.dictionarySettings),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Result limit
                    Text(l10n.resultLimit, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: tempLimit.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '$tempLimit',
                            onChanged: (value) {
                              setDialogState(() {
                                tempLimit = value.round();
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text('$tempLimit', textAlign: TextAlign.center),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Filter mode
                    Text(l10n.filterMode, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _FilterOption(
                      title: l10n.filterExactFirst,
                      subtitle: l10n.filterExactFirstDesc,
                      value: 'exact_first',
                      groupValue: tempFilterMode,
                      onChanged: (v) => setDialogState(() => tempFilterMode = v!),
                    ),
                    _FilterOption(
                      title: l10n.filterWithMeanings,
                      subtitle: l10n.filterWithMeaningsDesc,
                      value: 'with_meanings',
                      groupValue: tempFilterMode,
                      onChanged: (v) => setDialogState(() => tempFilterMode = v!),
                    ),
                    _FilterOption(
                      title: l10n.filterAll,
                      subtitle: l10n.filterAllDesc,
                      value: 'all',
                      groupValue: tempFilterMode,
                      onChanged: (v) => setDialogState(() => tempFilterMode = v!),
                    ),

                    const Divider(height: 24),

                    // Fallback to English
                    SwitchListTile(
                      title: Text(l10n.fallbackToEnglish),
                      subtitle: Text(l10n.fallbackToEnglishDesc),
                      value: tempFallback,
                      onChanged: (v) => setDialogState(() => tempFallback = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _resultLimit = tempLimit;
                });
                provider.setFilterMode(tempFilterMode);
                provider.setFallbackToEnglish(tempFallback);
                Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResults(BuildContext context, DictionaryProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    if (provider.isLoading) {
      return LoadingWidget(message: l10n.lookingUp);
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

    if (provider.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.enterWordToLookUp,
              style: const TextStyle(color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      );
    }

    // Display all results as a scrollable list
    final hasFallbackBanner = provider.usedFallback && provider.fallbackSource != null;
    final itemCount = provider.results.length + (hasFallbackBanner ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Show fallback notification banner as first item
        if (hasFallbackBanner && index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Không tìm được từ điển Việt. Đang hiển thị kết quả từ ${provider.fallbackSource}.',
                    style: const TextStyle(fontSize: 13, color: Colors.orange),
                  ),
                ),
              ],
            ),
          );
        }

        final resultIndex = hasFallbackBanner ? index - 1 : index;
        final result = provider.results[resultIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _DictionaryResultCard(
            result: result,
            resultIndex: resultIndex + 1,
            totalResults: provider.results.length,
            selectedLanguage: provider.selectedLanguage,
            onAddToDeck: () => _showAddToDeckDialog(context, result),
          ),
        );
      },
    );
  }

  void _showAddToDeckDialog(BuildContext context, DictionaryResult result) {
    final l10n = AppLocalizations.of(context)!;
    final deckProvider = context.read<DeckProvider>();
    final dictProvider = context.read<DictionaryProvider>();

    // Filter decks by source language
    final selectedLangCode = dictProvider.selectedLanguage.code;
    final filteredDecks = deckProvider.decks
        .where((deck) => deck.sourceLanguage == selectedLangCode)
        .toList();

    // Get first definition as back content
    String backContent = '';
    if (result.meanings.isNotEmpty) {
      final definitions = result.meanings
          .expand((m) => m.definitions)
          .map((d) => d.definition)
          .take(3)
          .toList();
      backContent = definitions.join('\n');
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addToDeck),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.front}: ${result.word}'),
              if (result.phonetic != null)
                Text('${l10n.phonetic}: ${result.phonetic}'),
              const SizedBox(height: 8),
              Text('${l10n.back}:'),
              Text(
                backContent,
                style: const TextStyle(fontSize: 12),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Text(l10n.selectDeck),
              if (filteredDecks.isEmpty && deckProvider.decks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'No ${dictProvider.selectedLanguage.nameEn} decks found',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            if (filteredDecks.isEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create-deck');
                },
                child: Text(l10n.createDeck),
              )
            else
              PopupMenuButton<String>(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.selectDeck,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                itemBuilder: (context) {
                  return filteredDecks.map((deck) {
                    return PopupMenuItem<String>(
                      value: deck.id,
                      child: Text(deck.name),
                    );
                  }).toList();
                },
                onSelected: (deckId) async {
                  Navigator.pop(context);
                  await _addFlashcardToDeck(
                    context,
                    deckId,
                    result,
                    backContent,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _addFlashcardToDeck(
    BuildContext context,
    String deckId,
    DictionaryResult result,
    String backContent,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final deckProvider = context.read<DeckProvider>();

    try {
      await deckProvider.addFlashcard(
        deckId: deckId,
        front: result.word,
        back: backContent,
        phonetic: result.phonetic,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.addedToDeck}: ${result.word}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Card displaying a single dictionary result with all attributes
class _DictionaryResultCard extends StatelessWidget {
  final DictionaryResult result;
  final int resultIndex;
  final int totalResults;
  final SupportedLanguage selectedLanguage;
  final VoidCallback? onAddToDeck;

  const _DictionaryResultCard({
    required this.result,
    required this.resultIndex,
    required this.totalResults,
    required this.selectedLanguage,
    this.onAddToDeck,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word header with Add button at top right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Result number badge
                      if (totalResults > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondaryLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$resultIndex / $totalResults',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                        ),
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
                    ],
                  ),
                ),
                // Add button at top right
                IconButton(
                  onPressed: onAddToDeck,
                  icon: const Icon(Icons.add_circle),
                  color: AppColors.primary,
                  tooltip: l10n.addToDeck,
                  iconSize: 32,
                ),
              ],
            ),

            const Divider(height: 24),

            // All meanings
            ...result.meanings.asMap().entries.map((entry) {
              final meaningIndex = entry.key;
              final meaning = entry.value;
              return _MeaningSection(
                meaning: meaning,
                isLast: meaningIndex == result.meanings.length - 1,
              );
            }),

            // Synonyms section (from all meanings)
            _buildSynonymsSection(context, l10n),

            // Antonyms section (from all meanings)
            _buildAntonymsSection(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSynonymsSection(BuildContext context, AppLocalizations l10n) {
    final allSynonyms = <String>{};
    for (final meaning in result.meanings) {
      allSynonyms.addAll(meaning.synonyms);
    }
    if (allSynonyms.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                l10n.synonyms,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allSynonyms.take(10).map((syn) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Text(syn, style: const TextStyle(fontSize: 12, color: Colors.green)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAntonymsSection(BuildContext context, AppLocalizations l10n) {
    final allAntonyms = <String>{};
    for (final meaning in result.meanings) {
      allAntonyms.addAll(meaning.antonyms);
    }
    if (allAntonyms.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                l10n.antonyms,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allAntonyms.take(10).map((ant) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Text(ant, style: const TextStyle(fontSize: 12, color: Colors.orange)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Section for each meaning (part of speech + definitions)
class _MeaningSection extends StatelessWidget {
  final DictionaryMeaning meaning;
  final bool isLast;

  const _MeaningSection({
    required this.meaning,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Part of speech
        if (meaning.partOfSpeech.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              meaning.partOfSpeech,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),

        // Definitions
        ...meaning.definitions.asMap().entries.map((entry) {
          final index = entry.key;
          final definition = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
                      style: const TextStyle(
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
          const SizedBox(height: 8),
          Text(
            l10n.synonyms,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: meaning.synonyms.take(5).map((syn) {
              return Chip(
                label: Text(syn, style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ],

        if (!isLast) const SizedBox(height: 12),
      ],
    );
  }
}

/// Compact button for kana/kanji conversion
class _ConversionButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ConversionButton({
    required this.label,
    required this.tooltip,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onPressed != null
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onPressed != null
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Radio option for filter mode selection
class _FilterOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _FilterOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
