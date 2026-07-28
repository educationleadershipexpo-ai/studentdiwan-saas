import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../portals/teacher/core/gradebook_engine.dart' as gb;

// ─────────────────────────────────────────────────────────────────────────────
// Student Gradebook — my OWN weighted composite, computed by the same shared
// engine the teacher/admin gradebook and the desktop use. Nothing is typed here:
// the engine auto-pulls my real Assignment, Assessment and Exam marks and weights
// each by the active curriculum's band for my grade. An unmarked component
// contributes nothing (shown as "—/weight"), never a fabricated number. The term
// selector mirrors the desktop so figures line up with a per-term report card.
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
    final terms = ref.watch(studentTermLabelsProvider).value ?? const <String>[];
    if (_term == null && terms.isNotEmpty) _term = terms.first;

    final async = ref.watch(studentGradebookProvider(_term));

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => _errorState(),
              data: (book) {
                final graded =
                    book.subjects.where((s) => s.hasData).toList();
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(studentGradebookSourcesProvider);
                    ref.invalidate(studentGradebookProvider(_term));
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      if (terms.length > 1) ...[
                        _termSelector(terms),
                        const SizedBox(height: 14),
                      ],
                      if (graded.isEmpty)
                        _emptyState()
                      else ...[
                        _overallCard(book, graded),
                        _banner(),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(left: 4, top: 8, bottom: 4),
                          child: Text('Subject Results',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text1)),
                        ),
                        ...graded.map((s) => _SubjectCard(subject: s)),
                      ],
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

  // ── Purple gradient header (matches the student portal look) ───────────────
  Widget _header() => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 20,
            left: 8,
            right: 20),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/dashboard'),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gradebook',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('Your weighted subject grades',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.grading_rounded, color: Colors.white, size: 26),
          ],
        ),
      );

  Widget _termSelector(List<String> terms) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryExtraLight)),
        child: Row(children: [
          const Icon(Icons.event_note_rounded,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          const Text('Term',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text2)),
          const Spacer(),
          DropdownButton<String>(
            value: _term,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(12),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text1),
            items: [
              for (final t in terms)
                DropdownMenuItem(value: t, child: Text(t))
            ],
            onChanged: (v) => setState(() => _term = v),
          ),
        ]),
      );

  Widget _overallCard(gb.StudentGradebook book, List<gb.SubjectGrade> graded) {
    final avg = book.overallPercentage;
    final top = graded.reduce((a, b) => a.percentage >= b.percentage ? a : b);
    final low = graded.reduce((a, b) => a.percentage <= b.percentage ? a : b);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text('${avg.toStringAsFixed(1)}%',
            style: const TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1)),
        const SizedBox(height: 4),
        Text('Weighted Average · ${book.overallLetter}',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _MiniStat(_first(top.subject), 'Strongest', AppColors.greenLight),
          const SizedBox(width: 16),
          _MiniStat(_first(low.subject), 'Needs Work', AppColors.amberLight),
          const SizedBox(width: 16),
          _MiniStat('${graded.length}', 'Subjects', Colors.white),
        ]),
      ]),
    );
  }

  Widget _banner() => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: AppColors.primaryExtraLight,
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Auto-pulled and weighted from your Assignments, Assessments and Exams — the same figures your teachers record. Only marked work counts.',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
          ),
        ]),
      );

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: const [
            Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.text3),
            SizedBox(height: 14),
            Text('No marks recorded yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text2)),
            SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Once teachers grade your assignments, assessments or exams, your calculated grades appear here automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.text3, height: 1.4),
              ),
            ),
          ],
        ),
      );

  Widget _errorState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.text3),
            const SizedBox(height: 12),
            const Text('Could not load your gradebook right now.',
                style: TextStyle(color: AppColors.text3)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.invalidate(studentGradebookSourcesProvider);
                ref.invalidate(studentGradebookProvider(_term));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
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
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w900, color: color),
            overflow: TextOverflow.ellipsis),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.white60,
                fontWeight: FontWeight.w600)),
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

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final pct = subject.percentage;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(subject.subject,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: _gradeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text(subject.letter,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _gradeColor)),
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
        const SizedBox(height: 10),
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
                  c.hasData
                      ? '${_fmt(c.obtainedPct / 100 * c.weight)}/${c.weight}'
                      : '—/${c.weight}',
                  c.hasData,
                ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Total ${pct.toStringAsFixed(0)}% · weighted composite',
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.text3,
                fontWeight: FontWeight.w600)),
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
                  fontSize: 10.5,
                  color: has ? AppColors.primary : AppColors.text3,
                  fontWeight: FontWeight.w600)),
          TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: 10.5,
                  color: has ? AppColors.text1 : AppColors.text3,
                  fontWeight: FontWeight.w800)),
        ])),
      );
}
