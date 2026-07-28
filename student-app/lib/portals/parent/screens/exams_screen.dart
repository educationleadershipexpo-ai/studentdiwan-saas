import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class ExamsScreen extends ConsumerWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final examsAsync = ref.watch(examsProvider(kid));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBackHeader(title: 'Exams · ${kid.firstName}'),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(message: 'Failed to load exams', onRetry: () => ref.invalidate(examsProvider(kid))),
        data: (exams) {
          if (exams.isEmpty) return const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No Exams Scheduled',
            subtitle: 'Upcoming exams will appear here.',
          );

          final now = DateTime.now();
          // An exam is "upcoming" if its date is today or in the future.
          // Dates from the API are parsed as midnight, so isBefore(now) would
          // be true for today — using isSameDay guards against that.
          final upcoming = exams.where((e) =>
            e.date != null &&
            (e.date!.isAfter(now) || DateUtils.isSameDay(e.date!, now))
          ).toList()..sort((a, b) => a.date!.compareTo(b.date!));
          // Past = explicitly dated in the past. Undated exams go here too.
          final past = exams.where((e) =>
            e.date == null ||
            (e.date!.isBefore(now) && !DateUtils.isSameDay(e.date!, now))
          ).toList()..sort((a, b) => (b.date ?? now).compareTo(a.date ?? now));

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(children: [
              if (upcoming.isNotEmpty) ...[
                const SectionHeader(title: 'Upcoming'),
                ...upcoming.map((e) => _ExamCard(exam: e)),
              ],
              if (past.isNotEmpty) ...[
                const SectionHeader(title: 'Past Exams'),
                ...past.map((e) => _ExamCard(exam: e, isPast: true)),
              ],
            ]),
          );
        },
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final bool isPast;
  const _ExamCard({required this.exam, this.isPast = false});

  String get _examType {
    final n = exam.name.toLowerCase();
    if (n.contains('final') || n.contains('annual')) return 'Final';
    if (n.contains('mid') || n.contains('midterm')) return 'Mid Term';
    if (n.contains('unit') || n.contains('test')) return 'Unit Test';
    if (n.contains('quiz')) return 'Quiz';
    return 'Exam';
  }

  Color get _typeColor {
    final t = _examType.toLowerCase();
    if (t.contains('final') || t.contains('annual')) return AppColors.red;
    if (t.contains('mid') || t.contains('term')) return AppColors.amber;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final daysUntil = exam.date != null && !isPast
        ? exam.date!.difference(DateTime.now()).inDays
        : null;
    // A released result exists only when a real mark was found for this
    // child+subject (see examsProvider) — never fabricated.
    final released = exam.score != null && exam.totalMarks != null;

    return WhiteCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: _typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (exam.date != null) ...[
              Text(DateFormat('d').format(exam.date!),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _typeColor)),
              Text(DateFormat('MMM').format(exam.date!).toUpperCase(),
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _typeColor, letterSpacing: 0.5)),
            ] else
              Icon(Icons.assignment_outlined, color: _typeColor, size: 22),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exam.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
          const SizedBox(height: 3),
          Wrap(spacing: 6, runSpacing: 3, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: _typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
              child: Text(_examType, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _typeColor)),
            ),
            if (exam.mode != null && exam.mode!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(5)),
                child: Text(exam.mode!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            if (exam.subject != null)
              Text(exam.subject!, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
          ]),
          if (exam.time != null || exam.venue != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              if (exam.time != null) ...[
                const Icon(Icons.schedule_rounded, size: 11, color: AppColors.text3),
                const SizedBox(width: 3),
                Text(exam.time!, style: const TextStyle(fontSize: 10, color: AppColors.text3)),
                const SizedBox(width: 8),
              ],
              if (exam.venue != null)
                Expanded(child: Row(children: [
                  const Icon(Icons.location_on_outlined, size: 11, color: AppColors.text3),
                  const SizedBox(width: 3),
                  Expanded(child: Text(exam.venue!,
                      style: const TextStyle(fontSize: 10, color: AppColors.text3), overflow: TextOverflow.ellipsis)),
                ])),
            ]),
          ],
        ])),
        const SizedBox(width: 8),
        // Released result takes precedence over the days-until badge.
        if (released)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${_fmt(exam.score!)}/${_fmt(exam.totalMarks!)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.text1)),
            if (exam.letter != null)
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: exam.letter!.startsWith('A') ? AppColors.greenLight : AppColors.blueLight,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(exam.letter!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: exam.letter!.startsWith('A') ? AppColors.green : AppColors.blue)),
              ),
          ])
        else if (daysUntil != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: daysUntil <= 3 ? AppColors.redLight : AppColors.primaryExtraLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysUntil == 0 ? 'Today' : daysUntil == 1 ? 'Tomorrow' : '${daysUntil}d',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800,
                color: daysUntil <= 3 ? AppColors.red : AppColors.primary,
              ),
            ),
          ),
      ]),
    );
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
