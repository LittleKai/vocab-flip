import os

filepath = 'lib/presentation/screens/dictionary/dictionary_search_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports
imports = '''import '../../../data/models/dictionary_result.dart';
import '../../../data/models/stroke_character.dart';
import '../../../data/local/database/stroke_data_dao.dart';
import '../../../data/repositories/stroke_data_repository.dart';
import '../../../data/services/tts_service.dart';
import '../../providers/dictionary_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/stroke/stroke_order_animation.dart';'''

content = content.replace('''import '../../../data/models/dictionary_result.dart';
import '../../../data/services/tts_service.dart';
import '../../providers/dictionary_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/common/loading_widget.dart';''', imports)

# Replace the button
old_button = '''                // Add button at top right
                IconButton(
                  onPressed: onAddToDeck,
                  icon: const Icon(Icons.add_circle),
                  color: AppColors.primary,
                  tooltip: l10n.addToDeck,
                  iconSize: 32,
                ),'''

new_button = '''                // Actions at top right
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((selectedLanguage == SupportedLanguage.japanese || selectedLanguage == SupportedLanguage.chinese) && RegExp(r'[\u4E00-\u9FBF]').hasMatch(result.word))
                      IconButton(
                        onPressed: () => _showStrokeOrderDialog(context, result.word, selectedLanguage),
                        icon: const Icon(Icons.brush),
                        color: AppColors.primary,
                        tooltip: l10n.playStrokeOrder,
                        iconSize: 28,
                      ),
                    IconButton(
                      onPressed: onAddToDeck,
                      icon: const Icon(Icons.add_circle),
                      color: AppColors.primary,
                      tooltip: l10n.addToDeck,
                      iconSize: 32,
                    ),
                  ],
                ),'''
                
content = content.replace(old_button, new_button)

# Add _showStrokeOrderDialog method
old_card_constructor = '''  final VoidCallback? onAddToDeck;

  const _DictionaryResultCard({
    required this.result,
    required this.resultIndex,
    required this.totalResults,
    required this.selectedLanguage,
    this.onAddToDeck,
  });

  @override'''

new_card_constructor = '''  final VoidCallback? onAddToDeck;

  const _DictionaryResultCard({
    required this.result,
    required this.resultIndex,
    required this.totalResults,
    required this.selectedLanguage,
    this.onAddToDeck,
  });

  void _showStrokeOrderDialog(BuildContext context, String word, SupportedLanguage language) {
    final l10n = AppLocalizations.of(context)!;
    
    final targetChars = word.characters.where((char) => RegExp(r'[\u4E00-\u9FBF]').hasMatch(char)).toList();
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

  @override'''

content = content.replace(old_card_constructor, new_card_constructor)

# Append the new stateful widget at the end
new_widget = '''
class _StrokeAnimationDialogContent extends StatefulWidget {
  final List<String> characters;
  final String sourceLanguage;

  const _StrokeAnimationDialogContent({
    required this.characters,
    required this.sourceLanguage,
  });

  @override
  State<_StrokeAnimationDialogContent> createState() => _StrokeAnimationDialogContentState();
}

class _StrokeAnimationDialogContentState extends State<_StrokeAnimationDialogContent> {
  int _currentIndex = 0;
  List<StrokeCharacter?> _strokeDataList = [];
  bool _isLoading = true;
  int _replayKey = 0;

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
      final data = await repository.lookupCharacter(char, widget.sourceLanguage);
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

    final currentData = _strokeDataList.isNotEmpty ? _strokeDataList[_currentIndex] : null;

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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: hasData ? null : Colors.grey,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: hasData
                      ? (selected) {
                          if (selected) {
                            setState(() {
                              _currentIndex = index;
                              _replayKey = 0;
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
                  key: ValueKey('__'),
                  character: currentData,
                  onCompleted: () {},
                )
              : const Center(
                  child: Text('Không có dữ liệu nét chữ', style: TextStyle(color: AppColors.textSecondaryLight)),
                ),
        ),
        
        const SizedBox(height: 16),
        
        if (currentData != null)
          IconButton(
            onPressed: () {
              setState(() {
                _replayKey++;
              });
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
'''

content += new_widget

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
