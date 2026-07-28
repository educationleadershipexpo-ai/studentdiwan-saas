import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class GradebookScreen extends ConsumerWidget {
  const GradebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final marksAsync = ref.watch(examMarksProvider(kid.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBackHeader(title: 'Gradebook'),
      body: marksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(message: 'Failed to load marks', onRetry: () => ref.invalidate(examMarksProvider(kid.id))),
        data: (marks) {
          if (marks.isEmpty) return const EmptyState(icon: Icons.bar_chart_rounded, title: 'No Marks Available');
          final avg = marks.fold(0.0, (s, m) => s + m.percentage) / marks.length;
          final highest = marks.reduce((a, b) => a.marks > b.marks ? a : b);
          final lowest = marks.reduce((a, b) => a.marks < b.marks ? a : b);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(children: [
              GradientCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text('${avg.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                  const SizedBox(height: 4),
                  const Text('Academic Average', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _MiniStat('${highest.marks.toInt()}', 'Highest', AppColors.green),
                    const SizedBox(width: 16),
                    _MiniStat('${lowest.marks.toInt()}', 'Lowest', AppColors.red),
                    const SizedBox(width: 16),
                    _MiniStat('${marks.length}', 'Subjects', Colors.white),
                  ]),
                ]),
              ),
              const SectionHeader(title: 'Subject Results'),
              ...marks.map((m) => _MarkCard(mark: m)),
            ]),
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MiniStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600)),
  ]);
}

class _MarkCard extends StatelessWidget {
  final ExamMarkModel mark;
  const _MarkCard({required this.mark});

  Color get _gradeColor {
    final p = mark.percentage;
    if (p >= 85) return AppColors.green;
    if (p >= 70) return AppColors.blue;
    if (p >= 60) return AppColors.amber;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) => WhiteCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(mark.subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: _gradeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(mark.letterGrade, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _gradeColor)),
        ),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (mark.percentage / 100).clamp(0.0, 1.0),
          backgroundColor: AppColors.primarySurface,
          valueColor: AlwaysStoppedAnimation(_gradeColor),
          minHeight: 6,
        ),
      ),
      const SizedBox(height: 6),
      Text('${mark.marks.toInt()} / ${mark.maxMarks.toInt()}${mark.teacherName != null ? ' · ${mark.teacherName}' : ''}',
        style: const TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w600)),
    ]),
  );
}
