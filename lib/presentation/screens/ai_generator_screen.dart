import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../providers/ai_provider.dart';
import '../providers/deck_provider.dart';
import 'ai_draft_queue_screen.dart';

class AiGeneratorScreen extends StatefulWidget {
  const AiGeneratorScreen({super.key});

  @override
  State<AiGeneratorScreen> createState() => _AiGeneratorScreenState();
}

class _AiGeneratorScreenState extends State<AiGeneratorScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _generate() async {
    if (_textController.text.trim().isEmpty) return;
    
    final deck = context.read<DeckProvider>().selectedDeck;
    final lang = deck?.sourceLanguage ?? 'en';
    final targetLang = deck?.targetLanguage ?? 'vi';
    
    final provider = context.read<AiProvider>();
    await provider.generateDeck(_textController.text.trim(), lang, targetLang);
    
    if (mounted && provider.state == AiState.success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiDraftQueueScreen()),
      );
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AiProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiCardGenerator)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: l10n.textToGenerateCards,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: provider.state == AiState.generating ? null : _generate,
                child: provider.state == AiState.generating
                    ? const CircularProgressIndicator()
                    : Text(l10n.generateCards),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
