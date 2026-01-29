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

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  SupportedLanguage _sourceLanguage = SupportedLanguage.english;
  bool _isLoading = false;

  bool get _isEditing => widget.deck != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.deck!.name;
      _descriptionController.text = widget.deck!.description ?? '';
      _sourceLanguage = SupportedLanguage.fromCode(widget.deck!.sourceLanguage);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editDeck : l10n.createDeck),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
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
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
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
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<DeckProvider>();

      if (_isEditing) {
        final updatedDeck = widget.deck!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          sourceLanguage: _sourceLanguage.code,
          targetLanguage: 'vi', // Always Vietnamese
        );
        await provider.updateDeck(updatedDeck);
      } else {
        final newDeck = Deck(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          sourceLanguage: _sourceLanguage.code,
          targetLanguage: 'vi', // Always Vietnamese
        );
        await provider.createDeck(newDeck);
      }

      // Check if there was an error in the provider
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
