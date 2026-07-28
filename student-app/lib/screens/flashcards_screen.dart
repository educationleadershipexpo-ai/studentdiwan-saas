import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  int _currentIndex = 0;
  bool _showBack = false;
  int _reviewedCount = 0;

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(studentFlashcardsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          const AppHeader(
            title: 'Revision Flashcards',
            subtitle: 'Interactive study decks to test your recall',
            showBackButton: true,
          ),
          const SizedBox(height: 16),

          Expanded(
            child: cardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Could not load flashcards.')),
              data: (cards) {
                if (cards.isEmpty) {
                  return const Center(child: Text('No revision cards available.'));
                }

                if (_currentIndex >= cards.length) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.green),
                        const SizedBox(height: 16),
                        Text(
                          'Deck Completed!',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You reviewed $_reviewedCount flashcards.',
                          style: const TextStyle(color: AppColors.text2),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () {
                            setState(() {
                              _currentIndex = 0;
                              _showBack = false;
                              _reviewedCount = 0;
                            });
                          },
                          child: const Text('Restart Deck', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                final currentCard = cards[_currentIndex];

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(currentCard['subject'] ?? 'General'),
                            backgroundColor: AppColors.primarySurface,
                            labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Card ${_currentIndex + 1} of ${cards.length}',
                            style: const TextStyle(color: AppColors.text3, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Card Flip container
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showBack = !_showBack),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _showBack ? AppColors.green : AppColors.primary,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_showBack ? AppColors.green : AppColors.primary).withOpacity(0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _showBack ? 'ANSWER' : 'QUESTION',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: _showBack ? AppColors.green : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _showBack ? (currentCard['back'] ?? '') : (currentCard['front'] ?? ''),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text1,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Tap card to flip',
                                  style: context.bodySmall.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                setState(() {
                                  _currentIndex++;
                                  _showBack = false;
                                  _reviewedCount++;
                                });
                              },
                              child: const Text('Needs Review', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                setState(() {
                                  _currentIndex++;
                                  _showBack = false;
                                  _reviewedCount++;
                                });
                              },
                              child: const Text('Got It!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
