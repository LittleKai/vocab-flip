import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/deck.dart';
import '../../../data/services/tts_service.dart';
import '../../../core/constants/supported_languages.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/flashcard/flip_card.dart';

class FlashcardViewerScreen extends StatefulWidget {
  final String deckId;
  final int? startIndex;

  const FlashcardViewerScreen({
    super.key,
    required this.deckId,
    this.startIndex,
  });

  @override
  State<FlashcardViewerScreen> createState() => _FlashcardViewerScreenState();
}

class _FlashcardViewerScreenState extends State<FlashcardViewerScreen> {
  final PageController _pageController = PageController();
  final FlipCardController _flipController = FlipCardController();
  final TtsService _ttsService = TtsService();
  final FocusNode _focusNode = FocusNode();

  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex ?? 0;
    _ttsService.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startIndex != null) {
        _pageController.jumpToPage(widget.startIndex!);
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final flashcards = context.read<FlashcardProvider>().flashcards;
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_currentIndex < flashcards.length - 1) {
          _nextCard();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_currentIndex > 0) {
          _previousCard();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        setState(() => _isFlipped = !_isFlipped);
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Determine if image should show on a specific side based on deck's imageDisplayMode
  bool _shouldShowImage(Deck? deck, bool isFront) {
    if (deck == null) return true;
    switch (deck.imageDisplayMode) {
      case ImageDisplayMode.none:
        return false;
      case ImageDisplayMode.both:
        return true;
      case ImageDisplayMode.front:
        return isFront;
      case ImageDisplayMode.back:
        return !isFront;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<FlashcardProvider, DeckProvider>(
      builder: (context, flashcardProvider, deckProvider, child) {
        final flashcards = flashcardProvider.flashcards;
        final deck = deckProvider.selectedDeck;

        if (flashcards.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.viewCards)),
            body: Center(child: Text(l10n.noFlashcards)),
          );
        }

        final showBackFirst = deck?.showBackFirst ?? false;
        final frontFields = deck?.frontFields ?? Deck.defaultFrontFields;
        final backFields = deck?.backFields ?? Deck.defaultBackFields;

        return KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            appBar: AppBar(
              title: Text('${_currentIndex + 1} / ${flashcards.length}'),
              actions: [
                // Show display mode indicator
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    showBackFirst ? Icons.flip_to_back : Icons.flip_to_front,
                    size: 20,
                    color: Colors.white70,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  onPressed: () {
                    flashcardProvider.shuffleFlashcards();
                    // Reset to first card after shuffle
                    _pageController.jumpToPage(0);
                    setState(() {
                      _currentIndex = 0;
                      _isFlipped = false;
                    });
                    _flipController.reset();
                  },
                  tooltip: l10n.shuffle,
                ),
              ],
            ),
            body: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentIndex + 1) / flashcards.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),

              // Card viewer
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: flashcards.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _isFlipped = false;
                    });
                    _flipController.reset();
                  },
                  itemBuilder: (context, index) {
                    final card = flashcards[index];

                    // Create structured front and back faces based on deck configuration
                    final frontFace = StructuredFlashcardFace(
                      card: card,
                      fields: frontFields,
                      showImage: _shouldShowImage(deck, true),
                      isFront: true,
                    );
                    final backFace = StructuredFlashcardFace(
                      card: card,
                      fields: backFields,
                      showImage: _shouldShowImage(deck, false),
                      isFront: false,
                    );

                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: FlipCard(
                        controller: _flipController,
                        isFlipped: _isFlipped,
                        onFlip: () {
                          // Only play TTS on first flip (front to back)
                          final wasFlipped = _isFlipped;
                          setState(() => _isFlipped = !_isFlipped);
                          if (!wasFlipped && deck?.autoPlayTtsOnFlip == true) {
                            _speakWord(card.front, deck?.sourceLanguage ?? 'en');
                          }
                        },
                        // Swap front/back if showBackFirst is enabled
                        front: showBackFirst ? backFace : frontFace,
                        back: showBackFirst ? frontFace : backFace,
                      ),
                    );
                  },
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: _currentIndex > 0 ? _previousCard : null,
                      icon: const Icon(Icons.arrow_back_ios),
                      iconSize: 32,
                    ),
                    IconButton(
                      onPressed: () {
                        final card = flashcards[_currentIndex];
                        // Always speak word (front) using source language
                        _speakWord(card.front, deck?.sourceLanguage ?? 'en');
                      },
                      icon: const Icon(Icons.volume_up),
                      iconSize: 32,
                      color: AppColors.primary,
                    ),
                    IconButton(
                      onPressed: _currentIndex < flashcards.length - 1
                          ? _nextCard
                          : null,
                      icon: const Icon(Icons.arrow_forward_ios),
                      iconSize: 32,
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  void _previousCard() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextCard() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _speakWord(String text, String langCode) async {
    await _ttsService.speak(
      text,
      language: SupportedLanguage.fromCode(langCode),
    );
  }
}
