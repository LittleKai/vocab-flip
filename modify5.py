import re

filepath = 'lib/presentation/widgets/flashcard/writing_practice_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_animation = '''                          StrokeOrderAnimation(
                            key: ValueKey(
                                'replay__'),
                            character: char,
                            onCompleted: () {'''

new_animation = '''                          StrokeOrderAnimation(
                            key: ValueKey(
                                'replay__'),
                            character: char,
                            strokeDuration: const Duration(milliseconds: 300),
                            pauseBetweenStrokes: const Duration(milliseconds: 100),
                            onCompleted: () {'''

content = content.replace(old_animation, new_animation)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
