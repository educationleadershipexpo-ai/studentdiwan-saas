import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/curriculum_config.dart';
import '../core/gradebook_engine.dart';
import '../core/gradebook_approval.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Weighted-composite Gradebook — the mobile face of the desktop TeacherGradebook.
//
// ERP rule: nothing is typed in here. The engine (gradebook_engine.dart) pulls
// the real Assignment / Assessment / Exam marks a class already has and computes
// a weighted result per subject, using the active curriculum's band weights.
// The teacher picks class → subject → term, reads the composite, and drives the
// approval chain (Subject Teacher → Class Teacher → Grade Coordinator →
// Principal). A single cell can be corrected with a MarkOverride, which the
// engine always honours over the auto-pulled value.
//
// Real data only: an unmarked component shows "—", never a fabricated number.
// ─────────────────────────────────────────────────────────────────────────────
class GradebookScreen extends ConsumerStatefulWidget {
  const GradebookScreen({super.key});

  @override
  ConsumerState<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends ConsumerState<GradebookScreen> {
  String? _grade; // display form e.g. "Grade 3"
  String? _section; // e.g. "B"
  String? _subject; // null = pick one
  String? _term; // e.g. "Term 1"

  GradebookQuery? get _overviewQuery =>
      (_grade != null && _section != null) ? GradebookQuery(_grade!, _section!, term: _term) : null;

  GradebookQuery? get _subjectQuery => (_grade != null && _section != null && _subject != null)
      ? GradebookQuery(_grade!, _section!, term: _term, subject: _subject)
      : null;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(myClassesProvider);
    final curriculumAsync = ref.watch(activeCurriculumProvider);

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Gradebook',
            subtitle: 'Weighted composite — auto-pulled from real marks',
            showBackButton: true,
          ),
          Expanded(
            child: classesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => _ErrorState(msg: e.toString(), onRetry: () => ref.invalidate(myClassesProvider)),
              data: (classes) {
                if (classes.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.class_outlined,
                    title: 'No class assigned',
                    message: 'Your gradebook appears once you have a class to teach.',
                  );
                }
                // Default the selection to the first class the teacher owns.
                _ensureDefaults(classes, curriculumAsync.value);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(gradebookSourcesProvider);
                    ref.invalidate(myClassesProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      _selectors(classes, curriculumAsync.value),
                      const SizedBox(height: 20),
                      if (_subject == null)
                        const _HintCard(text: 'Pick a subject to see its weighted breakdown, KPIs and approval status.')
                      else
                        _subjectBody(),
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

  // Seed class/section/term/subject once from the real data so the view isn't
  // blank on first open — never fabricated, always the teacher's own first class.
  void _ensureDefaults(List<Map<String, dynamic>> classes, CurriculumConfig? curriculum) {
    if (_grade == null || _section == null) {
      final first = classes.first;
      _grade = (first['grade'] ?? '').toString();
      _section = (first['section'] ?? '').toString();
    }
    if (_term == null && curriculum != null) {
      final labels = getPeriodLabels(curriculum);
      if (labels.isNotEmpty) _term = labels.first;
    }
  }

  // ── selectors row ───────────────────────────────────────────────────────────
  Widget _selectors(List<Map<String, dynamic>> classes, CurriculumConfig? curriculum) {
    // Distinct class labels "Grade 3 · B".
    final classItems = <String, Map<String, String>>{};
    for (final c in classes) {
      final g = (c['grade'] ?? '').toString();
      final s = (c['section'] ?? '').toString();
      classItems['$g|$s'] = {'grade': g, 'section': s};
    }
    final termLabels = curriculum != null ? getPeriodLabels(curriculum) : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Dropdown<String>(
          label: 'CLASS',
          value: (_grade != null && _section != null) ? '$_grade|$_section' : null,
          items: [
            for (final e in classItems.entries)
              DropdownMenuItem(value: e.key, child: Text('${_gradeOnce(e.value['grade'])} · ${e.value['section']}')),
          ],
          onChanged: (v) {
            if (v == null) return;
            final parts = v.split('|');
            setState(() {
              _grade = parts[0];
              _section = parts.length > 1 ? parts[1] : '';
              _subject = null; // subjects depend on class
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _subjectDropdown()),
            const SizedBox(width: 12),
            Expanded(
              child: _Dropdown<String>(
                label: 'TERM',
                value: _term,
                items: [for (final t in termLabels) DropdownMenuItem(value: t, child: Text(t))],
                onChanged: (v) => setState(() => _term = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Subject options are the real subjects discovered for THIS class in the
  // gradebook sources — not a hard-coded list.
  Widget _subjectDropdown() {
    final q = _overviewQuery;
    if (q == null) {
      return _Dropdown<String>(label: 'SUBJECT', value: null, items: const [], onChanged: (_) {});
    }
    final overview = ref.watch(classGradebookProvider(q));
    final subjects = <String>{};
    for (final row in overview.value ?? const <StudentGradebook>[]) {
      for (final s in row.subjects) {
        subjects.add(s.subject);
      }
    }
    final sorted = subjects.toList()..sort();
    return _Dropdown<String>(
      label: 'SUBJECT',
      value: _subject,
      hint: overview.isLoading ? 'Loading…' : (sorted.isEmpty ? 'No marks yet' : 'Select'),
      items: [for (final s in sorted) DropdownMenuItem(value: s, child: Text(s))],
      onChanged: (v) => setState(() => _subject = v),
    );
  }

  // ── subject body: KPIs + workflow + table ───────────────────────────────────
  Widget _subjectBody() {
    final q = _subjectQuery!;
    final async = ref.watch(classGradebookProvider(q));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => _ErrorState(msg: e.toString(), onRetry: () => ref.invalidate(classGradebookProvider(q))),
      data: (rows) {
        final graded = rows.where((r) => r.subjects.any((s) => s.hasData)).toList();
        if (graded.isEmpty) {
          return const _EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No marks recorded',
            message: 'Grades appear here once assignments, assessments or exams are marked for this subject.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kpis(graded),
            const SizedBox(height: 16),
            _WorkflowBar(query: q),
            const SizedBox(height: 20),
            _distribution(graded),
            const SizedBox(height: 20),
            Text('Weighted breakdown', style: context.heading2),
            const SizedBox(height: 4),
            Text('$_subject · ${_gradeOnce(_grade)} · $_section · $_term',
                style: context.bodySmall),
            const SizedBox(height: 12),
            _CompositeTable(
              rows: graded,
              subject: _subject!,
              onOverride: (row, comp) => _openOverride(row, comp),
            ),
          ],
        );
      },
    );
  }

  Widget _kpis(List<StudentGradebook> rows) {
    // Each student's single-subject percentage lives in their one SubjectGrade.
    double subjectPct(StudentGradebook r) => r.subjects.isNotEmpty ? r.subjects.first.percentage : 0;
    final pcts = rows.map(subjectPct).toList();
    final classAvg = pcts.isEmpty ? 0.0 : pcts.reduce((a, b) => a + b) / pcts.length;
    final passRate = pcts.isEmpty ? 0.0 : pcts.where((p) => p >= 40).length / pcts.length;
    return Row(
      children: [
        Expanded(child: _RingCard(title: 'Students', percentage: 1, label: '${rows.length}', color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _RingCard(title: 'Class Avg', percentage: classAvg / 100, label: '${classAvg.toStringAsFixed(0)}%', color: AppColors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _RingCard(title: 'Pass Rate', percentage: passRate, label: '${(passRate * 100).toStringAsFixed(0)}%', color: AppColors.green)),
      ],
    );
  }

  Widget _distribution(List<StudentGradebook> rows) {
    const order = ['A+', 'A', 'B+', 'B', 'C', 'D', 'F'];
    final counts = {for (final g in order) g: 0};
    for (final r in rows) {
      final letter = r.subjects.isNotEmpty ? r.subjects.first.letter : '—';
      if (counts.containsKey(letter)) counts[letter] = counts[letter]! + 1;
    }
    final max = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grade distribution', style: context.heading3),
          const SizedBox(height: 14),
          for (final g in order)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(width: 26, child: Text(g, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.text2))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : counts[g]! / max,
                        minHeight: 10,
                        backgroundColor: AppColors.primaryExtraLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  SizedBox(width: 26, child: Text('${counts[g]}', textAlign: TextAlign.end, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.text3))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── override dialog ─────────────────────────────────────────────────────────
  Future<void> _openOverride(StudentGradebook row, ComponentScore comp) async {
    final controller = TextEditingController(
        text: comp.hasData ? (comp.obtainedPct / 100 * comp.weight).toStringAsFixed(0) : '');
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Override mark', style: context.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${row.name} · ${comp.category} (out of ${comp.weight})', style: context.bodySmall),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'New mark (0–${comp.weight})'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save override')),
        ],
      ),
    );
    if (result != true) return;
    final value = double.tryParse(controller.text.trim());
    if (value == null || value < 0 || value > comp.weight) {
      _snack('Enter a mark between 0 and ${comp.weight}.', isError: true);
      return;
    }
    final me = ref.read(authProvider).user?.displayName ?? 'Teacher';
    try {
      await MarkOverrideService.instance.saveMarkOverride(
        studentId: row.studentId,
        studentName: row.name,
        grade: _grade ?? '',
        section: _section ?? '',
        subject: _subject ?? '',
        term: _term ?? '',
        columnKey: columnKeyFor(comp.category),
        columnLabel: comp.category,
        originalValue: comp.hasData ? comp.obtainedPct / 100 * comp.weight : null,
        overrideValue: value,
        reason: reasonController.text.trim(),
        overriddenBy: me,
      );
      ref.invalidate(gradebookSourcesProvider);
      _snack('Override saved.');
    } catch (e) {
      _snack('Could not save override: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.red : AppColors.green,
    ));
  }

  // Render a grade value as "Grade 3" exactly once — never "Grade Grade 3".
  String _gradeOnce(String? g) {
    final raw = (g ?? '').toString().trim();
    if (raw.isEmpty) return 'Grade';
    final stripped = raw.replaceFirst(RegExp(r'^grade\s*', caseSensitive: false), '').trim();
    return 'Grade $stripped';
  }
}

// ── weighted composite table ───────────────────────────────────────────────────
class _CompositeTable extends StatelessWidget {
  final List<StudentGradebook> rows;
  final String subject;
  final void Function(StudentGradebook row, ComponentScore comp) onOverride;
  const _CompositeTable({required this.rows, required this.subject, required this.onOverride});

  @override
  Widget build(BuildContext context) {
    // Columns come from the first student's component list (same band for all).
    final sample = rows.firstWhere((r) => r.subjects.isNotEmpty, orElse: () => rows.first);
    final comps = sample.subjects.isNotEmpty ? sample.subjects.first.components : const <ComponentScore>[];

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.primarySurface),
          headingTextStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.text2),
          dataTextStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.text1),
          columnSpacing: 22,
          columns: [
            const DataColumn(label: Text('#')),
            const DataColumn(label: Text('STUDENT')),
            for (final c in comps) DataColumn(label: Text('${c.category.toUpperCase()}\n/${c.weight}')),
            const DataColumn(label: Text('TOTAL')),
            const DataColumn(label: Text('GRADE')),
          ],
          rows: [
            for (final r in rows.where((r) => r.subjects.isNotEmpty))
              DataRow(cells: [
                DataCell(Text('${r.rank}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.text3))),
                DataCell(SizedBox(width: 120, child: Text(r.name, overflow: TextOverflow.ellipsis))),
                for (final c in r.subjects.first.components)
                  DataCell(
                    _cell(c),
                    onTap: () => onOverride(r, c),
                  ),
                DataCell(Text('${r.subjects.first.percentage.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.text1))),
                DataCell(_gradePill(r.subjects.first.letter)),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _cell(ComponentScore c) {
    if (c.source == ComponentSource.pending) {
      return Text('n/a', style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3));
    }
    if (!c.hasData) {
      return const Text('—', style: TextStyle(color: AppColors.text3));
    }
    final obtained = c.obtainedPct / 100 * c.weight;
    return Text(obtained.toStringAsFixed(0), style: GoogleFonts.inter(fontWeight: FontWeight.w600));
  }

  Widget _gradePill(String letter) {
    final color = letter == '—' ? AppColors.text3 : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
      child: Text(letter, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: color, fontSize: 12)),
    );
  }
}

// ── approval workflow bar ──────────────────────────────────────────────────────
class _WorkflowBar extends ConsumerWidget {
  final GradebookQuery query;
  const _WorkflowBar({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gradebookSubmissionProvider(query));
    final status = async.value?.status ?? SubmissionStatus.draft;
    final returnReason = async.value?.returnReason;

    Color color;
    switch (status) {
      case SubmissionStatus.approvedByPrincipal:
        color = AppColors.green;
        break;
      case SubmissionStatus.returnedToSubjectTeacher:
        color = AppColors.red;
        break;
      case SubmissionStatus.draft:
        color = AppColors.text3;
        break;
      default:
        color = AppColors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Text('Approval status', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.text1)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(status.label, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, color: color)),
              ),
            ],
          ),
          if (returnReason != null && returnReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Returned: $returnReason', style: GoogleFonts.inter(fontSize: 12, color: AppColors.red)),
          ],
          const SizedBox(height: 12),
          _actions(context, ref, status, async.value),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, WidgetRef ref, SubmissionStatus status, GradebookSubmission? sub) {
    final me = ref.read(authProvider).user?.displayName ?? 'Teacher';
    final svc = GradebookApprovalService.instance;

    Future<void> run(Future<void> Function() action, String ok) async {
      try {
        await action();
        ref.invalidate(gradebookSubmissionProvider(query));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok), backgroundColor: AppColors.green));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.red));
        }
      }
    }

    // Subject Teacher can submit from Draft or a returned book.
    if (status == SubmissionStatus.draft || status == SubmissionStatus.returnedToSubjectTeacher) {
      return _btn('Submit to Class Teacher', Icons.send_rounded, () async {
        final classTeacher = await _promptName(context, 'Class Teacher name');
        if (classTeacher == null || classTeacher.isEmpty) return;
        await run(
          () => svc.submitToClassTeacher(
            grade: query.grade,
            section: query.section,
            subject: query.subject ?? '',
            term: query.term ?? '',
            subjectTeacherName: me,
            classTeacherName: classTeacher,
          ),
          'Submitted to Class Teacher.',
        );
      });
    }

    if (status == SubmissionStatus.submittedToClassTeacher && sub != null) {
      return Wrap(spacing: 10, runSpacing: 10, children: [
        _btn('Approve', Icons.check_rounded, () async {
          final coord = await _promptName(context, 'Grade Coordinator name');
          if (coord == null || coord.isEmpty) return;
          await run(() => svc.classTeacherApprove(submission: sub, classTeacherName: me, gradeCoordinatorName: coord), 'Approved — sent to Grade Coordinator.');
        }),
        _btn('Return', Icons.undo_rounded, () async {
          final reason = await _promptName(context, 'Reason for return');
          if (reason == null || reason.isEmpty) return;
          await run(() => svc.classTeacherReturn(submission: sub, classTeacherName: me, reason: reason), 'Returned to Subject Teacher.', );
        }, outlined: true),
      ]);
    }

    if (status == SubmissionStatus.submittedToGradeCoordinator && sub != null) {
      return _btn('Approve as Coordinator', Icons.check_rounded, () async {
        var principal = await svc.getPrincipalName();
        if ((principal == null || principal.isEmpty) && context.mounted) {
          principal = await _promptName(context, 'Principal name');
        }
        if (principal == null || principal.isEmpty) return;
        await run(() => svc.gradeCoordinatorApprove(submission: sub, gradeCoordinatorName: me, principalName: principal!), 'Approved — sent to Principal.');
      });
    }

    if (status == SubmissionStatus.submittedToPrincipal && sub != null) {
      return _btn('Grant final approval', Icons.verified_rounded, () async {
        await run(() => svc.principalApprove(submission: sub, principalName: me), 'Gradebook fully approved.');
      });
    }

    if (status == SubmissionStatus.approvedByPrincipal) {
      return Row(children: [
        const Icon(Icons.lock_rounded, size: 16, color: AppColors.green),
        const SizedBox(width: 6),
        Text('Locked — fully approved', style: GoogleFonts.inter(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w600)),
      ]);
    }

    // Any other stage has no action for the current viewer — the status chip
    // above already conveys where the book sits in the chain.
    return const SizedBox.shrink();
  }

  Widget _btn(String label, IconData icon, VoidCallback onTap, {bool outlined = false}) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: AppColors.red),
        label: Text(label, style: const TextStyle(color: AppColors.red)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.red)),
      );
    }
    return ElevatedButton.icon(onPressed: onTap, icon: Icon(icon, size: 16), label: Text(label));
  }

  Future<String?> _promptName(BuildContext context, String label) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Confirm')),
        ],
      ),
    );
  }
}

// ── small building blocks ──────────────────────────────────────────────────────
class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          hint: hint != null ? Text(hint!, style: context.bodySmall) : null,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        ),
      ],
    );
  }
}

class _RingCard extends StatelessWidget {
  final String title;
  final double percentage;
  final String label;
  final Color color;
  const _RingCard({required this.title, required this.percentage, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      child: Column(
        children: [
          Text(title, style: context.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: CircularProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  strokeWidth: 5,
                  backgroundColor: color.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String text;
  const _HintCard({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: context.body)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _EmptyState({required this.icon, required this.title, required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.text3),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorState({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.red),
            const SizedBox(height: 12),
            Text('Could not load gradebook', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
            const SizedBox(height: 6),
            Text(msg, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
