import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));

    final asgAsync = ref.watch(assignmentsProvider(kid));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: const AppBackHeader(title: 'Assignments'),
      body: asgAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(message: 'Failed to load assignments', onRetry: () => ref.invalidate(assignmentsProvider(kid))),
        data: (assignments) {
          if (assignments.isEmpty) return const EmptyState(icon: Icons.edit_note_rounded, title: 'No Assignments', subtitle: 'No assignments found for this student.');
          final pending = assignments.where((a) => !a.submitted).toList();
          final done = assignments.where((a) => a.submitted).toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(children: [
              if (pending.isNotEmpty) ...[
                const SectionHeader(title: 'Pending'),
                ...pending.map((a) => _AsgnCard(assignment: a)),
              ],
              if (done.isNotEmpty) ...[
                const SectionHeader(title: 'Completed'),
                ...done.map((a) => _AsgnCard(assignment: a, dimmed: true)),
              ],
            ]),
          );
        },
      ),
    );
  }
}

class _AsgnCard extends StatelessWidget {
  final AssignmentModel assignment;
  final bool dimmed;
  const _AsgnCard({required this.assignment, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    // Status mirrors desktop: Graded > Submitted > Overdue > Pending.
    final status = assignment.status;
    final graded = status == 'Graded';
    final submitted = status == 'Submitted';
    final overdue = status == 'Overdue';
    final done = graded || submitted;

    final Color iconBg = graded
        ? AppColors.blueLight
        : submitted
            ? AppColors.greenLight
            : overdue
                ? AppColors.redLight
                : AppColors.amberLight;
    final Color iconClr = graded
        ? AppColors.blue
        : submitted
            ? AppColors.green
            : overdue
                ? AppColors.red
                : AppColors.amber;
    final IconData icon = graded
        ? Icons.grading_rounded
        : submitted
            ? Icons.check_rounded
            : Icons.edit_outlined;
    // Pending shows the due date inline; resolved states show the status word.
    final String label = (!done && !overdue && assignment.dueDate != null)
        ? 'Due ${DateFormat('d MMM').format(assignment.dueDate!)}'
        : status;

    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: WhiteCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconClr, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(assignment.subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text3)),
              const SizedBox(height: 2),
              Text(assignment.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
              child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: iconClr)),
            ),
          ]),
          // Teacher feedback only appears when a real graded submission carries it.
          if (assignment.feedback != null && assignment.feedback!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.format_quote_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(assignment.feedback!,
                    style: const TextStyle(fontSize: 11, color: AppColors.text2, height: 1.4))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
