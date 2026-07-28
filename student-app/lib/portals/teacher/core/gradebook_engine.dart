// ─────────────────────────────────────────────────────────────────────────────
// Unified Gradebook compute engine — a faithful Dart port of the desktop
// `src/lib/gradebookEngine.ts`. The single source of truth for grades.
//
// ERP rule: NO marks are entered directly into the gradebook. This engine
// AUTO-PULLS the real marks a school already produces and computes a weighted
// result per subject:
//
//   • Assignment marks  ← `assignment_submissions` ⋈ `TeacherAssignment`
//   • Assessment marks  ← `assessment_attempts`    ⋈ `assessments`
//   • Exam marks        ← `exam_marks`             ⋈ `exams`
//
// Weights come from the active curriculum's gradebook band for the student's
// grade (curriculum_config.dart). Categories with no automated source
// (Projects, Participation…) are reported as "pending" and excluded from the
// normalised percentage, so a partially-marked term still produces a fair
// score. A human-reviewed MarkOverride always wins over the auto-computed value.
//
// Real data only: an ungraded cell contributes nothing; it is never fabricated.
// ─────────────────────────────────────────────────────────────────────────────
import 'curriculum_config.dart';

// Which real store feeds a band category, inferred from its name / exam flag.
enum ComponentSource { assignment, assessment, exam, pending }

ComponentSource categorySource(GradebookCategory cat) {
  if (cat.isExam) return ComponentSource.exam;
  final n = cat.name.toLowerCase();
  if (RegExp(r'assign|homework').hasMatch(n)) return ComponentSource.assignment;
  if (RegExp(r'assess|quiz|class test|test').hasMatch(n)) return ComponentSource.assessment;
  // Projects, Participation, Observation, Activities … no automated feed yet.
  return ComponentSource.pending;
}

String letterFromPct(double p) {
  if (p >= 90) return 'A+';
  if (p >= 80) return 'A';
  if (p >= 70) return 'B+';
  if (p >= 60) return 'B';
  if (p >= 50) return 'C';
  if (p >= 40) return 'D';
  return 'F';
}

String _normGrade(String? g) => (g ?? '').toLowerCase().replaceAll('grade ', '').trim();
String _normSec(String? s) =>
    (s ?? '').trim().replaceFirst(RegExp(r'^sec(tion)?\b\.?\s*', caseSensitive: false), '').toUpperCase();

double _clampPct(double v) => v < 0 ? 0 : (v > 100 ? 100 : v);
double _toNum(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}') ?? 0;
}

/// A student the engine computes for.
class GradebookStudent {
  final String id;
  final String name;
  final String grade;
  final String section;
  const GradebookStudent({required this.id, required this.name, required this.grade, required this.section});
}

// Does a grade/section-scoped item apply to this student?
bool _appliesTo(String? itemGrade, String? itemSection, GradebookStudent student) {
  if (_normGrade(itemGrade) != _normGrade(student.grade)) return false;
  final sec = _normSec(itemSection);
  if (sec.isEmpty || sec == 'ALL' || sec == 'ALL SECTIONS') return true;
  return sec == _normSec(student.section);
}

/// One assessment component's contribution to a subject's 100-mark total.
class ComponentScore {
  final String category;
  final int weight;
  final ComponentSource source;
  final double obtainedPct; // 0..100
  final double weighted; // obtainedPct/100 * weight
  final int count; // graded items that contributed
  final bool hasData; // false → pending / not yet marked
  const ComponentScore({
    required this.category,
    required this.weight,
    required this.source,
    required this.obtainedPct,
    required this.weighted,
    required this.count,
    required this.hasData,
  });
}

/// A computed subject grade for a student.
class SubjectGrade {
  final String subject;
  final List<ComponentScore> components;
  final int presentWeight; // sum of weights of components that have data
  final double obtainedWeighted; // sum of weighted (out of 100)
  final double percentage; // normalised by presentWeight, 0..100
  final String letter;
  final bool hasData;
  const SubjectGrade({
    required this.subject,
    required this.components,
    required this.presentWeight,
    required this.obtainedWeighted,
    required this.percentage,
    required this.letter,
    required this.hasData,
  });
}

/// A manual mark correction — mirrors desktop MarkOverride.
class MarkOverride {
  final String id; // `${studentId}|${subject}|${columnKey}|${term}`
  final String studentId;
  final String studentName;
  final String grade;
  final String section;
  final String subject;
  final String term;
  final String columnKey;
  final String columnLabel;
  final double? originalValue;
  final double overrideValue;
  final String reason;
  final String overriddenBy;
  const MarkOverride({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.section,
    required this.subject,
    required this.term,
    required this.columnKey,
    required this.columnLabel,
    required this.originalValue,
    required this.overrideValue,
    required this.reason,
    required this.overriddenBy,
  });

  factory MarkOverride.fromJson(Map<String, dynamic> j) => MarkOverride(
        id: (j['id'] ?? '').toString(),
        studentId: (j['studentId'] ?? '').toString(),
        studentName: (j['studentName'] ?? '').toString(),
        grade: (j['grade'] ?? '').toString(),
        section: (j['section'] ?? '').toString(),
        subject: (j['subject'] ?? '').toString(),
        term: (j['term'] ?? '').toString(),
        columnKey: (j['columnKey'] ?? '').toString(),
        columnLabel: (j['columnLabel'] ?? '').toString(),
        originalValue: j['originalValue'] == null ? null : _toNum(j['originalValue']),
        overrideValue: _toNum(j['overrideValue']),
        reason: (j['reason'] ?? '').toString(),
        overriddenBy: (j['overriddenBy'] ?? '').toString(),
      );
}

/// All raw sources the engine computes from — fetched once, computed many.
class GradebookSources {
  final List<Map<String, dynamic>> assignments; // TeacherAssignment
  final List<Map<String, dynamic>> submissions; // assignment_submissions
  final List<Map<String, dynamic>> assessments;
  final List<Map<String, dynamic>> attempts; // assessment_attempts
  final List<Map<String, dynamic>> exams;
  // examId → subject → studentId → mark
  final Map<String, Map<String, Map<String, double>>> examMarks;
  final List<MarkOverride> overrides;
  const GradebookSources({
    required this.assignments,
    required this.submissions,
    required this.assessments,
    required this.attempts,
    required this.exams,
    required this.examMarks,
    required this.overrides,
  });
}

// exam_marks blob meta keys (mirrors data_provider._examMarkMetaKeys).
const _examMarkMetaKeys = {'id', 'uid', 'createdby', 'createdat', 'updatedat', 'updatedby'};

/// Build the examId→subject→student→mark cache from raw `exam_marks` rows.
Map<String, Map<String, Map<String, double>>> buildExamMarks(List<Map<String, dynamic>> rows) {
  final cache = <String, Map<String, Map<String, double>>>{};
  for (final row in rows) {
    final id = (row['id'] ?? '').toString();
    if (id.isEmpty) continue;
    final byExam = cache.putIfAbsent(id, () => {});
    row.forEach((subject, byStudent) {
      if (_examMarkMetaKeys.contains(subject.toLowerCase())) return;
      if (byStudent is! Map) return;
      final bySubject = byExam.putIfAbsent(subject, () => {});
      byStudent.forEach((sid, mark) {
        final v = (mark is num) ? mark.toDouble() : double.tryParse('${mark ?? ''}');
        if (v != null) bySubject[sid.toString()] = v;
      });
    });
  }
  return cache;
}

// ── exam grade-plan resolution (ports examStore getGradePlans/matchesSection) ──

List<Map<String, dynamic>> _gradePlans(Map<String, dynamic> exam) {
  final plans = exam['gradePlans'];
  if (plans is List && plans.isNotEmpty) {
    return plans.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
  return [
    {
      'grade': exam['grade'],
      'section': exam['section'],
      'sections': exam['sections'],
      'subjects': exam['subjects'],
      'slots': exam['slots'],
    }
  ];
}

bool _matchesSection(Map<String, dynamic> exam, String grade, String section) {
  final wantGrade = _normGrade(grade);
  final want = _normSec(section);
  for (final plan in _gradePlans(exam)) {
    if (_normGrade(plan['grade']?.toString()) != wantGrade) continue;
    if (want.isEmpty || want == 'ALL SECTIONS') return true;
    final have = _normSec(plan['section']?.toString());
    if (have == 'ALL SECTIONS' || have == want) return true;
  }
  return false;
}

// A multi-grade exam's top-level slots mirror the FIRST plan only; resolve the
// plan that actually matches the student before reading its subject slots.
List<Map<String, dynamic>> _slotsForStudent(Map<String, dynamic> exam, GradebookStudent student) {
  for (final plan in _gradePlans(exam)) {
    if (_normGrade(plan['grade']?.toString()) == _normGrade(student.grade)) {
      final s = plan['slots'];
      if (s is List) return s.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
  }
  final top = exam['slots'];
  if (top is List) return top.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  return const [];
}

// Public wrappers so other modules (e.g. the parent Exams screen) can reuse the
// EXACT same section-match + per-student slot resolution the gradebook uses,
// instead of re-implementing exam filtering and drifting out of parity.
bool examMatchesSection(Map<String, dynamic> exam, String grade, String section) =>
    _matchesSection(exam, grade, section);

List<Map<String, dynamic>> examSlotsForStudent(Map<String, dynamic> exam, GradebookStudent student) =>
    _slotsForStudent(exam, student);

// ── per-component computation ─────────────────────────────────────────────────

class _PctCount {
  final double pct;
  final int count;
  const _PctCount(this.pct, this.count);
}

// Average obtained-% for a student's graded assignments in a subject.
_PctCount _assignmentPct(String subject, GradebookStudent student, GradebookSources src) {
  final subj = subject.toLowerCase();
  final subjAssignments = src.assignments.where((a) =>
      (a['subject']?.toString().toLowerCase() ?? '') == subj &&
      _appliesTo(a['grade']?.toString(), a['section']?.toString(), student));
  final idSet = subjAssignments.map((a) => a['id'].toString()).toSet();
  final titleMax = {for (final a in subjAssignments) a['id'].toString(): (_toNum(a['totalMarks']) == 0 ? 100.0 : _toNum(a['totalMarks']))};
  final pcts = <double>[];
  for (final s in src.submissions) {
    if (s['studentId'].toString() != student.id) continue;
    if (!idSet.contains(s['assignmentId'].toString())) continue;
    final marks = s['marks'];
    if (marks == null) continue;
    final status = (s['status'] ?? '').toString();
    final graded = status == 'graded' || status == 'closed' || marks is num;
    if (!graded) continue;
    final max = titleMax[s['assignmentId'].toString()] ?? 100.0;
    pcts.add(_clampPct(_toNum(marks) / max * 100));
  }
  if (pcts.isEmpty) return const _PctCount(0, 0);
  return _PctCount(pcts.reduce((a, b) => a + b) / pcts.length, pcts.length);
}

// Average obtained-% for a student's submitted assessments in a subject.
_PctCount _assessmentPct(String subject, GradebookStudent student, GradebookSources src) {
  final subj = subject.toLowerCase();
  final subjAssessments = src.assessments.where((a) =>
      (a['subject']?.toString().toLowerCase() ?? '') == subj &&
      _appliesTo(a['grade']?.toString(), a['section']?.toString(), student));
  final maxById = {for (final a in subjAssessments) a['id'].toString(): (_toNum(a['totalMarks']) == 0 ? 100.0 : _toNum(a['totalMarks']))};
  final idSet = subjAssessments.map((a) => a['id'].toString()).toSet();
  final pcts = <double>[];
  for (final t in src.attempts) {
    if (t['studentId'].toString() != student.id) continue;
    if (!idSet.contains(t['assessmentId'].toString())) continue;
    if ((t['status'] ?? '').toString() != 'submitted') continue;
    if (t['score'] == null) continue;
    final max = maxById[t['assessmentId'].toString()] ?? 100.0;
    pcts.add(_clampPct(_toNum(t['score']) / max * 100));
  }
  if (pcts.isEmpty) return const _PctCount(0, 0);
  return _PctCount(pcts.reduce((a, b) => a + b) / pcts.length, pcts.length);
}

// Average obtained-% for a student's exam papers in a subject.
_PctCount _examPct(String subject, GradebookStudent student, GradebookSources src) {
  final subj = subject.toLowerCase();
  final pcts = <double>[];
  for (final exam in src.exams) {
    if (!_matchesSection(exam, student.grade, student.section)) continue;
    final slots = _slotsForStudent(exam, student);
    final hasSubject = slots.any((sl) => (sl['subject']?.toString().toLowerCase() ?? '') == subj) ||
        (slots.isEmpty && (exam['subjects']?.toString().toLowerCase() ?? '').contains(subj));
    if (!hasSubject) continue;
    final examId = (exam['id'] ?? '').toString();
    final mark = src.examMarks[examId]?[subject]?[student.id];
    if (mark == null) continue;
    final max = _toNum(exam['maxMarks']) == 0 ? 100.0 : _toNum(exam['maxMarks']);
    pcts.add(_clampPct(mark / max * 100));
  }
  if (pcts.isEmpty) return const _PctCount(0, 0);
  return _PctCount(pcts.reduce((a, b) => a + b) / pcts.length, pcts.length);
}

// ── subject discovery ─────────────────────────────────────────────────────────

/// All subjects a student has any real mark/activity in (union across sources).
List<String> discoverSubjects(GradebookStudent student, GradebookSources src) {
  final set = <String>{};
  for (final a in src.assignments) {
    if (_appliesTo(a['grade']?.toString(), a['section']?.toString(), student)) {
      final s = a['subject']?.toString();
      if (s != null && s.isNotEmpty) set.add(s);
    }
  }
  for (final a in src.assessments) {
    if (_appliesTo(a['grade']?.toString(), a['section']?.toString(), student)) {
      final s = a['subject']?.toString();
      if (s != null && s.isNotEmpty) set.add(s);
    }
  }
  for (final e in src.exams) {
    if (!_matchesSection(e, student.grade, student.section)) continue;
    for (final sl in _slotsForStudent(e, student)) {
      final s = sl['subject']?.toString();
      if (s != null && s.isNotEmpty) set.add(s);
    }
  }
  final list = set.toList()..sort();
  return list;
}

/// Same columnKey the desktop TeacherGradebook uses to key a MarkOverride.
String columnKeyFor(String categoryName) =>
    categoryName.toLowerCase().replaceAll(RegExp(r'[\s/()]+'), '_').replaceAll(RegExp(r'_+$'), '');

// ── public compute API ────────────────────────────────────────────────────────

// The generic fallback band (mirrors gradebookEngine.ts) when no curriculum
// band matches the student's grade.
final _fallbackCategories = <GradebookCategory>[
  const GradebookCategory('Assignments', null, 20, false),
  const GradebookCategory('Assessments', null, 20, false),
  const GradebookCategory('Mid-Term Exam', 1, 20, true),
  const GradebookCategory('Final Exam', 1, 40, true),
];

SubjectGrade computeSubject(
  String subject,
  GradebookStudent student,
  GradebookBand? band,
  GradebookSources src, {
  String? term,
}) {
  final categories = band?.categories ?? _fallbackCategories;
  final components = <ComponentScore>[];
  for (final cat in categories) {
    final source = categorySource(cat);
    var res = const _PctCount(0, 0);
    if (source == ComponentSource.assignment) {
      res = _assignmentPct(subject, student, src);
    } else if (source == ComponentSource.assessment) {
      res = _assessmentPct(subject, student, src);
    } else if (source == ComponentSource.exam) {
      res = _examPct(subject, student, src);
    }
    var hasData = source != ComponentSource.pending && res.count > 0;
    var obtainedPct = res.pct;

    // A human-reviewed MarkOverride always wins over the raw auto value.
    final columnKey = columnKeyFor(cat.name);
    MarkOverride? ov;
    for (final o in src.overrides) {
      if (o.studentId == student.id &&
          o.subject == subject &&
          o.columnKey == columnKey &&
          (term == null || o.term == term)) {
        ov = o;
        break;
      }
    }
    if (ov != null && cat.marks > 0) {
      obtainedPct = _clampPct(ov.overrideValue / cat.marks * 100);
      hasData = true;
    }

    components.add(ComponentScore(
      category: cat.name,
      weight: cat.marks,
      source: source,
      obtainedPct: obtainedPct,
      weighted: hasData ? obtainedPct / 100 * cat.marks : 0,
      count: res.count,
      hasData: hasData,
    ));
  }

  final presentWeight = components.where((c) => c.hasData).fold<int>(0, (a, c) => a + c.weight);
  final obtainedWeighted = components.fold<double>(0, (a, c) => a + c.weighted);
  final percentage = presentWeight > 0 ? obtainedWeighted / presentWeight * 100 : 0.0;
  return SubjectGrade(
    subject: subject,
    components: components,
    presentWeight: presentWeight,
    obtainedWeighted: obtainedWeighted,
    percentage: percentage,
    letter: presentWeight > 0 ? letterFromPct(percentage) : '—',
    hasData: presentWeight > 0,
  );
}

/// A student's whole gradebook: one SubjectGrade per subject + overall.
class StudentGradebook {
  final String studentId;
  final String name;
  final String grade;
  final String section;
  final List<SubjectGrade> subjects;
  final double overallPercentage;
  final String overallLetter;
  final bool complete;
  int rank;
  StudentGradebook({
    required this.studentId,
    required this.name,
    required this.grade,
    required this.section,
    required this.subjects,
    required this.overallPercentage,
    required this.overallLetter,
    required this.complete,
    this.rank = 0,
  });
}

StudentGradebook computeStudentGradebook(
  GradebookStudent student,
  GradebookBand? band,
  GradebookSources src, {
  List<String>? subjectList,
  String? term,
}) {
  final subs = (subjectList != null && subjectList.isNotEmpty ? subjectList : discoverSubjects(student, src))
      .map((sub) => computeSubject(sub, student, band, src, term: term))
      .where((s) => s.hasData || (subjectList != null && subjectList.isNotEmpty))
      .toList();

  final graded = subs.where((s) => s.hasData).toList();
  final overall = graded.isNotEmpty ? graded.fold<double>(0, (a, s) => a + s.percentage) / graded.length : 0.0;
  final complete = graded.isNotEmpty &&
      graded.every((s) => s.components.where((c) => c.source != ComponentSource.pending).every((c) => c.hasData));

  return StudentGradebook(
    studentId: student.id,
    name: student.name,
    grade: student.grade,
    section: student.section,
    subjects: subs,
    overallPercentage: overall,
    overallLetter: graded.isNotEmpty ? letterFromPct(overall) : '—',
    complete: complete,
  );
}

/// Compute a whole class at once, ranked by overall %.
List<StudentGradebook> computeClassGradebook(
  List<GradebookStudent> students,
  GradebookBand? band,
  GradebookSources src, {
  List<String>? subjectList,
  String? term,
}) {
  final rows = students.map((s) => computeStudentGradebook(s, band, src, subjectList: subjectList, term: term)).toList();
  final ranked = [...rows]..sort((a, b) => b.overallPercentage.compareTo(a.overallPercentage));
  for (var i = 0; i < ranked.length; i++) {
    ranked[i].rank = i + 1;
  }
  return rows;
}
