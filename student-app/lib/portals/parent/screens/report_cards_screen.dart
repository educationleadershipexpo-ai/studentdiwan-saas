import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class ReportCardsScreen extends ConsumerWidget {
  const ReportCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final rcAsync = ref.watch(reportCardsProvider(kid.id));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBackHeader(title: 'Report Cards · ${kid.firstName}'),
      body: rcAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(message: 'Failed to load report cards', onRetry: () => ref.invalidate(reportCardsProvider(kid.id))),
        data: (cards) {
          if (cards.isEmpty) return const EmptyState(
            icon: Icons.grade_outlined,
            title: 'No Report Cards Yet',
            subtitle: 'Report cards will appear here once published by the school.',
          );

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: cards.length,
            itemBuilder: (_, i) => _ReportCard(card: cards[i]),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final ReportCard card;
  const _ReportCard({required this.card});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _expanded = false;

  Color _gradeColor(String? grade) {
    if (grade == null) return AppColors.text3;
    final g = grade.toUpperCase();
    if (g.startsWith('A')) return AppColors.green;
    if (g.startsWith('B')) return AppColors.blue;
    if (g.startsWith('C')) return AppColors.amber;
    return AppColors.red;
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  // One subject's row: name · progress bar · obtained/max · letter pill.
  Widget _subjectRow(ReportCardSubject s) {
    final barColor = s.pct >= 80 ? AppColors.green : s.pct >= 60 ? AppColors.amber : AppColors.red;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 96,
          child: Text(s.subject,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (s.pct / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.primarySurface,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 54,
          child: Text('${_fmt(s.obtained)}/${_fmt(s.max)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: AppColors.text3)),
        ),
        const SizedBox(width: 6),
        Container(
          width: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(color: _gradeColor(s.letter).withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
          child: Text(s.letter,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _gradeColor(s.letter))),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final pct = card.percentage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.grade_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(card.term, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text1)),
                if (card.year.isNotEmpty)
                  Text(card.year, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
              ])),
              if (pct != null) ...[
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  if (card.overallGrade != null) Text(card.overallGrade!,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _gradeColor(card.overallGrade))),
                ]),
                const SizedBox(width: 8),
              ],
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: AppColors.text3, size: 20),
            ]),
          ),
        ),
        if (_expanded) ...[
          const Divider(height: 1, color: AppColors.primarySurface),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (pct != null) ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Overall Score', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                  Text('${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.primarySurface,
                    valueColor: AlwaysStoppedAnimation(
                      pct >= 75 ? AppColors.green : pct >= 50 ? AppColors.amber : AppColors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (card.rank != null && card.totalStudents != null) ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Class Rank', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                  Text('${card.rank} of ${card.totalStudents}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
                ]),
                const SizedBox(height: 12),
              ],
              // Per-subject grades — the official subject-wise breakdown from
              // the published report card (identical to the desktop table).
              if (card.subjects.isNotEmpty) ...[
                const Text('Subject Grades', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 0.4)),
                const SizedBox(height: 8),
                ...card.subjects.map((s) => _subjectRow(s)),
                const SizedBox(height: 12),
              ],
              if (card.teacherComments != null && card.teacherComments!.isNotEmpty) ...[
                const Text("Teacher's Comments", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 0.4)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(card.teacherComments!,
                      style: const TextStyle(fontSize: 12, color: AppColors.text2, height: 1.5))),
                  ]),
                ),
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}
