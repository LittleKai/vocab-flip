import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../data/models/deck.dart';
import '../../providers/deck_provider.dart';

class CreateDeckScreen extends StatefulWidget {
  final Deck? deck;

  const CreateDeckScreen({super.key, this.deck});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late TabController _tabController;
  SupportedLanguage _sourceLanguage = SupportedLanguage.english;
  bool _isLoading = false;
  bool _showBackFirst = false;

  // Card structure configuration
  List<CardFieldType> _frontFields = List.from(Deck.defaultFrontFields);
  List<CardFieldType> _backFields = List.from(Deck.defaultBackFields);
  ImageDisplayMode _imageDisplayMode = ImageDisplayMode.both;
  bool _autoPlayTtsOnFlip = true;

  bool get _isEditing => widget.deck != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (_isEditing) {
      _nameController.text = widget.deck!.name;
      _descriptionController.text = widget.deck!.description ?? '';
      _sourceLanguage = SupportedLanguage.fromCode(widget.deck!.sourceLanguage);
      _showBackFirst = widget.deck!.showBackFirst;
      _frontFields = List.from(widget.deck!.frontFields);
      _backFields = List.from(widget.deck!.backFields);
      _imageDisplayMode = widget.deck!.imageDisplayMode;
      _autoPlayTtsOnFlip = widget.deck!.autoPlayTtsOnFlip;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editDeck : l10n.createDeck),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.info_outline),
              text: l10n.basicInfo,
            ),
            Tab(
              icon: const Icon(Icons.dashboard_customize),
              text: l10n.cardStructure,
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(l10n),
            _buildCardStructureTab(l10n),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? l10n.updateDeck : l10n.createDeck),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Deck name
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: l10n.deckName,
            hintText: l10n.deckNameHint,
            prefixIcon: const Icon(Icons.folder),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.pleaseEnterDeckName;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: l10n.descriptionOptional,
            hintText: l10n.describeWhatDeckAbout,
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 24),

        // Source language
        Text(
          l10n.sourceLanguage,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.languageOfWordsToLearn,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: 12),
        _LanguageSelector(
          selectedLanguage: _sourceLanguage,
          onLanguageSelected: (lang) {
            setState(() => _sourceLanguage = lang);
          },
          excludeLanguages: const [SupportedLanguage.vietnamese],
        ),
        const SizedBox(height: 24),

        // Target language (fixed to Vietnamese)
        Text(
          l10n.targetLanguage,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.vietnameseBadge.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.vietnameseBadge),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.vietnameseBadge.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '🇻🇳',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.vietnamese,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Tiếng Việt',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: AppColors.vietnameseBadge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Display mode (Front first / Back first)
        Text(
          l10n.displayMode,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.displayModeDesc,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DisplayModeOption(
                icon: Icons.flip_to_front,
                label: l10n.frontFirst,
                isSelected: !_showBackFirst,
                onTap: () => setState(() => _showBackFirst = false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DisplayModeOption(
                icon: Icons.flip_to_back,
                label: l10n.backFirst,
                isSelected: _showBackFirst,
                onTap: () => setState(() => _showBackFirst = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Auto-play TTS on flip
        SwitchListTile(
          title: Text(l10n.autoPlayTts),
          subtitle: Text(l10n.autoPlayTtsDesc),
          value: _autoPlayTtsOnFlip,
          onChanged: (value) => setState(() => _autoPlayTtsOnFlip = value),
          secondary: const Icon(Icons.volume_up),
        ),
      ],
    );
  }

  Widget _buildCardStructureTab(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description
        Text(
          l10n.cardStructureDesc,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.dragToReorder,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
        ),
        const SizedBox(height: 24),

        // Front side fields
        _buildFieldSection(
          title: l10n.frontSide,
          color: AppColors.primary,
          icon: Icons.flip_to_front,
          fields: _frontFields,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) newIndex -= 1;
              final item = _frontFields.removeAt(oldIndex);
              _frontFields.insert(newIndex, item);
            });
          },
          onFieldDropped: (field) {
            setState(() {
              _backFields.remove(field);
              if (!_frontFields.contains(field)) {
                _frontFields.add(field);
              }
            });
          },
          l10n: l10n,
        ),
        const SizedBox(height: 24),

        // Back side fields
        _buildFieldSection(
          title: l10n.backSide,
          color: AppColors.secondary,
          icon: Icons.flip_to_back,
          fields: _backFields,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) newIndex -= 1;
              final item = _backFields.removeAt(oldIndex);
              _backFields.insert(newIndex, item);
            });
          },
          onFieldDropped: (field) {
            setState(() {
              _frontFields.remove(field);
              if (!_backFields.contains(field)) {
                _backFields.add(field);
              }
            });
          },
          l10n: l10n,
        ),
        const SizedBox(height: 32),

        // Image display mode
        Text(
          l10n.imageDisplay,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.imageDisplayDesc,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ImageDisplayMode.values.map((mode) {
            final isSelected = _imageDisplayMode == mode;
            return ChoiceChip(
              label: Text(_getImageModeLabel(mode, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _imageDisplayMode = mode);
                }
              },
              avatar: Icon(
                _getImageModeIcon(mode),
                size: 18,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFieldSection({
    required String title,
    required Color color,
    required IconData icon,
    required List<CardFieldType> fields,
    required void Function(int, int) onReorder,
    required void Function(CardFieldType) onFieldDropped,
    required AppLocalizations l10n,
  }) {
    return DragTarget<CardFieldType>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => onFieldDropped(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: isHighlighted ? color.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted ? color : Colors.grey.shade300,
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),

              // Field list
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fields.length,
                onReorder: onReorder,
                buildDefaultDragHandles: false,
                itemBuilder: (context, index) {
                  final field = fields[index];
                  return _FieldItem(
                    key: ValueKey(field),
                    field: field,
                    index: index,
                    color: color,
                    l10n: l10n,
                  );
                },
              ),

              if (fields.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Drop fields here',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getImageModeLabel(ImageDisplayMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ImageDisplayMode.none:
        return l10n.noImage;
      case ImageDisplayMode.both:
        return l10n.bothSides;
      case ImageDisplayMode.front:
        return l10n.frontOnly;
      case ImageDisplayMode.back:
        return l10n.backOnly;
    }
  }

  IconData _getImageModeIcon(ImageDisplayMode mode) {
    switch (mode) {
      case ImageDisplayMode.none:
        return Icons.hide_image;
      case ImageDisplayMode.both:
        return Icons.filter_none;
      case ImageDisplayMode.front:
        return Icons.flip_to_front;
      case ImageDisplayMode.back:
        return Icons.flip_to_back;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Switch to basic info tab if validation fails
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<DeckProvider>();

      if (_isEditing) {
        final updatedDeck = widget.deck!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          sourceLanguage: _sourceLanguage.code,
          targetLanguage: 'vi',
          showBackFirst: _showBackFirst,
          frontFields: _frontFields,
          backFields: _backFields,
          imageDisplayMode: _imageDisplayMode,
          autoPlayTtsOnFlip: _autoPlayTtsOnFlip,
        );
        await provider.updateDeck(updatedDeck);
      } else {
        final newDeck = Deck(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          sourceLanguage: _sourceLanguage.code,
          targetLanguage: 'vi',
          showBackFirst: _showBackFirst,
          frontFields: _frontFields,
          backFields: _backFields,
          imageDisplayMode: _imageDisplayMode,
          autoPlayTtsOnFlip: _autoPlayTtsOnFlip,
        );
        await provider.createDeck(newDeck);
      }

      if (provider.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error!),
              backgroundColor: Colors.red,
            ),
          );
          provider.clearError();
        }
        return;
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _FieldItem extends StatelessWidget {
  final CardFieldType field;
  final int index;
  final Color color;
  final AppLocalizations l10n;

  const _FieldItem({
    super.key,
    required this.field,
    required this.index,
    required this.color,
    required this.l10n,
  });

  String _getFieldLabel(CardFieldType field, AppLocalizations l10n) {
    switch (field) {
      case CardFieldType.word:
        return l10n.fieldWord;
      case CardFieldType.phonetic:
        return l10n.fieldPhonetic;
      case CardFieldType.meaning:
        return l10n.fieldMeaning;
      case CardFieldType.example:
        return l10n.fieldExample;
      case CardFieldType.notes:
        return l10n.fieldNotes;
    }
  }

  IconData _getFieldIcon(CardFieldType field) {
    switch (field) {
      case CardFieldType.word:
        return Icons.text_fields;
      case CardFieldType.phonetic:
        return Icons.record_voice_over;
      case CardFieldType.meaning:
        return Icons.translate;
      case CardFieldType.example:
        return Icons.format_quote;
      case CardFieldType.notes:
        return Icons.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<CardFieldType>(
      data: field,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getFieldIcon(field), size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                _getFieldLabel(field, l10n),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(_getFieldIcon(field), size: 18, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text(
              _getFieldLabel(field, l10n),
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Drag handle for reordering within section
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.drag_indicator,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ),

            // Field icon
            Icon(_getFieldIcon(field), size: 18, color: color),
            const SizedBox(width: 8),

            // Field label
            Expanded(
              child: Text(
                _getFieldLabel(field, l10n),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final SupportedLanguage selectedLanguage;
  final ValueChanged<SupportedLanguage> onLanguageSelected;
  final List<SupportedLanguage> excludeLanguages;

  const _LanguageSelector({
    required this.selectedLanguage,
    required this.onLanguageSelected,
    this.excludeLanguages = const [],
  });

  @override
  Widget build(BuildContext context) {
    final languages = SupportedLanguage.values
        .where((l) => !excludeLanguages.contains(l))
        .toList();

    return Column(
      children: languages.map((lang) {
        final isSelected = selectedLanguage == lang;
        final color = _getLanguageColor(lang);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onLanguageSelected(lang),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        lang.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.nameEn,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ),
                        ),
                        Text(
                          lang.nameVi,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: color),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getLanguageColor(SupportedLanguage lang) {
    switch (lang) {
      case SupportedLanguage.english:
        return AppColors.englishBadge;
      case SupportedLanguage.japanese:
        return AppColors.japaneseBadge;
      case SupportedLanguage.chinese:
        return AppColors.chineseBadge;
      case SupportedLanguage.vietnamese:
        return AppColors.vietnameseBadge;
    }
  }
}

class _DisplayModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DisplayModeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : null,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
