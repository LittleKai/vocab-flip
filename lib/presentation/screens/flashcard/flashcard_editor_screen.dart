import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../data/models/flashcard.dart';
import '../../../data/models/deck.dart';
import '../../../data/models/dictionary_result.dart';
import '../../../data/services/image_service.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/dictionary_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/ai_provider.dart';

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

  final _imageService = ImageService();

  bool _isLoading = false;
  bool _isLookingUp = false;

  // Image state
  String? _localImagePath;
  bool _useImageUrl = false;
  final _imageUrlController = TextEditingController();

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
      final imageUrl = widget.flashcard!.frontImageUrl ?? widget.flashcard!.imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
          _useImageUrl = true;
          _imageUrlController.text = imageUrl;
        } else {
          _localImagePath = imageUrl;
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
    final deck = context.watch<DeckProvider>().selectedDeck;

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
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
          children: [
            // Build fields based on deck structure
            ..._buildFieldsFromStructure(l10n, deck),

            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 12),

            // Tags (always at bottom)
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: l10n.tagsOptional,
                hintText: l10n.tagsHint,
                prefixIcon: const Icon(Icons.label),
              ),
            ),

            // Image section (based on deck's imageDisplayMode)
            if (deck != null && deck.imageDisplayMode != ImageDisplayMode.none) ...[
              const SizedBox(height: 24),
              _buildImageSection(l10n, deck),
            ],

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? l10n.update : l10n.addFlashcard),
              ),
            ),

            if (!_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _submitAndAddAnother,
                  child: Text(l10n.addAndCreateAnother),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  List<Widget> _buildFieldsFromStructure(AppLocalizations l10n, Deck? deck) {
    final widgets = <Widget>[];
    final frontFields = deck?.frontFields ?? Deck.defaultFrontFields;
    final backFields = deck?.backFields ?? Deck.defaultBackFields;

    // Front section header
    widgets.add(_SectionHeader(
      title: l10n.front,
      icon: Icons.flip_to_front,
      color: AppColors.primary,
    ));
    widgets.add(const SizedBox(height: 12));

    // Front fields
    for (final field in frontFields) {
      widgets.add(_buildFieldWidget(field, l10n, isFront: true));
      widgets.add(const SizedBox(height: 12));
    }

    widgets.add(const SizedBox(height: 12));

    // Back section header
    widgets.add(_SectionHeader(
      title: l10n.back,
      icon: Icons.flip_to_back,
      color: AppColors.secondary,
    ));
    widgets.add(const SizedBox(height: 12));

    // Back fields
    for (final field in backFields) {
      widgets.add(_buildFieldWidget(field, l10n, isFront: false));
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  Widget _buildFieldWidget(CardFieldType field, AppLocalizations l10n, {required bool isFront}) {
    final color = isFront ? AppColors.primary : AppColors.secondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Side indicator
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isFront ? Icons.flip_to_front : Icons.flip_to_back,
              color: color,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildFieldInput(field, l10n)),
      ],
    );
  }

  Widget _buildFieldInput(CardFieldType field, AppLocalizations l10n) {
    switch (field) {
      case CardFieldType.word:
        return TextFormField(
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
        );

      case CardFieldType.phonetic:
        return TextFormField(
          controller: _phoneticController,
          decoration: InputDecoration(
            labelText: l10n.phoneticReading,
            hintText: l10n.phoneticHint,
            prefixIcon: const Icon(Icons.record_voice_over),
          ),
        );

      case CardFieldType.meaning:
        return Consumer<AiProvider>(
          builder: (context, aiProvider, child) {
            return TextFormField(
              controller: _backController,
              decoration: InputDecoration(
                labelText: l10n.meaningBack,
                hintText: l10n.enterMeaning,
                prefixIcon: const Icon(Icons.translate),
                suffixIcon: aiProvider.state == AiState.generating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.bolt, color: AppColors.primary),
                        onPressed: () => _generateMnemonic(aiProvider, context),
                        tooltip: l10n.generateMnemonic ?? 'Generate Mnemonic',
                      ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterMeaning;
                }
                return null;
              },
            );
          },
        );

      case CardFieldType.example:
        return TextFormField(
          controller: _exampleController,
          decoration: InputDecoration(
            labelText: l10n.exampleSentence,
            hintText: l10n.addExample,
            prefixIcon: const Icon(Icons.format_quote),
          ),
          maxLines: 3,
        );

      case CardFieldType.notes:
        return TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: l10n.notesOptional,
            hintText: l10n.addNotes,
            prefixIcon: const Icon(Icons.note),
          ),
          maxLines: 2,
        );
    }
  }

  Widget _buildImageSection(AppLocalizations l10n, Deck deck) {
    final modeLabel = switch (deck.imageDisplayMode) {
      ImageDisplayMode.both => l10n.bothSides,
      ImageDisplayMode.front => l10n.frontOnly,
      ImageDisplayMode.back => l10n.backOnly,
      ImageDisplayMode.none => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                modeLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ToggleButtons(
              isSelected: [!_useImageUrl, _useImageUrl],
              onPressed: (index) {
                setState(() => _useImageUrl = index == 1);
              },
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
              children: [
                Tooltip(
                  message: l10n.localFile,
                  child: const Icon(Icons.folder, size: 18),
                ),
                Tooltip(
                  message: l10n.imageUrl,
                  child: const Icon(Icons.link, size: 18),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                      setState(() => _imageUrlController.clear());
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
                constraints: const BoxConstraints(maxHeight: 200),
                child: Image.network(
                  _imageUrlController.text,
                  fit: BoxFit.contain,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  errorBuilder: (_, __, ___) => _buildImageError(l10n),
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

  Widget _buildImageError(AppLocalizations l10n) {
    return Container(
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
          border: Border.all(color: Colors.grey.shade300),
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
                          onTap: () => setState(() => _localImagePath = null),
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
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
          child: Icon(icon, size: 20, color: color ?? Colors.white),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    // Always use 1000px max width for better quality
    const maxWidth = 1000;
    final savedPath = await _imageService.pickAndSaveImage(maxWidth: maxWidth, useB2: false);
    if (savedPath != null) {
      if (_localImagePath != null && _localImagePath != savedPath) {
        await _imageService.deleteImage(_localImagePath!);
      }
      setState(() => _localImagePath = savedPath);
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

      final results = dictProvider.results;
      if (results.isNotEmpty) {
        _fillFromDictionary(results.first);
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

  Future<void> _generateMnemonic(AiProvider provider, BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final word = _frontController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterWordFirst)),
      );
      return;
    }
    final deck = context.read<DeckProvider>().selectedDeck;
    final lang = deck?.sourceLanguage ?? 'en';
    
    final result = await provider.generateMnemonic(word, lang);
    if (result != null && mounted) {
      // Append mnemonic to notes
      final currentNotes = _notesController.text.trim();
      if (currentNotes.isNotEmpty) {
        _notesController.text = '$currentNotes\n\nMnemonic: $result';
      } else {
        _notesController.text = 'Mnemonic: $result';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.success), backgroundColor: AppColors.success),
      );
    } else if (provider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppColors.error),
      );
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
      final oldImage = widget.flashcard!.frontImageUrl ?? widget.flashcard!.imageUrl;
      if (oldImage != null && !oldImage.startsWith('http') && oldImage != imageUrl) {
        await _imageService.deleteImage(oldImage);
      }

      final updated = widget.flashcard!.copyWith(
        front: _frontController.text.trim(),
        frontPhonetic: _phoneticController.text.trim(),
        back: _backController.text.trim(),
        example: _exampleController.text.trim(),
        notes: _notesController.text.trim(),
        frontImageUrl: imageUrl,
        clearFrontImage: imageUrl == null && widget.flashcard!.hasFrontImage,
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
        frontImageUrl: imageUrl,
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
    setState(() => _localImagePath = null);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
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
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
