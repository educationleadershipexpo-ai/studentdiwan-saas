import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';

class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  static const _palette = [AppColors.primary, AppColors.green, AppColors.amber, AppColors.blue, AppColors.orange, AppColors.red];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherFlashcardsProvider);
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Flashcards', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.invalidate(teacherFlashcardsProvider)),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _errorState(e.toString(), () => ref.invalidate(teacherFlashcardsProvider)),
        data: (decks) {
          if (decks.isEmpty) {
            return _emptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(teacherFlashcardsProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: decks.length,
              itemBuilder: (_, i) {
                final d = decks[i];
                final color = _palette[i % _palette.length];
                final cards = _extractCards(d);
                final title = (d['title'] ?? d['name'] ?? d['setName'] ?? 'Untitled Deck').toString();
                final subject = (d['subject'] ?? d['topic'] ?? d['category'] ?? '').toString();
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: cards.isEmpty
                      ? null
                      : () => _openDeck(context, title, cards),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primaryExtraLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.style_rounded, color: color, size: 24),
                        ),
                        const Spacer(),
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text1)),
                        if (subject.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(subject, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.layers_outlined, size: 14, color: color),
                            const SizedBox(width: 4),
                            Text('${cards.length} cards', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Normalise the various shapes a card list can arrive in into [{q, a}].
  List<Map<String, String>> _extractCards(Map<String, dynamic> deck) {
    final raw = deck['cards'] ?? deck['flashcards'] ?? deck['items'] ?? deck['questions'];
    if (raw is! List) return [];
    return raw.map<Map<String, String>>((c) {
      if (c is Map) {
        final q = (c['question'] ?? c['q'] ?? c['front'] ?? c['term'] ?? '').toString();
        final a = (c['answer'] ?? c['a'] ?? c['back'] ?? c['definition'] ?? '').toString();
        return {'q': q, 'a': a};
      }
      return {'q': c.toString(), 'a': ''};
    }).where((c) => c['q']!.isNotEmpty).toList();
  }

  void _openDeck(BuildContext context, String title, List<Map<String, String>> cards) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FlashcardViewer(title: title, cards: cards),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style_outlined, size: 56, color: AppColors.text3),
            const SizedBox(height: 12),
            Text('No flashcard decks', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
            const SizedBox(height: 6),
            Text('No flashcard sets have been created in the system yet.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.red),
            const SizedBox(height: 12),
            Text('Could not load flashcards', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
            const SizedBox(height: 6),
            Text(msg, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _FlashcardViewer extends StatefulWidget {
  final String title;
  final List<Map<String, String>> cards;
  const _FlashcardViewer({required this.title, required this.cards});

  @override
  State<_FlashcardViewer> createState() => _FlashcardViewerState();
}

class _FlashcardViewerState extends State<_FlashcardViewer> {
  bool _flipped = false;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_index];
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.text3.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(widget.title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text1)),
          Text('Card ${_index + 1} of ${widget.cards.length}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
          const SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _flipped ? [AppColors.green, const Color(0xFF34D399)] : AppColors.headerGradient,
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_flipped ? 'ANSWER' : 'QUESTION', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1)),
                        const SizedBox(height: 16),
                        Text(
                          _flipped ? (card['a'] ?? '') : (card['q'] ?? ''),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text('Tap to flip', style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _index > 0 ? () => setState(() { _index--; _flipped = false; }) : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _index < widget.cards.length - 1 ? () => setState(() { _index++; _flipped = false; }) : null,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
