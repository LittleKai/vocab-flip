import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../data/models/flashcard.dart';
import '../../../data/models/dictionary_result.dart';
import '../../../data/services/image_service.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/dictionary_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/settings_provider.dart';

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
  final _imageUrlController = TextEditingController();

  final _imageService = ImageService();

  bool _isLoading = false;
  bool _isLookingUp = false;
  String? _localImagePath; // Local file path for picked image
  bool _useImageUrl = false; // Toggle between URL and local image

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

      // Load existing image
      if (widget.flashcard!.hasImage) {
        if (widget.flashcard!.isImageUrl) {
          _useImageUrl = true;
          _imageUrlController.text = widget.flashcard!.imageUrl!;
        } else {
          _localImagePath = widget.flashcard!.imageUrl;
        }
      }
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
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editFlashcard : l10n.addFlashcard),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              onPressed: _isLookingUp ? null : _autoFill,
              tooltip: l10n.autoFillFromDictionary,
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
                labelText: l10n.wordFront,
                hintText: l10n.enterWord,
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
                        tooltip: l10n.lookUp,
                      ),
              ),
              textCapitalization: TextCapitalization.none,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterWord;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phonetic
            TextFormField(
              controller: _phoneticController,
              decoration: InputDecoration(
                labelText: l10n.phoneticReading,
                hintText: l10n.phoneticHint,
                prefixIcon: const Icon(Icons.record_voice_over),
              ),
            ),
            const SizedBox(height: 16),

            // Back (Meaning)
            TextFormField(
              controller: _backController,
              decoration: InputDecoration(
                labelText: l10n.meaningBack,
                hintText: l10n.enterMeaning,
                prefixIcon: const Icon(Icons.translate),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterMeaning;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Image Section
            _buildImageSection(l10n),
            const SizedBox(height: 16),

            // Example
            TextFormField(
              controller: _exampleController,
              decoration: InputDecoration(
                labelText: l10n.exampleSentence,
                hintText: l10n.addExample,
                prefixIcon: const Icon(Icons.format_quote),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notesOptional,
                hintText: l10n.addNotes,
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: l10n.tagsOptional,
                hintText: l10n.tagsHint,
                prefixIcon: const Icon(Icons.label),
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
                      : Text(_isEditing ? l10n.update : l10n.addFlashcard),
                ),
              ),
            ),

            if (!_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _submitAndAddAnother,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.addAndCreateAnother),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle
        Row(
          children: [
            Icon(Icons.image, color: AppColors.textSecondaryLight, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.image,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            const Spacer(),
            // Toggle between URL and Local
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l10n.localFile),
                  icon: const Icon(Icons.folder, size: 16),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.imageUrl),
                  icon: const Icon(Icons.link, size: 16),
                ),
              ],
              selected: {_useImageUrl},
              onSelectionChanged: (selected) {
                setState(() {
                  _useImageUrl = selected.first;
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Image input based on mode
        if (_useImageUrl)
          _buildUrlInput(l10n)
        else
          _buildLocalImagePicker(l10n),
      ],
    );
  }

  Widget _buildUrlInput(AppLocalizations l10n) {
    return Column(
      children: [
        TextFormField(
          controller: _imageUrlController,
          decoration: InputDecoration(
            labelText: l10n.imageUrl,
            hintText: l10n.enterImageUrl,
            prefixIcon: const Icon(Icons.link),
            suffixIcon: _imageUrlController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _imageUrlController.clear();
                      });
                    },
                  )
                : null,
          ),
          keyboardType: TextInputType.url,
          onChanged: (value) => setState(() {}),
        ),
        if (_imageUrlController.text.isNotEmpty &&
            _imageService.isValidImageUrl(_imageUrlController.text))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 200,
                ),
                child: Image.network(
                  _imageUrlController.text,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.grey.shade400),
                          const SizedBox(height: 4),
                          Text(
                            l10n.invalidImageUrl,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 100,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocalImagePicker(AppLocalizations l10n) {
    final hasImage = _localImagePath != null;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        constraints: BoxConstraints(
          minHeight: hasImage ? 150 : 120,
          maxHeight: 250,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: hasImage
            ? Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(
                        File(_localImagePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(l10n),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _buildImageButton(
                          icon: Icons.edit,
                          onTap: _pickImage,
                          tooltip: l10n.changeImage,
                        ),
                        const SizedBox(width: 8),
                        _buildImageButton(
                          icon: Icons.delete,
                          onTap: _removeImage,
                          tooltip: l10n.removeImage,
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _buildImagePlaceholder(l10n),
      ),
    );
  }

  Widget _buildImagePlaceholder(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tapToAddImage,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? color,
  }) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: color ?? Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    // Get max width from settings to resize image and save storage
    final maxWidth = context.read<SettingsProvider>().flashcardImageMaxWidth;
    final savedPath = await _imageService.pickAndSaveImage(maxWidth: maxWidth);
    if (savedPath != null) {
      // Delete old image if it's different
      if (_localImagePath != null && _localImagePath != savedPath) {
        await _imageService.deleteImage(_localImagePath!);
      }
      setState(() {
        _localImagePath = savedPath;
      });
    }
  }

  void _removeImage() {
    if (_localImagePath != null) {
      // We'll delete the image when saving if it's not used
      setState(() {
        _localImagePath = null;
      });
    }
  }

  Future<void> _autoFill() async {
    final l10n = AppLocalizations.of(context)!;
    final word = _frontController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterWordFirst)),
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
          SnackBar(
            content: Text(l10n.autoFilled),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dictProvider.error ?? l10n.wordNotFound),
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
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _saveFlashcard();
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.flashcardAdded),
          backgroundColor: AppColors.success,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _getImageUrl() {
    if (_useImageUrl) {
      final url = _imageUrlController.text.trim();
      return url.isNotEmpty && _imageService.isValidImageUrl(url) ? url : null;
    } else {
      return _localImagePath;
    }
  }

  Future<void> _saveFlashcard() async {
    final provider = context.read<FlashcardProvider>();
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final imageUrl = _getImageUrl();

    if (_isEditing) {
      // Check if image was removed or changed
      final oldImageUrl = widget.flashcard!.imageUrl;
      if (oldImageUrl != null &&
          !oldImageUrl.startsWith('http') &&
          oldImageUrl != imageUrl) {
        // Delete old local image
        await _imageService.deleteImage(oldImageUrl);
      }

      final updated = widget.flashcard!.copyWith(
        front: _frontController.text.trim(),
        frontPhonetic: _phoneticController.text.trim(),
        back: _backController.text.trim(),
        example: _exampleController.text.trim(),
        notes: _notesController.text.trim(),
        imageUrl: imageUrl,
        clearImage: imageUrl == null && widget.flashcard!.hasImage,
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
        imageUrl: imageUrl,
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
    _imageUrlController.clear();
    setState(() {
      _localImagePath = null;
    });
  }
}
