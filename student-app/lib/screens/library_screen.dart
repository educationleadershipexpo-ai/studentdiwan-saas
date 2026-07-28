import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// Live library catalogue for the logged-in student. Titles come from the real
// `library` table, availability from real per-copy inventory (library_copies),
// and "Reserve" writes a real library_reservations row — no mock books, no
// fake progress delay.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _searchQuery = '';
  String? _reservingId; // book currently being reserved

  Future<void> _reserve(String bookId, String bookTitle) async {
    setState(() => _reservingId = bookId);
    try {
      await reserveLibraryBook(ref, bookId: bookId, bookTitle: bookTitle);
      ref.invalidate(studentLibraryReservationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hold requested for "$bookTitle".'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reserve: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _reservingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(studentLibraryProvider);
    final availability = ref.watch(studentLibraryAvailabilityProvider).value ?? const <String, int>{};
    final reservedIds = ref.watch(studentLibraryReservationsProvider).value ?? const <String>{};

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Digital Library',
            subtitle: 'Search the catalog, reserve textbooks, and track availability',
            showBackButton: true,
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Search title, author, or category...',
                        hintStyle: TextStyle(color: AppColors.text3),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Book List
          Expanded(
            child: booksAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonLoader(width: double.infinity, height: 90),
                ),
              ),
              error: (err, stack) => const Center(
                child: Text('Could not load the catalogue right now.',
                    style: TextStyle(color: AppColors.text3)),
              ),
              data: (books) {
                final filtered = books.where((b) {
                  if (_searchQuery.isEmpty) return true;
                  final title = '${b['title'] ?? ''}'.toLowerCase();
                  final author = '${b['author'] ?? ''}'.toLowerCase();
                  final category = '${b['category'] ?? ''}'.toLowerCase();
                  return title.contains(_searchQuery) ||
                      author.contains(_searchQuery) ||
                      category.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(studentLibraryProvider);
                      ref.invalidate(studentLibraryAvailabilityProvider);
                      ref.invalidate(studentLibraryReservationsProvider);
                    },
                    child: ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.24),
                        Center(
                          child: Column(
                            children: [
                              const Icon(Icons.local_library_outlined, size: 64, color: AppColors.text3),
                              const SizedBox(height: 12),
                              Text(
                                books.isEmpty
                                    ? 'The library catalogue is empty.'
                                    : 'No books match your search.',
                                style: const TextStyle(color: AppColors.text3, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(studentLibraryProvider);
                    ref.invalidate(studentLibraryAvailabilityProvider);
                    ref.invalidate(studentLibraryReservationsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final book = filtered[index];
                      final id = '${book['id'] ?? ''}';
                      final title = '${book['title'] ?? 'Untitled'}';
                      final author = '${book['author'] ?? 'Unknown author'}';
                      final category = '${book['category'] ?? ''}';

                      final availableCount = availability[id] ?? 0;
                      final isReserved = reservedIds.contains(id);
                      final isAvailable = availableCount > 0;
                      final isReserving = _reservingId == id;

                      // Status label + color from real inventory / hold state.
                      final String statusLabel;
                      final Color statColor;
                      if (isReserved) {
                        statusLabel = 'On hold';
                        statColor = AppColors.amber;
                      } else if (isAvailable) {
                        statusLabel = availableCount == 1 ? '1 copy available' : '$availableCount copies available';
                        statColor = AppColors.green;
                      } else {
                        statusLabel = 'All copies out';
                        statColor = AppColors.red;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primaryExtraLight),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Book cover
                            Container(
                              width: 54,
                              height: 75,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(2, 4),
                                  )
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.book_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: context.heading3.copyWith(fontSize: 14.5)),
                                  Text('By $author', style: const TextStyle(color: AppColors.text2, fontSize: 12.5)),
                                  if (category.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(category, style: context.bodySmall),
                                  ],
                                  const SizedBox(height: 8),
                                  StatusChip(
                                    label: statusLabel,
                                    textColor: statColor,
                                    bgColor: statColor.withOpacity(0.08),
                                  ),
                                ],
                              ),
                            ),

                            // Reserve action — only when a copy is out and not
                            // already on hold by this student.
                            if (isReserving)
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              )
                            else if (!isReserved && !isAvailable)
                              IconButton(
                                tooltip: 'Request hold',
                                icon: const Icon(Icons.bookmark_add_rounded, color: AppColors.primary, size: 26),
                                onPressed: () => _reserve(id, title),
                              ),
                          ],
                        ),
                      );
                    },
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
