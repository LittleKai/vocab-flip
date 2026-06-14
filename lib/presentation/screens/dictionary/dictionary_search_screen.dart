// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/dialogs/standard_dialog.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../core/utils/romaji_converter.dart';
import '../../../data/models/dictionary_result.dart';
import '../../../data/models/stroke_character.dart';
import '../../../data/local/database/stroke_data_dao.dart';
import '../../../data/repositories/stroke_data_repository.dart';
import '../../../data/services/tts_service.dart';
import '../../providers/dictionary_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/stroke/stroke_order_animation.dart';

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
    final isNarrow = MediaQuery.of(context).size.width < 450;

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
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Language selector + conversion buttons + settings
                      Row(
                        children: [
                          if (!isNarrow) ...[
                            Text('${l10n.dictionary}: ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondaryLight)),
                            const SizedBox(width: 4),
                          ],
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
                              String getLangName(SupportedLanguage l) {
                                switch (l) {
                                  case SupportedLanguage.english:
                                    return l10n.english;
                                  case SupportedLanguage.japanese:
                                    return l10n.japanese;
                                  case SupportedLanguage.chinese:
                                    return l10n.chinese;
                                  case SupportedLanguage.vietnamese:
                                    return l10n.vietnamese;
                                }
                              }

                              return DropdownMenuItem(
                                value: lang,
                                child: Text(getLangName(lang),
                                    style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (lang) {
                              if (lang != null) {
                                provider.setLanguage(lang);
                              }
                            },
                          ),

                          // Conversion buttons for Japanese
                          if (provider.selectedLanguage ==
                              SupportedLanguage.japanese) ...[
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
                                  ? () => _showKanjiSuggestions(
                                      context, provider, _resultLimit)
                                  : null,
                            ),
                          ],

                          const Spacer(),

                          // Settings button with result count
                          InkWell(
                            onTap: () => _showSettingsDialog(context),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.18),
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.tune, size: 16),
                                  const SizedBox(width: 4),
                                  Text('$_resultLimit',
                                      style: const TextStyle(fontSize: 12)),
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
                          filled: true,
                          fillColor: AppColors.primary.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final kanji = _kanjiSuggestions[index];
                              return ActionChip(
                                label: Text(kanji,
                                    style: const TextStyle(fontSize: 16)),
                                onPressed: () {
                                  _searchController.text = kanji;
                                  _searchController.selection =
                                      TextSelection.collapsed(
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
              ),

              // Search button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            provider.isLoading ? null : () => _search(provider),
                        icon: provider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(l10n.lookUp),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (provider.isLoading) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          provider.clearResults();
                        },
                        icon: const Icon(Icons.cancel),
                        label: Text(l10n.cancel),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ],
                  ],
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
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // Auto-convert Romaji to Hiragana for Japanese
      if (provider.selectedLanguage == SupportedLanguage.japanese) {
        if (!RomajiConverter.isJapanese(query) &&
            RomajiConverter.isRomaji(query)) {
          query = RomajiConverter.convertToKana(query, toKatakana: false);
          _searchController.value = TextEditingValue(
            text: query,
            selection: TextSelection.collapsed(offset: query.length),
          );
        }
      }

      provider.lookup(query, limit: _resultLimit);
      _focusNode.unfocus();
    }
  }

  /// Convert text to hiragana or katakana
  /// Supports: romaji → kana, hiragana ↔ katakana
  void _convertToKana({required bool toKatakana}) {
    final value = _searchController.text;
    if (value.isEmpty) return;

    final converted =
        RomajiConverter.convertToKana(value, toKatakana: toKatakana);
    if (converted != value) {
      _searchController.value = TextEditingValue(
        text: converted,
        selection: TextSelection.collapsed(offset: converted.length),
      );
      setState(() {});
    }
  }

  /// Show Kanji suggestions from dictionary search
  Future<void> _showKanjiSuggestions(
      BuildContext context, DictionaryProvider provider, int limit) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loadingKanji = true;
      _kanjiSuggestions = [];
    });

    try {
      // Search for kanji using Mazii API
      final results =
          await provider.searchKanjiSuggestions(query, limit: limit);
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

    int tempLimit = _resultLimit;
    String tempFilterMode = provider.filterMode;
    bool tempFallback = provider.fallbackToEnglish;
    String tempFetchMode = provider.fetchMode;

    showStandardDialog(
      context: context,
      title: l10n.dictionarySettings,
      customContent: StatefulBuilder(
        builder: (context, setDialogState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Result limit
                Text(l10n.resultLimit,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
                Text(l10n.filterMode,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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

                // Fetch mode
                const Text('Nguồn dữ liệu',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _FilterOption(
                  title: 'Kết hợp cả 2',
                  subtitle: 'Sử dụng cả offline database và online API',
                  value: 'both',
                  groupValue: tempFetchMode,
                  onChanged: (v) => setDialogState(() => tempFetchMode = v!),
                ),
                _FilterOption(
                  title: 'Chỉ Offline',
                  subtitle: 'Chỉ tìm trong máy, không cần internet',
                  value: 'offline',
                  groupValue: tempFetchMode,
                  onChanged: (v) => setDialogState(() => tempFetchMode = v!),
                ),
                _FilterOption(
                  title: 'Chỉ Online',
                  subtitle: 'Chỉ tìm trên máy chủ',
                  value: 'online',
                  groupValue: tempFetchMode,
                  onChanged: (v) => setDialogState(() => tempFetchMode = v!),
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
      secondaryButtonText: l10n.cancel,
      onSecondaryPressed: () {},
      primaryButtonText: l10n.save,
      onPrimaryPressed: () {
        setState(() {
          _resultLimit = tempLimit;
        });
        provider.setFilterMode(tempFilterMode);
        provider.setFetchMode(tempFetchMode);
        provider.setFallbackToEnglish(tempFallback);
      },
    );
  }

  Widget _buildResults(BuildContext context, DictionaryProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    if (provider.isLoading && provider.results.isEmpty) {
      return LoadingWidget(message: l10n.lookingUp);
    }

    if (provider.error != null && provider.results.isEmpty) {
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
    final hasFallbackBanner =
        provider.usedFallback && provider.fallbackSource != null;
    final baseItemCount = provider.results.length + (hasFallbackBanner ? 1 : 0);
    final showLoadingAtBottom =
        provider.isLoading && provider.results.isNotEmpty;
    final itemCount = baseItemCount + (showLoadingAtBottom ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Loading indicator at the bottom
        if (showLoadingAtBottom && index == itemCount - 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Đang tìm thêm trên các nguồn online...',
                  style: TextStyle(
                    color: AppColors.textSecondaryLight.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

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

    // Controllers for editable fields
    final phoneticController =
        TextEditingController(text: result.phonetic ?? '');
    final backController = TextEditingController(text: backContent);
    final exampleController = TextEditingController();
    final notesController = TextEditingController();

    // Get first example if available
    for (final meaning in result.meanings) {
      for (final def in meaning.definitions) {
        if (def.example != null && def.example!.isNotEmpty) {
          exampleController.text = def.example!;
          break;
        }
      }
      if (exampleController.text.isNotEmpty) break;
    }

    String? selectedDeckId =
        filteredDecks.isNotEmpty ? filteredDecks.first.id : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Row(
                children: [
                  const Icon(Icons.add_card, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(l10n.addToDeck),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Word (read-only) - Card style
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.front,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary.withValues(alpha: 0.7),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              result.word,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phonetic (editable)
                      TextField(
                        controller: phoneticController,
                        decoration: InputDecoration(
                          labelText: l10n.phonetic,
                          hintText: l10n.phoneticHint,
                          prefixIcon:
                              const Icon(Icons.record_voice_over, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Back/Meaning (editable)
                      TextField(
                        controller: backController,
                        decoration: InputDecoration(
                          labelText: l10n.back,
                          hintText: l10n.enterMeaning,
                          prefixIcon: const Icon(Icons.translate, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      // Example (editable)
                      TextField(
                        controller: exampleController,
                        decoration: InputDecoration(
                          labelText: l10n.example,
                          hintText: l10n.addExample,
                          prefixIcon: const Icon(Icons.format_quote, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Notes (editable)
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: l10n.notes,
                          hintText: l10n.addNotes,
                          prefixIcon: const Icon(Icons.note, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // Deck selection header
                      Row(
                        children: [
                          const Icon(Icons.folder,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.selectDeck,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Deck list
                      if (filteredDecks.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.folder_off,
                                size: 40,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                deckProvider.decks.isNotEmpty
                                    ? 'No ${dictProvider.selectedLanguage.nameEn} decks found'
                                    : l10n.noDecksYet,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondaryLight,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  phoneticController.dispose();
                                  backController.dispose();
                                  exampleController.dispose();
                                  notesController.dispose();
                                  Navigator.pop(dialogContext);
                                  Navigator.pushNamed(context, '/create-deck');
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(l10n.createDeck),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredDecks.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                              itemBuilder: (context, index) {
                                final deck = filteredDecks[index];
                                final isSelected = deck.id == selectedDeckId;
                                return Material(
                                  color: isSelected
                                      ? AppColors.primary
                                          .withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedDeckId = deck.id;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.primary
                                                      .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.style,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.primary,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  deck.name,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${deck.cardCount} ${l10n.cards.toLowerCase()}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .textSecondaryLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: AppColors.primary,
                                              size: 24,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    phoneticController.dispose();
                    backController.dispose();
                    exampleController.dispose();
                    notesController.dispose();
                    Navigator.pop(dialogContext);
                  },
                  child: Text(l10n.cancel),
                ),
                if (filteredDecks.isNotEmpty)
                  FilledButton.icon(
                    onPressed: selectedDeckId == null
                        ? null
                        : () async {
                            final phonetic = phoneticController.text.trim();
                            final back = backController.text.trim();
                            final example = exampleController.text.trim();
                            final notes = notesController.text.trim();

                            phoneticController.dispose();
                            backController.dispose();
                            exampleController.dispose();
                            notesController.dispose();

                            Navigator.pop(dialogContext);
                            await _addFlashcardToDeckWithDetails(
                              context,
                              selectedDeckId!,
                              result.word,
                              phonetic.isEmpty ? null : phonetic,
                              back,
                              example.isEmpty ? null : example,
                              notes.isEmpty ? null : notes,
                            );
                          },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addFlashcard),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addFlashcardToDeckWithDetails(
    BuildContext context,
    String deckId,
    String word,
    String? phonetic,
    String back,
    String? example,
    String? notes,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final deckProvider = context.read<DeckProvider>();

    try {
      await deckProvider.addFlashcard(
        deckId: deckId,
        front: word,
        back: back,
        phonetic: phonetic,
        example: example,
        notes: notes,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.addedToDeck}: $word'),
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

  void _showStrokeOrderDialog(
      BuildContext context, String word, SupportedLanguage language) {
    final l10n = AppLocalizations.of(context)!;

    final targetChars = word.characters
        .where((char) => RegExp(r'[一-龿]').hasMatch(char))
        .toList();
    if (targetChars.isEmpty) return;

    showStandardDialog(
      context: context,
      title: l10n.playStrokeOrder,
      customContent: _StrokeAnimationDialogContent(
        characters: targetChars,
        sourceLanguage: language.code,
      ),
      primaryButtonText: l10n.close,
    );
  }

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
                      // Result number badge & Data Source badge
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (totalResults > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.textSecondaryLight
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$resultIndex / $totalResults',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondaryLight),
                              ),
                            ),
                          if (result.dataSource != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: result.dataSource!
                                        .toLowerCase()
                                        .contains('offline')
                                    ? Colors.blueGrey.withValues(alpha: 0.2)
                                    : Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    result.dataSource!
                                            .toLowerCase()
                                            .contains('offline')
                                        ? Icons.sd_storage
                                        : Icons.cloud_done,
                                    size: 12,
                                    color: result.dataSource!
                                            .toLowerCase()
                                            .contains('offline')
                                        ? Colors.blueGrey
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    result.dataSource!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: result.dataSource!
                                              .toLowerCase()
                                              .contains('offline')
                                          ? Colors.blueGrey
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: SelectableText(
                              result.word,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.volume_up,
                                color: AppColors.primary),
                            onPressed: () {
                              TtsService().speak(result.word,
                                  language: selectedLanguage);
                            },
                            tooltip: 'Phát âm (TTS)',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      if (result.phonetic != null) ...[
                        const SizedBox(height: 4),
                        SelectableText(
                          result.phonetic!,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions at top right
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((selectedLanguage == SupportedLanguage.japanese ||
                            selectedLanguage == SupportedLanguage.chinese) &&
                        RegExp(r'[一-龿]').hasMatch(result.word))
                      IconButton(
                        onPressed: () => _showStrokeOrderDialog(
                            context, result.word, selectedLanguage),
                        icon: const Icon(Icons.brush),
                        color: Colors.orange,
                        tooltip: l10n.playStrokeOrder,
                        iconSize: 28,
                      ),
                    IconButton(
                      onPressed: onAddToDeck,
                      icon: const Icon(Icons.add_circle),
                      color: Colors.green,
                      tooltip: l10n.addToDeck,
                      iconSize: 32,
                    ),
                  ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Text(syn,
                    style: const TextStyle(fontSize: 12, color: Colors.green)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Text(ant,
                    style: const TextStyle(fontSize: 12, color: Colors.orange)),
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
                      child: SelectableText(definition.definition),
                    ),
                  ],
                ),
                if (definition.example != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: SelectableText(
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

class _StrokeAnimationDialogContent extends StatefulWidget {
  final List<String> characters;
  final String sourceLanguage;

  const _StrokeAnimationDialogContent({
    required this.characters,
    required this.sourceLanguage,
  });

  @override
  State<_StrokeAnimationDialogContent> createState() =>
      _StrokeAnimationDialogContentState();
}

class _StrokeAnimationDialogContentState
    extends State<_StrokeAnimationDialogContent> {
  int _currentIndex = 0;
  List<StrokeCharacter?> _strokeDataList = [];
  bool _isLoading = true;
  final GlobalKey<StrokeOrderAnimationState> _animationKey =
      GlobalKey<StrokeOrderAnimationState>();

  @override
  void initState() {
    super.initState();
    _loadStrokeData();
  }

  Future<void> _loadStrokeData() async {
    final dao = StrokeDataDao();
    await dao.init();
    final repository = StrokeDataRepository(dao);

    final List<StrokeCharacter?> dataList = [];
    for (final char in widget.characters) {
      final data =
          await repository.lookupCharacter(char, widget.sourceLanguage);
      dataList.add(data);
    }

    if (mounted) {
      setState(() {
        _strokeDataList = dataList;
        final firstValidIndex = dataList.indexWhere((data) => data != null);
        if (firstValidIndex != -1) {
          _currentIndex = firstValidIndex;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final currentData =
        _strokeDataList.isNotEmpty ? _strokeDataList[_currentIndex] : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.characters.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Wrap(
              spacing: 8,
              children: List.generate(widget.characters.length, (index) {
                final isSelected = index == _currentIndex;
                final hasData = _strokeDataList[index] != null;
                return ChoiceChip(
                  label: Text(
                    widget.characters[index],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: hasData ? null : Colors.grey,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: hasData
                      ? (selected) {
                          if (selected) {
                            setState(() {
                              _currentIndex = index;
                            });
                          }
                        }
                      : null,
                );
              }),
            ),
          ),
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: currentData != null
              ? StrokeOrderAnimation(
                  key: _animationKey,
                  character: currentData,
                  strokeDuration: const Duration(milliseconds: 300),
                  pauseBetweenStrokes: const Duration(milliseconds: 500),
                  onCompleted: () {},
                )
              : const Center(
                  child: Text('Không có dữ liệu nét chữ',
                      style: TextStyle(color: AppColors.textSecondaryLight)),
                ),
        ),
        const SizedBox(height: 16),
        if (currentData != null)
          IconButton(
            onPressed: () {
              _animationKey.currentState?.replay();
            },
            icon: const Icon(Icons.replay),
            color: AppColors.primary,
            tooltip: 'Phát lại',
            iconSize: 32,
          ),
      ],
    );
  }
}
