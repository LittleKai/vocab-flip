import re

filepath = 'lib/presentation/screens/dictionary/dictionary_search_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_actions = '''                // Actions at top right
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((selectedLanguage == SupportedLanguage.japanese || selectedLanguage == SupportedLanguage.chinese) && RegExp(r'[\\u4E00-\\u9FBF]').hasMatch(result.word))
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

new_actions = '''                // Actions at top right
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((selectedLanguage == SupportedLanguage.japanese || selectedLanguage == SupportedLanguage.chinese) && RegExp(r'[\\u4E00-\\u9FBF]').hasMatch(result.word))
                      IconButton(
                        onPressed: () => _showStrokeOrderDialog(context, result.word, selectedLanguage),
                        icon: const Icon(Icons.brush),
                        color: Colors.orange, // Màu cam cho cọ
                        tooltip: l10n.playStrokeOrder,
                        iconSize: 28,
                      ),
                    IconButton(
                      onPressed: onAddToDeck,
                      icon: const Icon(Icons.add_circle),
                      color: Colors.green, // Màu xanh lá cho nút thêm
                      tooltip: l10n.addToDeck,
                      iconSize: 32,
                    ),
                  ],
                ),'''

content = content.replace(old_actions, new_actions)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
