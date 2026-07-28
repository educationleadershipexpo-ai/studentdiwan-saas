import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';
import '../../teacher/core/gradebook_engine.dart' as gb;

// ─────────────────────────────────────────────────────────────────────────────
// Parent Gradebook — the child's WEIGHTED composite, identical to what the
// teacher/admin gradebook and the desktop ParentGradebook.tsx compute. Nothing
// is entered here: the shared engine auto-pulls the child's real Assignment,
// Assessment and Exam marks and weights each by the active curriculum's band for
// the child's grade. An unmarked component contributes nothing (shown as "—"),
// never a fabricated number. A term selector mirrors the desktop so the figures
// line up with a per-term report card.
// ─────────────────────────────────────────────────────────────────────────────
class GradebookScreen extends ConsumerStatefulWidget {
  const GradebookScreen({super.key});

  @override
  ConsumerState<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends ConsumerState<GradebookScreen> {
  String? _term; // null until terms load; then defaults to the first term

  @override
  Widget build(BuildContext context) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));

    final terms = ref.watch(parentTermLabelsProvider).value ?? const <String>[];
    if (_term == null && terms.isNotEmpty) _term = terms.first;

    final query = ParentGradebookQuery(kid, term: _term);
    final async = ref.watch(parentGradebookProvider(query));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: const AppBackHeader(title: 'Gradebook'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(
          message: 'Failed to load marks',
          onRetry: () => ref.invalidate(parentGradebookProvider(query)),
        ),
        data: (book) {
          final graded = book.subjects.where((s) => s.hasData).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(parentGradebookSourcesProvider);
              ref.invalidate(parentGradebookProvider(query));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (terms.length > 1) ...[
                  _termSelector(terms),
                  const SizedBox(height: 14),
                ],
                if (graded.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyState(
                      icon: Icons.bar_chart_rounded,
                      title: 'No marks recorded yet',
                      subtitle:
                          'Once teachers grade assignments, assessments or exams, the calculated grades appear here automatically.',
                    ),
                  )
                else ...[
                  _overallCard(book, graded),
                  const SizedBox(height: 8),
                  _banner(kid.gradeLabel),
                  const SectionHeader(title: 'Subject Results'),
                  ...graded.map((s) => _SubjectCard(subject: s)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _termSelector(List<String> terms) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          const Text('Term', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text2)),
          const Spacer(),
          DropdownButton<String>(
            value: _term,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(12),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1),
            items: [for (final t in terms) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _term = v),
          ),
        ]),
      );

  Widget _overallCard(gb.StudentGradebook book, List<gb.SubjectGrade> graded) {
    final avg = book.overallPercentage;
    final top = graded.reduce((a, b) => a.percentage >= b.percentage ? a : b);
    final low = graded.reduce((a, b) => a.percentage <= b.percentage ? a : b);
    return GradientCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text('${avg.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
        const SizedBox(height: 4),
        Text('Weighted Average · ${book.overallLetter}',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _MiniStat(_first(top.subject), 'Strongest', AppColors.green),
          const SizedBox(width: 16),
          _MiniStat(_first(low.subject), 'Needs Work', AppColors.amberLight),
          const SizedBox(width: 16),
          _MiniStat('${graded.length}', 'Subjects', Colors.white),
        ]),
      ]),
    );
  }

  Widget _banner(String gradeLabel) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Auto-pulled and weighted from $gradeLabel Assignments, Assessments and Exams — the same figures teachers record.',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ]),
      );

  String _first(String subject) => subject.split(' ').first;
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MiniStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
            overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600)),
      ]);
}

class _SubjectCard extends StatelessWidget {
  final gb.SubjectGrade subject;
  const _SubjectCard({required this.subject});

  Color get _gradeColor {
    final p = subject.percentage;
    if (p >= 85) return AppColors.green;
    if (p >= 70) return AppColors.blue;
    if (p >= 60) return AppColors.amber;
    return AppColors.red;
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final pct = subject.percentage;
    return WhiteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(subject.subject,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: _gradeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(subject.letter, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _gradeColor)),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.primarySurface,
            valueColor: AlwaysStoppedAnimation(_gradeColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        // Weighted component breakdown — each category's obtained/weight, or "—"
        // when that component has no marks yet (honest, never fabricated).
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final c in subject.components)
              if (c.source != gb.ComponentSource.pending)
                _chip(
                  c.category,
                  c.hasData ? '${_fmt(c.obtainedPct / 100 * c.weight)}/${c.weight}' : '—/${c.weight}',
                  c.hasData,
                ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Total ${pct.toStringAsFixed(0)}% · weighted composite',
            style: const TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _chip(String label, String value, bool has) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: has ? AppColors.primaryExtraLight : AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text.rich(TextSpan(children: [
          TextSpan(
              text: '$label ',
              style: TextStyle(
                  fontSize: 10.5, color: has ? AppColors.primary : AppColors.text3, fontWeight: FontWeight.w600)),
          TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: 10.5, color: has ? AppColors.text1 : AppColors.text3, fontWeight: FontWeight.w800)),
        ])),
      );
}
