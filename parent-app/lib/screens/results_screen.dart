import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final marksAsync = ref.watch(examMarksProvider(kid.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBackHeader(title: 'Academic Results'),
      body: marksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(message: 'Failed to load results', onRetry: () => ref.invalidate(examMarksProvider(kid.id))),
        data: (marks) {
          if (marks.isEmpty) return const EmptyState(icon: Icons.bar_chart_rounded, title: 'No Results', subtitle: 'Exam results will appear here once published.');
          final avg = marks.fold(0.0, (s, m) => s + m.percentage) / marks.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(children: [
              GradientCard(
                child: Column(children: [
                  Text('${avg.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                  const SizedBox(height: 4),
                  Text('Overall Performance · ${kid.fullName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              const SectionHeader(title: 'Subject Results'),
              ...marks.map((m) {
                final p = m.percentage;
                final Color c = p >= 85 ? AppColors.green : p >= 70 ? AppColors.blue : p >= 60 ? AppColors.amber : AppColors.red;
                return WhiteCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(m.subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(m.letterGrade, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: c)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: (p / 100).clamp(0.0, 1.0), backgroundColor: AppColors.primarySurface,
                        valueColor: AlwaysStoppedAnimation(c), minHeight: 6),
                    ),
                    const SizedBox(height: 5),
                    Text('${m.marks.toInt()} / ${m.maxMarks.toInt()}${m.teacherName != null ? ' · ${m.teacherName}' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w600)),
                  ]),
                );
              }),
            ]),
          );
        },
      ),
    );
  }
}
