import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/spaced_repetition.dart';
import '../../../data/services/tts_service.dart';
import '../../../core/constants/supported_languages.dart';
import '../../providers/study_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/flashcard/flip_card.dart';
import '../../widgets/flashcard/multiple_choice_card.dart';
import '../../widgets/flashcard/type_answer_card.dart';
import '../../widgets/flashcard/writing_practice_card.dart';
import '../../widgets/dialogs/standard_dialog.dart';
import '../../providers/stroke_practice_provider.dart';

enum StudyMode {
  classic,
  multipleChoice,
  typeAnswer,
  writingPractice,
}

class StudyScreen extends StatefulWidget {
  final String deckId;

  const StudyScreen({super.key, required this.deckId});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final FlipCardController _flipController = FlipCardController();
  final TtsService _ttsService = TtsService();
  StudyMode _currentMode = StudyMode.classic;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyProvider>().startStudySession(widget.deckId).then((_) {
        // Just in case we started in writing practice mode somehow, load the first card
        if (_currentMode == StudyMode.writingPractice && mounted) {
          final deck = context.read<DeckProvider>().selectedDeck;
          final card = context.read<StudyProvider>().currentCard;
          if (card != null) {
            context.read<StrokePracticeProvider>().loadForCard(
                  text: card.front,
                  sourceLanguage: deck?.sourceLanguage ?? '',
                );
          }
        }
      });
      context.read<DeckProvider>().selectDeck(widget.deckId);
    });
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer3<StudyProvider, DeckProvider, StrokePracticeProvider>(
      builder: (context, studyProvider, deckProvider, strokeProvider, child) {
        final deck = deckProvider.selectedDeck;

        return PopScope(
          canPop: studyProvider.state == StudyState.idle ||
              studyProvider.state == StudyState.completed,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _confirmExit(context, studyProvider);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(deck?.name ?? l10n.study),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _confirmExit(context, studyProvider),
              ),
              actions: [
                if (studyProvider.state == StudyState.studying ||
                    studyProvider.state == StudyState.showingAnswer) ...[
                  PopupMenuButton<StudyMode>(
                    icon: const Icon(Icons.tune),
                    tooltip: l10n.studyMode,
                    onSelected: (StudyMode mode) {
                      setState(() {
                        _currentMode = mode;
                      });
                      if (mode == StudyMode.writingPractice &&
                          studyProvider.currentCard != null) {
                        strokeProvider.loadForCard(
                          text: studyProvider.currentCard!.front,
                          sourceLanguage: deck?.sourceLanguage ?? '',
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<StudyMode>>[
                      PopupMenuItem<StudyMode>(
                        value: StudyMode.classic,
                        child: Text(l10n.classicFlip),
                      ),
                      PopupMenuItem<StudyMode>(
                        value: StudyMode.multipleChoice,
                        child: Text(l10n.multipleChoice),
                      ),
                      PopupMenuItem<StudyMode>(
                        value: StudyMode.typeAnswer,
                        child: Text(l10n.typeAnswer),
                      ),
                      if (deck?.sourceLanguage == 'ja' ||
                          deck?.sourceLanguage == 'zh')
                        PopupMenuItem<StudyMode>(
                          value: StudyMode.writingPractice,
                          child: Text(l10n.writingPractice),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.shuffle),
                    onPressed: () {
                      studyProvider.shuffleCards();
                      if (_currentMode == StudyMode.writingPractice &&
                          studyProvider.currentCard != null) {
                        strokeProvider.loadForCard(
                          text: studyProvider.currentCard!.front,
                          sourceLanguage: deck?.sourceLanguage ?? '',
                        );
                      }
                    },
                    tooltip: l10n.shuffle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () {
                      studyProvider.skipCard();
                      if (_currentMode == StudyMode.writingPractice &&
                          studyProvider.currentCard != null) {
                        strokeProvider.loadForCard(
                          text: studyProvider.currentCard!.front,
                          sourceLanguage: deck?.sourceLanguage ?? '',
                        );
                      }
                    },
                    tooltip: l10n.skip,
                  ),
                ],
              ],
            ),
            body: _buildBody(context, studyProvider, deck),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    StudyProvider provider,
    dynamic deck,
  ) {
    final l10n = AppLocalizations.of(context)!;

    switch (provider.state) {
      case StudyState.idle:
      case StudyState.loading:
        return const Center(child: CircularProgressIndicator());

      case StudyState.studying:
      case StudyState.showingAnswer:
        return _buildStudyView(context, provider, deck);

      case StudyState.completed:
        return _buildCompletedView(context, provider);

      case StudyState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(l10n.anError),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.startStudySession(widget.deckId),
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStudyView(
    BuildContext context,
    StudyProvider provider,
    dynamic deck,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final card = provider.currentCard;
    if (card == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: provider.progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),

        // Stats bar with pronunciation button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Pronunciation button
              IconButton(
                onPressed: () => _speakWord(
                  card.front,
                  deck?.sourceLanguage ?? 'en',
                ),
                icon: const Icon(Icons.volume_up),
                iconSize: 28,
                color: AppColors.primary,
              ),
              const Spacer(),
              _StatChip(
                icon: Icons.check_circle,
                label: '${provider.cardsCorrect}',
                color: AppColors.success,
              ),
              const SizedBox(width: 16),
              _StatChip(
                icon: Icons.cancel,
                label: '${provider.cardsIncorrect}',
                color: AppColors.error,
              ),
              const SizedBox(width: 16),
              _StatChip(
                icon: Icons.pending,
                label: '${provider.cardsRemaining}',
                color: AppColors.warning,
              ),
            ],
          ),
        ),

        // Flashcard
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildCardWidget(context, provider, deck),
          ),
        ),

        // Action buttons
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _currentMode == StudyMode.classic
                ? (provider.state == StudyState.studying
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => provider.showAnswer(),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(l10n.showAnswer),
                          ),
                        ),
                      )
                    : _buildRatingButtons(context, provider))
                : const SizedBox
                    .shrink(), // Multiple choice and Type Answer have their own logic
          ),
        ),
      ],
    );
  }

  Widget _buildCardWidget(
    BuildContext context,
    StudyProvider provider,
    dynamic deck,
  ) {
    final card = provider.currentCard;
    if (card == null) return const SizedBox.shrink();

    switch (_currentMode) {
      case StudyMode.multipleChoice:
        return MultipleChoiceCard(
          card: card,
          allCards: provider.studyQueue,
          onAnswerSelected: (isCorrect) {
            _rateCard(
                provider, isCorrect ? ReviewRating.good : ReviewRating.again);
          },
        );
      case StudyMode.typeAnswer:
        return TypeAnswerCard(
          card: card,
          onAnswerSelected: (isCorrect) {
            _rateCard(
                provider, isCorrect ? ReviewRating.good : ReviewRating.again);
          },
        );
      case StudyMode.writingPractice:
        return WritingPracticeCard(
          card: card,
          onComplete: (rating) {
            _rateCard(provider, rating);
          },
        );
      case StudyMode.classic:
        return FlipCard(
          controller: _flipController,
          isFlipped: provider.state == StudyState.showingAnswer,
          onFlip: () {
            // Only trigger on first flip (front to back)
            if (provider.state == StudyState.studying) {
              provider.showAnswer();
              // Auto-play TTS only on first flip
              if (deck?.autoPlayTtsOnFlip == true) {
                _speakWord(card.front, deck?.sourceLanguage ?? 'en');
              }
            }
          },
          front: FlashcardFace(
            text: card.front,
            phonetic: card.frontPhonetic,
            imageUrl: card.effectiveFrontImageUrl,
            isFront: true,
            onAudioPlay: () => _speakWord(
              card.front,
              deck?.sourceLanguage ?? 'en',
            ),
          ),
          back: FlashcardFace(
            text: card.back,
            subtitle: card.example,
            imageUrl: card.effectiveBackImageUrl,
            isFront: false,
            // Only speak word, not meaning
            onAudioPlay: () => _speakWord(
              card.front,
              deck?.sourceLanguage ?? 'en',
            ),
          ),
        );
    }
  }

  Widget _buildRatingButtons(BuildContext context, StudyProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final intervals = provider.getIntervalPreviews();

    return Row(
      children: [
        Expanded(
          child: _RatingButton(
            label: l10n.again,
            interval: intervals[ReviewRating.again] ?? 1,
            color: AppColors.ratingAgain,
            onPressed: () => _rateCard(provider, ReviewRating.again),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RatingButton(
            label: l10n.hard,
            interval: intervals[ReviewRating.hard] ?? 1,
            color: AppColors.ratingHard,
            onPressed: () => _rateCard(provider, ReviewRating.hard),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RatingButton(
            label: l10n.good,
            interval: intervals[ReviewRating.good] ?? 1,
            color: AppColors.ratingGood,
            onPressed: () => _rateCard(provider, ReviewRating.good),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RatingButton(
            label: l10n.easy,
            interval: intervals[ReviewRating.easy] ?? 1,
            color: AppColors.ratingEasy,
            onPressed: () => _rateCard(provider, ReviewRating.easy),
          ),
        ),
      ],
    );
  }

  void _rateCard(StudyProvider provider, ReviewRating rating) async {
    await provider.rateCard(rating);
    _flipController.reset();

    if (!mounted) return;

    if (_currentMode == StudyMode.writingPractice &&
        provider.currentCard != null) {
      final deck = context.read<DeckProvider>().selectedDeck;
      context.read<StrokePracticeProvider>().loadForCard(
            text: provider.currentCard!.front,
            sourceLanguage: deck?.sourceLanguage ?? '',
          );
    }

    if (provider.isFatigued) {
      provider.resetFatigue();
      final l10n = AppLocalizations.of(context)!;
      showStandardDialog(
        context: context,
        title: l10n.brainFatigueDetected,
        content: l10n.brainFatigueDesc,
        secondaryButtonText: l10n.keepGoing,
        primaryButtonText: l10n.takeABreak,
        onPrimaryPressed: () {
          Navigator.of(context)
              .pop(); // Go back to deck list or previous screen
        },
      );
    }
  }

  Widget _buildCompletedView(BuildContext context, StudyProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final session = provider.currentSession;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.studyComplete,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            _ResultCard(
              label: l10n.cardsStudied,
              value: '${provider.cardsStudied}',
              icon: Icons.style,
            ),
            const SizedBox(height: 12),
            _ResultCard(
              label: l10n.accuracy,
              value: '${provider.accuracy.toStringAsFixed(1)}%',
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
            const SizedBox(height: 12),
            if (session != null)
              _ResultCard(
                label: l10n.time,
                value: _formatDuration(session.duration),
                icon: Icons.timer,
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    provider.reset();
                    Navigator.pop(context);
                  },
                  child: Text(l10n.done),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.startStudySession(widget.deckId,
                        forceReload: true);
                  },
                  child: Text(l10n.studyAgain),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Future<void> _speakWord(String text, String langCode) async {
    await _ttsService.speak(
      text,
      language: SupportedLanguage.fromCode(langCode),
    );
  }

  void _confirmExit(BuildContext context, StudyProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    if (provider.cardsStudied == 0) {
      provider.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.pop(context);
      });
      return;
    }

    showStandardDialog(
      context: context,
      title: l10n.endSession,
      content: l10n.progressSaved,
      secondaryButtonText: l10n.continueSession,
      primaryButtonText: l10n.endSession,
      onPrimaryPressed: () async {
        await provider.saveAndCompleteSession();
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final int interval;
  final Color color;
  final VoidCallback onPressed;

  const _RatingButton({
    required this.label,
    required this.interval,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatInterval(interval),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatInterval(int days) {
    if (days < 1) return '<1d';
    if (days == 1) return '1d';
    if (days < 30) return '${days}d';
    if (days < 365) return '${(days / 30).round()}mo';
    return '${(days / 365).round()}y';
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _ResultCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.primary),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color ?? AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}
