import re

with open('lib/presentation/screens/dictionary/dictionary_search_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r"child: Text\('.+?', style: TextStyle\(color: AppColors.textSecondaryLight\)\),",
                 r"child: Text('Không có dữ liệu nét chữ', style: TextStyle(color: AppColors.textSecondaryLight)),", content)
content = re.sub(r"tooltip: '.+?',\s*iconSize: 32,", "tooltip: 'Phát lại',\n            iconSize: 32,", content)

with open('lib/presentation/screens/dictionary/dictionary_search_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
