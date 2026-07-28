import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final libAsync = ref.watch(libraryProvider(kid.id));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBackHeader(title: 'Library · ${kid.firstName}'),
      body: libAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(message: 'Failed to load library records', onRetry: () => ref.invalidate(libraryProvider(kid.id))),
        data: (loans) {
          final active = loans.where((l) => !l.returned).toList();
          final returned = loans.where((l) => l.returned).toList();

          if (loans.isEmpty) return const EmptyState(icon: Icons.menu_book_rounded, title: 'No Books Borrowed', subtitle: 'Currently borrowed books will appear here.');
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(children: [
              if (active.isNotEmpty) ...[
                const SectionHeader(title: 'Currently Borrowed'),
                ...active.map((l) => _BookCard(loan: l)),
              ],
              if (returned.isNotEmpty) ...[
                const SectionHeader(title: 'Return History'),
                ...returned.map((l) => _BookCard(loan: l, dimmed: true)),
              ],
            ]),
          );
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final LibraryLoan loan;
  final bool dimmed;
  const _BookCard({required this.loan, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final overdue = loan.isOverdue;
    final statusColor = loan.returned ? AppColors.green : overdue ? AppColors.red : AppColors.amber;
    final statusText = loan.returned ? 'Returned' : overdue ? 'Overdue' : 'Borrowed';

    return Opacity(
      opacity: dimmed ? 0.65 : 1,
      child: WhiteCard(
        child: Row(children: [
          Container(
            width: 44, height: 58,
            decoration: BoxDecoration(
              color: AppColors.primaryExtraLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loan.bookTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1), maxLines: 2),
            if (loan.author != null) Text(loan.author!, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(
                loan.dueDate != null
                  ? loan.returned
                    ? '$statusText · ${DateFormat('d MMM').format(loan.dueDate!)}'
                    : '$statusText · Due ${DateFormat('d MMM').format(loan.dueDate!)}'
                  : statusText,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ),
          ])),
        ]),
      ),
    );
  }
}
