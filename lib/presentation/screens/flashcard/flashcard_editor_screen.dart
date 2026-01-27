import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../data/models/flashcard.dart';
import '../../../data/models/dictionary_result.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/dictionary_provider.dart';
import '../../providers/deck_provider.dart';

class FlashcardEditorScreen extends StatefulWidget {
  final String deckId;
  final Flashcard? flashcard;

  const FlashcardEditorScreen({
    super.key,
    required this.deckId,
    this.flashcard,
  });

  @override
  State<FlashcardEditorScreen> createState() => _FlashcardEditorScreenState();
}

class _FlashcardEditorScreenState extends State<FlashcardEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _phoneticController = TextEditingController();
  final _backController = TextEditingController();
  final _exampleController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;
  bool _isLookingUp = false;

  bool get _isEditing => widget.flashcard != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _frontController.text = widget.flashcard!.front;
      _phoneticController.text = widget.flashcard!.frontPhonetic ?? '';
      _backController.text = widget.flashcard!.back;
      _exampleController.text = widget.flashcard!.example ?? '';
      _notesController.text = widget.flashcard!.notes ?? '';
      _tagsController.text = widget.flashcard!.tags.join(', ');
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _phoneticController.dispose();
    _backController.dispose();
    _exampleController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Flashcard' : 'Add Flashcard'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              onPressed: _isLookingUp ? null : _autoFill,
              tooltip: 'Auto-fill from dictionary',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Front (Word)
            TextFormField(
              controller: _frontController,
              decoration: InputDecoration(
                labelText: 'Word / Front',
                hintText: 'Enter the word to learn',
                prefixIcon: const Icon(Icons.text_fields),
                suffixIcon: _isLookingUp
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _autoFill,
                        tooltip: 'Look up',
                      ),
              ),
              textCapitalization: TextCapitalization.none,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a word';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phonetic
            TextFormField(
              controller: _phoneticController,
              decoration: const InputDecoration(
                labelText: 'Phonetic / Reading (optional)',
                hintText: 'IPA, Pinyin, Hiragana, etc.',
                prefixIcon: Icon(Icons.record_voice_over),
              ),
            ),
            const SizedBox(height: 16),

            // Back (Meaning)
            TextFormField(
              controller: _backController,
              decoration: const InputDecoration(
                labelText: 'Meaning / Back',
                hintText: 'Enter the meaning in Vietnamese',
                prefixIcon: Icon(Icons.translate),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the meaning';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Example
            TextFormField(
              controller: _exampleController,
              decoration: const InputDecoration(
                labelText: 'Example sentence (optional)',
                hintText: 'Add an example sentence',
                prefixIcon: Icon(Icons.format_quote),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes or hints',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (optional)',
                hintText: 'verb, N5, food (comma-separated)',
                prefixIcon: Icon(Icons.label),
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
                      : Text(_isEditing ? 'Update' : 'Add Flashcard'),
                ),
              ),
            ),

            if (!_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _submitAndAddAnother,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Add & Create Another'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _autoFill() async {
    final word = _frontController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a word first')),
      );
      return;
    }

    setState(() => _isLookingUp = true);

    try {
      final deck = await context.read<DeckProvider>().getDeckById(widget.deckId);
      if (deck == null) return;

      final dictProvider = context.read<DictionaryProvider>();
      dictProvider.setLanguage(SupportedLanguage.fromCode(deck.sourceLanguage));
      await dictProvider.lookup(word);

      final result = dictProvider.result;
      if (result != null) {
        _fillFromDictionary(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-filled from dictionary'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dictProvider.error ?? 'Word not found'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLookingUp = false);
      }
    }
  }

  void _fillFromDictionary(DictionaryResult result) {
    if (result.phonetic != null && _phoneticController.text.isEmpty) {
      _phoneticController.text = result.phonetic!;
    }

    if (result.primaryDefinition != null && _backController.text.isEmpty) {
      _backController.text = result.primaryDefinition!;
    }

    if (result.firstExample != null && _exampleController.text.isEmpty) {
      _exampleController.text = result.firstExample!;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _saveFlashcard();
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAndAddAnother() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _saveFlashcard();
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flashcard added!'),
          backgroundColor: AppColors.success,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveFlashcard() async {
    final provider = context.read<FlashcardProvider>();
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (_isEditing) {
      final updated = widget.flashcard!.copyWith(
        front: _frontController.text.trim(),
        frontPhonetic: _phoneticController.text.trim(),
        back: _backController.text.trim(),
        example: _exampleController.text.trim(),
        notes: _notesController.text.trim(),
        tags: tags,
      );
      await provider.updateFlashcard(updated);
    } else {
      final flashcard = Flashcard(
        deckId: widget.deckId,
        front: _frontController.text.trim(),
        frontPhonetic: _phoneticController.text.trim().isNotEmpty
            ? _phoneticController.text.trim()
            : null,
        back: _backController.text.trim(),
        example: _exampleController.text.trim().isNotEmpty
            ? _exampleController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        tags: tags,
      );
      await provider.createFlashcard(flashcard);
    }
  }

  void _clearForm() {
    _frontController.clear();
    _phoneticController.clear();
    _backController.clear();
    _exampleController.clear();
    _notesController.clear();
    _tagsController.clear();
  }
}
