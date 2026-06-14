import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../dialogs/standard_dialog.dart';

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
  final _promptController = TextEditingController();
  final _noteInstructionController = TextEditingController();
  double _cardCount = 20;
  bool _includeExamples = true;
  bool _includeNotes = false;
  String _model = 'flash'; // 'flash' or 'pro'

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
      {'text': l10n.promptSuggestion1, 'icon': Icons.chat_bubble_outline, 'color': Colors.blue},
      {'text': l10n.promptSuggestion2, 'icon': Icons.business_center_outlined, 'color': Colors.brown},
      {'text': l10n.promptSuggestion3, 'icon': Icons.restaurant_menu_outlined, 'color': Colors.orange},
      {'text': l10n.promptSuggestion4, 'icon': Icons.tag_faces_outlined, 'color': Colors.purple},
      {'text': l10n.promptSuggestion5, 'icon': Icons.computer_outlined, 'color': Colors.teal},
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 22),
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
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.aiGenerateCards,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.help_outline, size: 20, color: AppColors.primary),
                          tooltip: l10n.promptSuggestionsTitle,
                          onPressed: () => _showPromptSuggestions(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _promptController,
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
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      onChanged: (v) => setState(() => _cardCount = v),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('20', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
                          Text(l10n.maxCards(100), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
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
                    Row(
                      children: [
                        Expanded(
                          child: _ModelOption(
                            label: 'Flash',
                            subtitle: l10n.modelFlash,
                            icon: Icons.flash_on,
                            color: AppColors.warning,
                            isSelected: _model == 'flash',
                            onTap: () => setState(() => _model = 'flash'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ModelOption(
                            label: 'Pro',
                            subtitle: l10n.modelPro,
                            icon: Icons.stars,
                            color: AppColors.primary,
                            isSelected: _model == 'pro',
                            onTap: () => setState(() => _model = 'pro'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Optional fields toggles
                    SwitchListTile(
                      title: Text(l10n.includeExamples),
                      subtitle: Text(l10n.example, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                      value: _includeExamples,
                      onChanged: (v) => setState(() => _includeExamples = v),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: Text(l10n.includeNotes),
                      subtitle: Text(l10n.notes, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                      value: _includeNotes,
                      onChanged: (v) => setState(() => _includeNotes = v),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    // Note instructions input (only visible if _includeNotes is true)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _includeNotes
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16),
                              child: TextField(
                                controller: _noteInstructionController,
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
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    onPressed: (!isAuthenticated || isGenerating || (!aiProvider.canGenerate))
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        );
      },
    );
  }

  Widget _buildUsageInfo(BuildContext context, AiProvider aiProvider, bool isAuthenticated) {
    final l10n = AppLocalizations.of(context)!;

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

    final freeUses = aiProvider.freeUsesRemaining;
    final credits = aiProvider.creditBalance;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (freeUses > 0 ? AppColors.info : AppColors.secondary).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (freeUses > 0 ? AppColors.info : AppColors.secondary).withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (freeUses > 0) ...[
            Row(
              children: [
                Icon(Icons.card_giftcard, color: AppColors.info, size: 18),
                const SizedBox(width: 6),
                Text(
                  l10n.freeUsesRemaining(freeUses),
                  style: TextStyle(color: AppColors.info, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.monetization_on_outlined, color: AppColors.secondary, size: 18),
                const SizedBox(width: 6),
                Text(
                  l10n.costsOneCredit,
                  style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  l10n.balanceCredits(credits),
                  style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12),
                ),
              ],
            ),
            if (credits <= 0) ...[
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
      noteInstructions: _includeNotes ? _noteInstructionController.text.trim() : null,
      model: _model == 'pro' ? 'pro' : 'flash',
      deckId: widget.deckId,
    );

    if (!mounted) return;

    if (aiProvider.state == AiState.success && aiProvider.draftCards.isNotEmpty) {
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

class _ModelOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModelOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppColors.textSecondary(context),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
