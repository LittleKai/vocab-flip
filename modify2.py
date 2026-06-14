import re

filepath = 'lib/presentation/screens/dictionary/dictionary_search_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the whole class _StrokeAnimationDialogContentState body
new_state_body = '''class _StrokeAnimationDialogContentState
    extends State<_StrokeAnimationDialogContent> {
  int _currentIndex = 0;
  List<StrokeCharacter?> _strokeDataList = [];
  bool _isLoading = true;
  final GlobalKey<StrokeOrderAnimationState> _animationKey = GlobalKey<StrokeOrderAnimationState>();

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
                  pauseBetweenStrokes: const Duration(milliseconds: 100),
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
}'''

# Extract the part to replace using regex
pattern = re.compile(r'class _StrokeAnimationDialogContentState.+', re.DOTALL)
content = pattern.sub(new_state_body, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

