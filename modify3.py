import re

filepath = 'lib/presentation/screens/dictionary/dictionary_search_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_show_dialog = '''  void _showStrokeOrderDialog(BuildContext context, String word, SupportedLanguage language) {
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
  }'''

new_show_dialog = '''  void _showStrokeOrderDialog(BuildContext context, String word, SupportedLanguage language) {
    final l10n = AppLocalizations.of(context)!;
    
    final targetChars = word.characters.where((char) => RegExp(r'[\\u4E00-\\u9FBF]').hasMatch(char)).toList();
    if (targetChars.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.playStrokeOrder),
        content: _StrokeAnimationDialogContent(
          characters: targetChars,
          sourceLanguage: language.code,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }'''

content = content.replace(old_show_dialog, new_show_dialog)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
