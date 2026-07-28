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
      backgroundColor: AppColors.background,
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
    final overdue = assignment.isOverdue;
    final done = assignment.submitted;
    final Color iconBg = done ? AppColors.greenLight : overdue ? AppColors.redLight : AppColors.amberLight;
    final Color iconClr = done ? AppColors.green : overdue ? AppColors.red : AppColors.amber;
    final String status = done ? 'Done' : overdue ? 'Overdue' : assignment.dueDate != null ? 'Due ${DateFormat('d MMM').format(assignment.dueDate!)}' : 'Pending';

    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: WhiteCard(
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(done ? Icons.check_rounded : Icons.edit_outlined, color: iconClr, size: 18),
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
            child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: iconClr)),
          ),
        ]),
      ),
    );
  }
}
