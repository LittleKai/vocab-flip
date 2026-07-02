import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';

/// Bottom sheet for configuring AI card generation.
///
/// Shows prompt input, card count slider, model selection,
/// include examples/notes toggles, and free uses / credit info.
class AiGenerateBottomSheet extends StatefulWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final String deckId;

  const AiGenerateBottomSheet({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.deckId,
  });

  @override
  State<AiGenerateBottomSheet> createState() => _AiGenerateBottomSheetState();
}

class _AiGenerateBottomSheetState extends State<AiGenerateBottomSheet> {
  static const String _modelFlash = 'gemini-3-flash';
  static const String _modelPro = 'gemini-3.1-pro';
  static const String _modelFlash35 = 'gemini-3.5-flash';

  final _promptController = TextEditingController();
  final _noteInstructionController = TextEditingController();
  double _cardCount = 20;
  bool _includeExamples = true;
  bool _includeNotes = false;
  String _model = _modelFlash;

  int get _selectedModelCost {
    return _model == _modelFlash ? 5 : 10;
  }

  bool get _selectedModelAllowsFreeUse => _model == _modelFlash;

  List<_AiModelOption> _modelOptions(AppLocalizations l10n) {
    return [
      _AiModelOption(
        id: _modelFlash,
        title: 'Gemini 3 Flash',
        subtitle: '${l10n.dailyFreeFlash} / ${l10n.creditsPerUse(5)}',
        icon: Icons.flash_on,
        color: AppColors.warning,
      ),
      _AiModelOption(
        id: _modelPro,
        title: 'Gemini 3.1 Pro',
        subtitle: l10n.creditsPerUse(10),
        icon: Icons.stars,
        color: AppColors.primary,
      ),
      _AiModelOption(
        id: _modelFlash35,
        title: 'Gemini 3.5 Flash',
        subtitle: l10n.creditsPerUse(10),
        icon: Icons.bolt,
        color: AppColors.info,
      ),
    ];
  }

  bool _canGenerateWithSelection(AiProvider aiProvider) {
    if (_selectedModelAllowsFreeUse && aiProvider.freeUsesRemaining > 0) {
      return true;
    }
    return aiProvider.creditBalance >= _selectedModelCost;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiProvider>().loadUsageInfo();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _noteInstructionController.dispose();
    super.dispose();
  }

  void _showPromptSuggestions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = [
      {
        'text': l10n.promptSuggestion1,
        'icon': Icons.chat_bubble_outline,
        'color': Colors.blue
      },
      {
        'text': l10n.promptSuggestion2,
        'icon': Icons.business_center_outlined,
        'color': Colors.brown
      },
      {
        'text': l10n.promptSuggestion3,
        'icon': Icons.restaurant_menu_outlined,
        'color': Colors.orange
      },
      {
        'text': l10n.promptSuggestion4,
        'icon': Icons.tag_faces_outlined,
        'color': Colors.purple
      },
      {
        'text': l10n.promptSuggestion5,
        'icon': Icons.computer_outlined,
        'color': Colors.teal
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lightbulb_outline,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.promptSuggestionsTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List of Suggestions
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = suggestions[index];
                    final text = item['text'] as String;
                    final icon = item['icon'] as IconData;
                    final color = item['color'] as Color;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _promptController.text = text;
                          });
                          Navigator.pop(bottomSheetContext);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: color, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      text,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            height: 1.4,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.useThisPrompt.toUpperCase(),
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aiProvider = context.watch<AiProvider>();
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    final isGenerating = aiProvider.state == AiState.generating;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.aiGenerateCards,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 20),

                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Prompt input
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.aiGenerateCardsDesc,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.help_outline,
                                size: 20, color: AppColors.primary),
                            tooltip: l10n.promptSuggestionsTitle,
                            onPressed: () => _showPromptSuggestions(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _promptController,
                        enabled: !isGenerating,
                        maxLines: 4,
                        minLines: 3,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: l10n.aiPromptHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Card count slider
                      Row(
                        children: [
                          Text(
                            l10n.cardCount,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_cardCount.round()}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _cardCount,
                        min: 20,
                        max: 100,
                        divisions: 16,
                        label: '${_cardCount.round()}',
                        activeColor: AppColors.primary,
                        onChanged: isGenerating
                            ? null
                            : (v) => setState(() => _cardCount = v),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('20',
                                style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 12)),
                            Text(l10n.maxCards(100),
                                style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 12)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Model selection
                      Text(
                        l10n.aiModel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _ModelDropdown(
                        options: _modelOptions(l10n),
                        value: _model,
                        onChanged: isGenerating
                            ? null
                            : (value) => setState(() => _model = value),
                      ),

                      const SizedBox(height: 16),

                      // Optional fields toggles
                      SwitchListTile(
                        title: Text(l10n.includeExamples),
                        subtitle: Text(l10n.includeExamplesDesc,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context))),
                        value: _includeExamples,
                        onChanged: isGenerating
                            ? null
                            : (v) => setState(() => _includeExamples = v),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: Text(l10n.includeNotes),
                        subtitle: Text(l10n.includeNotesDesc,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context))),
                        value: _includeNotes,
                        onChanged: isGenerating
                            ? null
                            : (v) => setState(() => _includeNotes = v),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),

                      // Note instructions input (only visible if _includeNotes is true)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: _includeNotes
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    top: 8, bottom: 8, left: 16),
                                child: TextField(
                                  controller: _noteInstructionController,
                                  enabled: !isGenerating,
                                  maxLines: 2,
                                  minLines: 1,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: l10n.noteInstructionsHint,
                                    helperText: l10n.noteInstructionsDesc,
                                    helperMaxLines: 2,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    filled: true,
                                    fillColor: Theme.of(context).cardColor,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 12),

                      // Usage info
                      _buildUsageInfo(context, aiProvider, isAuthenticated),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Bottom generate button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: (!isAuthenticated ||
                              isGenerating ||
                              !_canGenerateWithSelection(aiProvider))
                          ? null
                          : _onGenerate,
                      icon: isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        isGenerating ? l10n.generating : l10n.generate,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsageInfo(
      BuildContext context, AiProvider aiProvider, bool isAuthenticated) {
    final l10n = AppLocalizations.of(context)!;

    final freeUses = aiProvider.freeUsesRemaining;
    final credits = aiProvider.creditBalance;
    final canUseFree = _selectedModelAllowsFreeUse && freeUses > 0;
    final modelCost = _selectedModelCost;

    if (!isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.login, color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.signInToUseAi,
                style: TextStyle(color: AppColors.warning, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (canUseFree ? AppColors.info : AppColors.secondary)
            .withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (canUseFree ? AppColors.info : AppColors.secondary)
              .withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canUseFree) ...[
            Row(
              children: [
                Icon(Icons.card_giftcard, color: AppColors.info, size: 18),
                const SizedBox(width: 6),
                Text(
                  l10n.freeUsesRemaining(freeUses),
                  style: TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.monetization_on_outlined,
                    color: AppColors.secondary, size: 18),
                const SizedBox(width: 6),
                Text(
                  l10n.creditsPerUse(modelCost),
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                const Spacer(),
                Text(
                  l10n.balanceCredits(credits),
                  style: TextStyle(
                      color: AppColors.textSecondary(context), fontSize: 12),
                ),
              ],
            ),
            if (credits < modelCost) ...[
              const SizedBox(height: 4),
              Text(
                l10n.insufficientCredits,
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _onGenerate() async {
    final l10n = AppLocalizations.of(context)!;
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterPrompt)),
      );
      return;
    }

    final cardCount = _cardCount.round();

    // Add strict instruction to enforce exact card count
    final locale = Localizations.localeOf(context).languageCode;
    final strictInstruction = locale == 'vi'
        ? '\n\nQUAN TRỌNG: Bạn BẮT BUỘC PHẢI TẠO ĐÚNG $cardCount thẻ. Không được tạo nhiều hơn hay ít hơn.'
        : '\n\nIMPORTANT: You MUST GENERATE EXACTLY $cardCount cards. No more, no less.';
    final finalPrompt = prompt + strictInstruction;

    final aiProvider = context.read<AiProvider>();
    await aiProvider.generateCards(
      prompt: finalPrompt,
      sourceLanguage: widget.sourceLanguage,
      targetLanguage: widget.targetLanguage,
      count: cardCount,
      includeExamples: _includeExamples,
      includeNotes: _includeNotes,
      noteInstructions:
          _includeNotes ? _noteInstructionController.text.trim() : null,
      model: _model,
      deckId: widget.deckId,
    );

    if (!mounted) return;

    if (aiProvider.state == AiState.success &&
        aiProvider.draftCards.isNotEmpty) {
      Navigator.pop(context, true); // Signal to open draft review
    } else if (aiProvider.state == AiState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aiProvider.errorMessage ?? l10n.aiGenerationFailed),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (aiProvider.draftCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noCardsGenerated)),
      );
    }
  }
}

class _AiModelOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _AiModelOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _ModelDropdown extends StatelessWidget {
  final List<_AiModelOption> options;
  final String value;
  final ValueChanged<String>? onChanged;

  const _ModelDropdown({
    required this.options,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.firstWhere((option) => option.id == value);
    final theme = Theme.of(context);

    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        borderRadius: BorderRadius.circular(16),
        decoration: InputDecoration(
          filled: true,
          fillColor: onChanged == null
              ? selected.color.withValues(alpha: 0.04)
              : selected.color.withValues(alpha: 0.08),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: selected.color.withValues(alpha: 0.35)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: selected.color.withValues(alpha: 0.35)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: selected.color.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: selected.color, width: 1.5),
          ),
        ),
        selectedItemBuilder: (context) {
          return options
              .map((option) => _ModelDropdownRow(
                    option: option,
                    compact: true,
                  ))
              .toList();
        },
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.id,
                child: _ModelDropdownRow(
                  option: option,
                  selected: option.id == value,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged == null
            ? null
            : (value) {
                if (value != null) onChanged!(value);
              },
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: selected.color),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _ModelDropdownRow extends StatelessWidget {
  final _AiModelOption option;
  final bool compact;
  final bool selected;

  const _ModelDropdownRow({
    required this.option,
    this.compact = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 32 : 36,
          height: compact ? 32 : 36,
          decoration: BoxDecoration(
            color: option.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child:
              Icon(option.icon, color: option.color, size: compact ? 18 : 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              if (!compact)
                Text(
                  option.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
            ],
          ),
        ),
        if (!compact && selected) ...[
          const SizedBox(width: 10),
          Icon(
            Icons.check_circle_rounded,
            color: option.color,
            size: 18,
          ),
        ],
      ],
    );
  }
}
