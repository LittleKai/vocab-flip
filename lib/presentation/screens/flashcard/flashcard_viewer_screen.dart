import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
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
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FlashcardProvider, DeckProvider>(
      builder: (context, flashcardProvider, deckProvider, child) {
        final flashcards = flashcardProvider.flashcards;
        final deck = deckProvider.selectedDeck;

        if (flashcards.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('View Cards')),
            body: const Center(child: Text('No flashcards')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${_currentIndex + 1} / ${flashcards.length}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.shuffle),
                onPressed: () {
                  // TODO: Shuffle cards
                },
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
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: FlipCard(
                        controller: _flipController,
                        isFlipped: _isFlipped,
                        onFlip: () {
                          setState(() => _isFlipped = !_isFlipped);
                        },
                        front: FlashcardFace(
                          text: card.front,
                          phonetic: card.frontPhonetic,
                          isFront: true,
                          onAudioPlay: () => _speakWord(
                            card.front,
                            deck?.sourceLanguage ?? 'en',
                          ),
                        ),
                        back: FlashcardFace(
                          text: card.back,
                          subtitle: card.example,
                          isFront: false,
                          onAudioPlay: () => _speakWord(card.back, 'vi'),
                        ),
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
                        setState(() => _isFlipped = !_isFlipped);
                        if (_isFlipped) {
                          _flipController.flipToBack();
                        } else {
                          _flipController.flipToFront();
                        }
                      },
                      icon: Icon(_isFlipped ? Icons.flip_to_front : Icons.flip_to_back),
                      iconSize: 32,
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
