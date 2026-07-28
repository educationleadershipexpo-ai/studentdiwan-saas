import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../portals/teacher/core/gradebook_engine.dart' as gb;
import '../portals/teacher/core/curriculum_config.dart' as cc;


// ─── Infrastructure ────────────────────────────────────────────────────────────
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main before usage');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return ApiClient(prefs);
});

// Helper: safely parse a list response from /api/data/:entity
List<Map<String, dynamic>> _parseList(dynamic responseData) {
  if (responseData is List) {
    return responseData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
}

// ─── Student Profile ───────────────────────────────────────────────────────────
// Fetches the real student record from the DB using the logged-in user's displayName
final studentProfileProvider = FutureProvider<StudentProfile>((ref) async {
  final api = ref.watch(apiClientProvider);
  final prefs = ref.watch(sharedPrefsProvider);

  // Get cached user JSON from login
  final userJson = prefs.getString(StorageKeys.userJson);
  String displayName = '';
  String email = '';
  if (userJson != null) {
    try {
      final u = json.decode(userJson) as Map<String, dynamic>;
      displayName = u['displayName'] as String? ?? '';
      email = u['email'] as String? ?? '';
    } catch (_) {}
  }

  try {
    // Look up real student record by name
    final res = await api.get('/api/data/students');
    final students = _parseList(res.data);

    // Match by displayName (name field in student record)
    Map<String, dynamic>? match;
    if (displayName.isNotEmpty) {
      match = students.firstWhere(
        (s) => (s['name'] as String?)?.toLowerCase() == displayName.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      if (match.isEmpty) match = null;
    }
    // Fallback: match by email (login email vs. student email)
    if (match == null && email.isNotEmpty) {
      match = students.firstWhere(
        (s) => (s['email'] as String?)?.toLowerCase().contains(email.split('@')[0].toLowerCase()) == true,
        orElse: () => <String, dynamic>{},
      );
      if (match.isEmpty) match = null;
    }

    if (match != null) {
      return StudentProfile(
        id: match['id'] as String? ?? '',
        displayName: match['name'] as String? ?? displayName,
        email: match['email'] as String? ?? email,
        gradeName: gradeLabel(match['grade'], match['section']),
        rollNumber: 'Roll No. ${match['rollNumber'] ?? match['studentId'] ?? ''}',
        avatarUrl: '',
        studentData: match,
      );
    }
  } catch (_) {}

  // Fallback: build from login credentials
  return StudentProfile(
    id: '',
    displayName: displayName,
    email: email,
    gradeName: 'Student',
    rollNumber: '',
    avatarUrl: '',
  );
});

// ─── Timetable ─────────────────────────────────────────────────────────────────
// The admin panel publishes the ENTIRE school timetable as ONE record
// (id "published-timetable-v3") in `timetable_slots`, whose `gridJson` is a JSON
// object keyed by class ("Grade 3-B") → 2-D grid[periodRow][dayCol] = cell.
// This is the exact source the desktop Student/Parent web portals read, so the
// mobile app decodes it identically. No fabricated fallback — an unconfigured
// class shows an empty state.
const List<Map<String, String>> _kTimetableSlots = [
  {'start': '08:00 AM', 'end': '08:45 AM'},
  {'start': '08:45 AM', 'end': '09:30 AM'},
  {'start': '09:30 AM', 'end': '10:15 AM'},
  {'start': '10:35 AM', 'end': '11:20 AM'},
  {'start': '11:20 AM', 'end': '12:05 PM'},
  {'start': '12:05 PM', 'end': '12:50 PM'},
];

String _ttStripKey(String k) => k.replaceAll(RegExp(r'\s+'), '').toLowerCase();

final studentTimetableProvider = FutureProvider<List<TimetablePeriod>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    final grade = profile.grade.trim();
    final section = profile.section.trim().toUpperCase();
    if (grade.isEmpty || section.isEmpty) return [];

    // Fetch the single published-timetable blob by id.
    final res = await api.get('/api/data/timetable_slots/published-timetable-v3');
    final rec = res.data;
    if (rec is! Map) return [];
    final gridJson = rec['gridJson'];
    if (gridJson is! String || gridJson.isEmpty) return [];

    Map<String, dynamic> allGrids;
    try {
      allGrids = jsonDecode(gridJson) as Map<String, dynamic>;
    } catch (_) {
      return [];
    }

    // Resolve this student's class key ("Grade 3-B"), tolerant of spacing/case.
    final normGrade = RegExp(r'^grade\s', caseSensitive: false).hasMatch(grade)
        ? grade.replaceFirst(RegExp(r'^grade\s+', caseSensitive: false), 'Grade ')
        : 'Grade $grade';
    final classKey = '$normGrade-$section';
    dynamic classGrid = allGrids[classKey];
    if (classGrid == null) {
      final target = _ttStripKey(classKey);
      final match = allGrids.keys.firstWhere(
        (k) => _ttStripKey(k) == target,
        orElse: () => '',
      );
      if (match.isNotEmpty) classGrid = allGrids[match];
    }
    if (classGrid is! List) return [];

    final out = <TimetablePeriod>[];
    for (int period = 0; period < classGrid.length && period < _kTimetableSlots.length; period++) {
      final row = classGrid[period];
      if (row is! List) continue;
      final times = _kTimetableSlots[period];
      for (int dayCol = 0; dayCol < row.length && dayCol < 5; dayCol++) {
        final cell = row[dayCol];
        if (cell is! Map) continue;
        final subject = (cell['subject'] ?? '').toString().trim();
        if (subject.isEmpty) continue;
        out.add(TimetablePeriod(
          id: '${classKey}_${period}_$dayCol',
          startTime: times['start']!,
          endTime: times['end']!,
          subject: subject,
          teacherName: (cell['teacher'] ?? '').toString().trim(),
          room: (cell['room'] ?? '').toString().trim(),
          day: dayCol + 1, // 1 = Mon .. 5 = Fri
        ));
      }
    }
    return out;
  } catch (_) {
    return [];
  }
});

// ─── Homework ──────────────────────────────────────────────────────────────────
final studentHomeworkProvider = FutureProvider<List<HomeworkModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/api/data/homework');
    final list = _parseList(res.data);
    return list.map((e) => HomeworkModel(
      id: e['id'] as String? ?? '',
      title: e['title'] as String? ?? 'Homework',
      subject: e['subject'] as String? ?? '',
      dueDate: e['dueDate'] as String? ?? '',
      priority: e['priority'] as String? ?? 'Medium',
      isCompleted: e['isCompleted'] as bool? ?? false,
      instructions: e['instructions'] as String? ?? e['description'] as String? ?? '',
    )).toList();
  } catch (_) {
    return [];
  }
});

// ─── Homework Submissions ───────────────────────────────────────────────────────
// The student's own real submission rows (HomeworkSubmission), same entity the
// desktop Student/Homework page writes/reads. "Completed" is derived from having
// actually submitted — the teacher's create flow never sets isCompleted on the
// homework row, so that field is unreliable. Returns the set of submitted
// homeworkIds for the logged-in student.
final studentHomeworkSubmissionsProvider =
    FutureProvider<Set<String>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    final studentId = profile.id;
    if (studentId.isEmpty) return <String>{};

    // Desktop maps "HomeworkSubmission" → the `homework_submissions` table
    // client-side (localDb.ts entityMapping); the server stores by the raw
    // path segment, so mobile must use the mapped table name to share data.
    final res = await api.get('/api/data/homework_submissions');
    final list = _parseList(res.data);
    return list
        .where((e) => '${e['studentId']}' == studentId)
        .map((e) => '${e['homeworkId']}')
        .toSet();
  } catch (_) {
    return <String>{};
  }
});

// Submit the student's homework answer as a real HomeworkSubmission row.
// Mirrors desktop handleSubmitHomework (Homework.tsx): POST /api/data/HomeworkSubmission
// with {homeworkId, studentId, studentName, content, submittedAt, status}.
Future<void> submitHomework(
  WidgetRef ref, {
  required String homeworkId,
  required String content,
}) async {
  final api = ref.read(apiClientProvider);
  final profile = await ref.read(studentProfileProvider.future);
  if (profile.id.isEmpty) {
    throw Exception('Your student record could not be found.');
  }
  await api.post('/api/data/homework_submissions', data: {
    'homeworkId': homeworkId,
    'studentId': profile.id,
    'studentName': profile.displayName,
    'content': content,
    'status': 'submitted',
  });
}

// ─── Assignments ───────────────────────────────────────────────────────────────
// Desktop student Assignments.tsx reads the raw "TeacherAssignment" entity and
// filters to the student's own grade/section — mirror both here.
String _canonAsgGrade(String? raw) =>
    (raw ?? '').trim().toLowerCase().replaceFirst(RegExp(r'^grade\s*'), '');
String _canonAsgSection(String? raw) =>
    (raw ?? '').trim().toUpperCase().replaceFirst(RegExp(r'^SEC(TION)?\.?\s*'), '');

final studentAssignmentsProvider = FutureProvider<List<AssignmentModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    final data = profile.studentData;
    final myGrade = _canonAsgGrade(data?['grade']?.toString());
    final mySection = _canonAsgSection(data?['section']?.toString());

    final res = await api.get('/api/data/TeacherAssignment');
    final list = _parseList(res.data).where((e) {
      if (myGrade.isEmpty) return false;
      if (_canonAsgGrade(e['grade']?.toString()) != myGrade) return false;
      final sec = _canonAsgSection(e['section']?.toString());
      return sec.isEmpty || sec == 'ALL' || sec == 'ALL SECTIONS' || sec == mySection;
    }).toList();
    return list.map((e) => AssignmentModel(
      id: e['id'] as String? ?? '',
      title: e['title'] as String? ?? 'Assignment',
      subject: e['subject'] as String? ?? '',
      dueDate: e['dueDate'] as String? ?? '',
      points: (e['points'] as num?)?.toInt() ?? (e['marks'] as num?)?.toInt() ?? 0,
      score: (e['score'] as num?)?.toInt(),
      status: e['status'] as String? ?? 'Pending',
      feedback: e['feedback'] as String?,
    )).toList();
  } catch (_) {
    return [];
  }
});

// ─── Study Materials ───────────────────────────────────────────────────────────
final studentMaterialsProvider = FutureProvider<List<StudyMaterialModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/api/data/study_materials');
    final list = _parseList(res.data);
    return list.map((e) => StudyMaterialModel(
      id: e['id'] as String? ?? '',
      title: e['title'] as String? ?? '',
      subject: e['subject'] as String? ?? '',
      type: e['type'] as String? ?? 'Document',
      size: e['size'] as String? ?? '',
      downloadUrl: e['fileUrl'] as String? ?? e['downloadUrl'] as String? ?? '',
    )).toList();
  } catch (_) {
    return [];
  }
});

// ─── Assessments ──────────────────────────────────────────────────────────────
final studentAssessmentsProvider = FutureProvider<List<AssessmentModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/api/data/assessments');
    final list = _parseList(res.data);
    return list.map((e) => AssessmentModel(
      id: e['id'] as String? ?? '',
      title: e['title'] as String? ?? '',
      subject: e['subject'] as String? ?? '',
      durationMinutes: (e['durationMinutes'] as num?)?.toInt() ?? 20,
      questionsCount: (e['questionsCount'] as num?)?.toInt() ?? 10,
      scoreObtained: (e['scoreObtained'] as num?)?.toInt(),
    )).toList();
  } catch (_) {
    return [];
  }
});

// ─── Assessment quiz (full questions + attempts) ────────────────────────────
// Mirrors desktop student/Assessments.tsx: reads the real `assessments` rows
// (with questions parsed from the JSON blob), scoped to the student's grade/
// section, plus the student's own attempts. Taking a quiz writes a real
// assessment_attempts row scored against the questions' correctAnswer — no
// hardcoded Newton questions, no fake "2/2 synced to ERP".
class QuizOption {
  final String id;
  final String text;
  QuizOption(this.id, this.text);
}

class QuizQuestion {
  final String id;
  final String type;
  final String text;
  final int marks;
  final List<QuizOption> options;
  final String correctAnswer; // may be empty for open-ended
  QuizQuestion({
    required this.id,
    required this.type,
    required this.text,
    required this.marks,
    required this.options,
    required this.correctAnswer,
  });
}

class QuizAssessment {
  final String id;
  final String title;
  final String subject;
  final int durationMinutes;
  final int totalMarks;
  final int passingMarks;
  final List<QuizQuestion> questions;
  QuizAssessment({
    required this.id,
    required this.title,
    required this.subject,
    required this.durationMinutes,
    required this.totalMarks,
    required this.passingMarks,
    required this.questions,
  });
}

List<QuizQuestion> _parseQuestions(dynamic raw) {
  dynamic data = raw;
  if (data is String && data.isNotEmpty) {
    try {
      data = json.decode(data);
    } catch (_) {
      return [];
    }
  }
  if (data is! List) return [];
  final out = <QuizQuestion>[];
  for (var i = 0; i < data.length; i++) {
    final q = data[i];
    if (q is! Map) continue;
    final m = q.cast<String, dynamic>();
    final opts = <QuizOption>[];
    final rawOpts = m['options'];
    if (rawOpts is List) {
      for (var j = 0; j < rawOpts.length; j++) {
        final o = rawOpts[j];
        if (o is Map) {
          opts.add(QuizOption('${o['id'] ?? j}', '${o['text'] ?? ''}'));
        } else {
          opts.add(QuizOption('$j', '$o'));
        }
      }
    }
    out.add(QuizQuestion(
      id: '${m['id'] ?? 'q$i'}',
      type: '${m['type'] ?? 'MCQ'}',
      text: '${m['text'] ?? ''}',
      marks: (m['marks'] as num?)?.toInt() ?? 1,
      options: opts,
      correctAnswer: '${m['correctAnswer'] ?? ''}',
    ));
  }
  return out;
}

// Full assessments (with questions) scoped to the student's grade/section.
final studentQuizAssessmentsProvider =
    FutureProvider<List<QuizAssessment>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    final studentData = profile.studentData ?? const {};
    final myGrade = canonGrade('${studentData['grade'] ?? ''}');
    final mySection = canonSection('${studentData['section'] ?? ''}');

    final res = await api.get('/api/data/assessments');
    final list = _parseList(res.data);
    final out = <QuizAssessment>[];
    for (final a in list) {
      final status = '${a['status'] ?? ''}';
      if (status != 'Active' && status != 'Completed') continue;
      // Match grade/section when the assessment specifies them.
      final aGrade = canonGrade('${a['grade'] ?? ''}');
      final aSection = canonSection('${a['section'] ?? ''}');
      if (aGrade.isNotEmpty && myGrade.isNotEmpty && aGrade != myGrade) continue;
      if (aSection.isNotEmpty && mySection.isNotEmpty && aSection != mySection) continue;

      final questions = _parseQuestions(a['questions']);
      final total = (a['totalMarks'] as num?)?.toInt() ??
          questions.fold<int>(0, (s, q) => s + q.marks);
      out.add(QuizAssessment(
        id: '${a['id'] ?? ''}',
        title: '${a['title'] ?? ''}',
        subject: '${a['subject'] ?? ''}',
        durationMinutes: (a['duration'] as num?)?.toInt() ??
            (a['durationMinutes'] as num?)?.toInt() ?? 20,
        totalMarks: total,
        passingMarks: (a['passingMarks'] as num?)?.toInt() ?? 0,
        questions: questions,
      ));
    }
    return out;
  } catch (_) {
    return [];
  }
});

// This student's submitted attempts → assessmentId → score.
final studentQuizAttemptsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    if (profile.id.isEmpty) return <String, int>{};
    final res = await api.get('/api/data/assessment_attempts');
    final list = _parseList(res.data);
    final out = <String, int>{};
    for (final r in list) {
      final mine = '${r['studentId']}' == profile.id ||
          '${r['studentName']}'.toLowerCase() == profile.displayName.toLowerCase();
      final submitted = '${r['status']}' == 'submitted' || r['submittedAt'] != null;
      if (mine && submitted) {
        out['${r['assessmentId']}'] = (r['score'] as num?)?.toInt() ?? 0;
      }
    }
    return out;
  } catch (_) {
    return <String, int>{};
  }
});

// Submit a real attempt: score auto-gradable questions against correctAnswer
// (open-ended answered questions get full marks, matching desktop), then POST
// a canonical assessment_attempts row.
Future<int> submitQuizAttempt(
  WidgetRef ref, {
  required QuizAssessment assessment,
  required Map<String, String> answers,
}) async {
  final api = ref.read(apiClientProvider);
  final profile = await ref.read(studentProfileProvider.future);
  if (profile.id.isEmpty) {
    throw Exception('Your student record could not be found.');
  }
  int score = 0;
  for (final q in assessment.questions) {
    final ans = answers[q.id];
    if (ans == null || ans.isEmpty) continue;
    if (q.correctAnswer.isNotEmpty) {
      if (ans == q.correctAnswer) score += q.marks;
    } else {
      score += q.marks; // open-ended: full marks on answer, per desktop
    }
  }
  final now = DateTime.now().toIso8601String();
  await api.post('/api/data/assessment_attempts', data: {
    'assessmentId': assessment.id,
    'studentId': profile.id,
    'studentName': profile.displayName,
    'answers': json.encode(answers),
    'startedAt': now,
    'submittedAt': now,
    'score': score,
    'status': 'submitted',
  });
  return score;
}

// ─── Exams ────────────────────────────────────────────────────────────────────
final studentExamsProvider = FutureProvider<List<ExamModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/api/data/exams');
    final list = _parseList(res.data);
    return list.map((e) => ExamModel(
      id: e['id'] as String? ?? '',
      title: e['title'] as String? ?? e['name'] as String? ?? 'Exam',
      dateRange: e['date'] as String? ?? e['dateRange'] as String? ?? '',
      subject: e['subject'] as String? ?? '',
      room: e['room'] as String? ?? e['hall'] as String? ?? '',
    )).toList();
  } catch (_) {
    return [];
  }
});

// ─── Results / Grades ─────────────────────────────────────────────────────────
// Mirrors desktop Exams.tsx "results" tab: Published `exams` joined with
// `exam_marks` rows ({id: examId, <subject>: {<studentId>: mark}}), keeping
// only this student's marks. Same letter bands as gradebookEngine.gradeFor.
String _letterFor(int pct) {
  if (pct >= 90) return 'A+';
  if (pct >= 80) return 'A';
  if (pct >= 70) return 'B+';
  if (pct >= 60) return 'B';
  if (pct >= 50) return 'C';
  if (pct >= 40) return 'D';
  return 'F';
}

final studentResultsProvider = FutureProvider<List<ResultGrade>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    if (profile.id.isEmpty) return [];

    final examsRes = await api.get('/api/data/exams');
    final exams = _parseList(examsRes.data)
        .where((e) => '${e['status']}' == 'Published')
        .toList();
    if (exams.isEmpty) return [];

    final marksRes = await api.get('/api/data/exam_marks');
    final markRows = {
      for (final m in _parseList(marksRes.data)) '${m['id']}': m,
    };

    final out = <ResultGrade>[];
    for (final e in exams) {
      final marksForExam = markRows['${e['id']}'];
      if (marksForExam == null) continue;
      final examTitle = '${e['name'] ?? e['title'] ?? ''}';
      final max = (e['maxMarks'] as num?)?.toInt() ?? 100;
      marksForExam.forEach((subject, perStudent) {
        if (subject == 'id' || perStudent is! Map) return;
        final mark = perStudent[profile.id];
        if (mark is! num) return;
        final score = mark.toInt();
        final pct = max > 0 ? ((score / max) * 100).round() : 0;
        out.add(ResultGrade(
          subject: examTitle.isEmpty ? subject : '$subject · $examTitle',
          score: score,
          total: max,
          grade: _letterFor(pct),
        ));
      });
    }
    return out;
  } catch (_) {
    return [];
  }
});

// ─── Gradebook (weighted composite) ─────────────────────────────────────────
// The student's own weighted gradebook, computed by the SAME engine the teacher
// and parent portals use (lib/portals/teacher/core/gradebook_engine.dart). Real
// data only: assignments, assessments, exams and manual overrides are weighted
// by the active curriculum's band for the student's grade; an unmarked category
// is excluded from the denominator and never fabricated.

// The school's active curriculum (school_config/active_curriculum → default).
final studentCurriculumProvider = FutureProvider<cc.CurriculumConfig>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/api/data/school_config/active_curriculum');
    final rec = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
    final id = rec?['curriculumId']?.toString();
    return cc.getCurriculum(id);
  } catch (_) {
    return cc.getCurriculum(cc.defaultCurriculumId);
  }
});

// All raw gradebook source tables, loaded once (mirrors desktop loadGradebookSources).
final studentGradebookSourcesProvider = FutureProvider<gb.GradebookSources>((ref) async {
  final api = ref.watch(apiClientProvider);

  Future<List<Map<String, dynamic>>> fetch(String entity) async {
    try {
      final res = await api.get('/api/data/$entity');
      return _parseList(res.data);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  final results = await Future.wait([
    fetch('TeacherAssignment'),
    fetch('assignment_submissions'),
    fetch('assessments'),
    fetch('assessment_attempts'),
    fetch('exams'),
    fetch('exam_marks'),
    fetch('MarkOverride'),
  ]);
  return gb.GradebookSources(
    assignments: results[0],
    submissions: results[1],
    assessments: results[2],
    attempts: results[3],
    exams: results[4],
    examMarks: gb.buildExamMarks(results[5]),
    overrides: results[6].map(gb.MarkOverride.fromJson).toList(),
  );
});

// The student's whole weighted gradebook (all subjects + overall %), optionally
// scoped to a term (null → all terms combined). Honest empty state when the
// student has no published marks.
final studentGradebookProvider =
    FutureProvider.family<gb.StudentGradebook, String?>((ref, term) async {
  final profile = await ref.watch(studentProfileProvider.future);
  final curriculum = await ref.watch(studentCurriculumProvider.future);
  final src = await ref.watch(studentGradebookSourcesProvider.future);
  final band = cc.getBandForGrade(curriculum, profile.grade);
  final student = gb.GradebookStudent(
    id: profile.id,
    name: profile.displayName,
    grade: profile.grade,
    section: profile.section,
  );
  return gb.computeStudentGradebook(student, band, src, term: term);
});

// The term labels for the active curriculum, for the term selector (mirrors
// getPeriodLabels).
final studentTermLabelsProvider = FutureProvider<List<String>>((ref) async {
  final curriculum = await ref.watch(studentCurriculumProvider.future);
  return cc.getPeriodLabels(curriculum);
});

// Published report cards for the logged-in student, read from the real
// `report_cards` table (desktop entity "ReportCard"). Only records that have
// been through the approval chain and published to students are visible — this
// mirrors desktop getLatestPublished (status "published" && publishedToStudents).
// No fabricated terms, subjects, ranks, or averages.
class ReportCardSubjectRow {
  final String subject;
  final double obtained;
  final double max;
  final int pct;
  final String letter;
  ReportCardSubjectRow({
    required this.subject,
    required this.obtained,
    required this.max,
    required this.pct,
    required this.letter,
  });
}

class ReportCardRow {
  final String id;
  final String term;
  final String year;
  final List<ReportCardSubjectRow> subjects;
  final int overallPct;
  final String overallGrade;
  final int? attendancePct;
  final String classTeacherRemark;
  final String teacherName;
  final String generatedAt;
  ReportCardRow({
    required this.id,
    required this.term,
    required this.year,
    required this.subjects,
    required this.overallPct,
    required this.overallGrade,
    required this.attendancePct,
    required this.classTeacherRemark,
    required this.teacherName,
    required this.generatedAt,
  });

  String get label => [term, year].where((s) => s.isNotEmpty).join(' · ');
}

List<ReportCardSubjectRow> _parseReportSubjects(dynamic raw) {
  dynamic data = raw;
  if (data is String && data.isNotEmpty) {
    try {
      data = json.decode(data);
    } catch (_) {
      return [];
    }
  }
  if (data is! List) return [];
  final out = <ReportCardSubjectRow>[];
  for (final s in data) {
    if (s is! Map) continue;
    final m = s.cast<String, dynamic>();
    out.add(ReportCardSubjectRow(
      subject: '${m['subject'] ?? ''}',
      obtained: (m['obtained'] as num?)?.toDouble() ?? 0,
      max: (m['max'] as num?)?.toDouble() ?? 100,
      pct: (m['pct'] as num?)?.toInt() ?? 0,
      letter: '${m['letter'] ?? ''}',
    ));
  }
  return out;
}

final studentReportCardsProvider =
    FutureProvider<List<ReportCardRow>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    if (profile.id.isEmpty) return [];

    final res = await api.get('/api/data/report_cards');
    final list = _parseList(res.data);
    final out = <ReportCardRow>[];
    for (final r in list) {
      if ('${r['studentId']}' != profile.id) continue;
      if ('${r['status']}' != 'published') continue;
      final toStudents = r['publishedToStudents'];
      if (toStudents == false) continue; // must be published to students
      out.add(ReportCardRow(
        id: '${r['id'] ?? ''}',
        term: '${r['term'] ?? ''}',
        year: '${r['year'] ?? ''}',
        subjects: _parseReportSubjects(r['subjects']),
        overallPct: (r['overallPct'] as num?)?.toInt() ?? 0,
        overallGrade: '${r['overallGrade'] ?? ''}',
        attendancePct: (r['attendancePct'] as num?)?.toInt(),
        classTeacherRemark: '${r['classTeacherRemark'] ?? ''}',
        teacherName: '${r['teacherName'] ?? ''}',
        generatedAt: '${r['generatedAt'] ?? ''}',
      ));
    }
    // Newest first (desktop sorts by generatedAt desc).
    out.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return out;
  } catch (_) {
    return [];
  }
});

// ─── Fees ─────────────────────────────────────────────────────────────────────
// Real source is the `invoices` table (same as desktop). Each row:
// {invoiceNumber, studentId, amount, paidAmount, dueAmount, dueDate, status,...}.
final studentFeesProvider = FutureProvider<List<FeeInvoice>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    final studentId = profile.id;
    if (studentId.isEmpty) return [];

    final res = await api.get('/api/data/invoices');
    final list = _parseList(res.data);

    return list.where((e) => e['studentId'] == studentId).map((e) {
      final status = (e['status'] as String?)?.toLowerCase() ?? '';
      return FeeInvoice(
        invoiceNumber: e['invoiceNumber'] as String? ?? e['id'] as String? ?? '',
        dateDue: e['dueDate'] as String? ?? '',
        amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
        isPaid: status == 'paid' || (e['dueAmount'] as num?) == 0,
      );
    }).toList();
  } catch (_) {
    return [];
  }
});

// ─── Messages ─────────────────────────────────────────────────────────────────
final studentMessagesProvider = FutureProvider<List<MessageModel>>((ref) async {
  final api = ref.watch(apiClientProvider);

  try {
    // Fetch messages/announcements
    final res = await api.get('/api/data/messages');
    final list = _parseList(res.data);
    if (list.isNotEmpty) {
      return list.map((e) => MessageModel(
        id: e['id'] as String? ?? '',
        senderName: e['senderName'] as String? ?? e['from'] as String? ?? 'School',
        senderRole: e['senderRole'] as String? ?? '',
        content: e['content'] as String? ?? e['message'] as String? ?? '',
        unreadCount: (e['unread'] as bool? ?? false) ? 1 : 0,
        timestamp: DateTime.tryParse(e['createdAt'] as String? ?? '') ?? DateTime.now(),
      )).toList();
    }

    // Try notices/announcements as fallback
    final res2 = await api.get('/api/data/notices');
    final list2 = _parseList(res2.data);
    return list2.map((e) => MessageModel(
      id: e['id'] as String? ?? '',
      senderName: e['author'] as String? ?? 'School Administration',
      senderRole: 'Administration',
      content: e['content'] as String? ?? e['message'] as String? ?? '',
      unreadCount: 0,
      timestamp: DateTime.tryParse(e['createdAt'] as String? ?? '') ?? DateTime.now(),
    )).toList();
  } catch (_) {
    return [];
  }
});

// ─── Notifications ─────────────────────────────────────────────────────────────
final studentNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final prefs = ref.watch(sharedPrefsProvider);

  try {
    final userJson = prefs.getString(StorageKeys.userJson);
    String uid = '';
    String email = '';
    if (userJson != null) {
      final u = json.decode(userJson) as Map<String, dynamic>;
      uid = u['uid'] as String? ?? '';
      email = u['email'] as String? ?? '';
    }

    final res = await api.get('/api/data/notifications', queryParameters: {
      if (uid.isNotEmpty) 'forUid': uid,
      'forRole': 'student',
      if (email.isNotEmpty) 'forEmail': email,
    });
    return _parseList(res.data);
  } catch (_) {
    return [];
  }
});

// ─── Attendance (student-level) ───────────────────────────────────────────────
// Reads the same source as the desktop Student portal: the per-session
// `TeacherAttendance` documents ({grade:"Grade 3", section:"B", date, marks:{
// <studentId>:"P"|"A"|"L"|"H"}}). The flat `attendance` table the mobile app
// used before is a different, unrelated store — reading it showed wrong data.
final studentAttendanceProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);

  try {
    final profile = await ref.watch(studentProfileProvider.future);
    final studentId = profile.id;
    if (studentId.isEmpty) return [];

    final sGrade = canonGrade(profile.grade);
    final sSection = canonSection(profile.section);

    final res = await api.get('/api/data/TeacherAttendance');
    final rows = _parseList(res.data);

    const statusLabel = {
      'P': 'Present', 'A': 'Absent', 'L': 'Late', 'H': 'Half day',
      'E': 'Excused', 'S': 'Sick',
    };

    final out = <Map<String, dynamic>>[];
    for (final r in rows) {
      // Match this student's class (grade + section), tolerant of "Grade 3"/"3".
      if (canonGrade(r['grade'] as String?) != sGrade) continue;
      if (sSection.isNotEmpty && canonSection(r['section'] as String?) != sSection) continue;

      final marks = r['marks'];
      if (marks is! Map) continue;
      final mark = marks[studentId];
      if (mark == null) continue; // student not in this session's roster

      final date = (r['date'] as String?) ??
          (r['createdAt'] as String?)?.substring(0, 10) ?? '';
      if (date.isEmpty) continue;

      out.add({
        'date': date,
        'status': statusLabel[mark.toString().toUpperCase()] ?? 'Present',
        'code': mark.toString().toUpperCase(),
      });
    }
    return out;
  } catch (_) {
    return [];
  }
});

// ─── Library Books ─────────────────────────────────────────────────────────────
// Real shared catalogue (the `library` table == desktop's LibraryItem entity).
final studentLibraryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/api/data/library');
    return _parseList(res.data);
  } catch (_) {
    return [];
  }
});

// Per-copy inventory (desktop's LibraryCopy) — availability is real ("a copy is
// on the shelf") instead of a stale status flag on the title. Maps bookId → how
// many copies are currently Available.
final studentLibraryAvailabilityProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/api/data/library_copies');
    final list = _parseList(res.data);
    final counts = <String, int>{};
    for (final c in list) {
      if ('${c['status']}' == 'Available') {
        final bookId = '${c['bookId']}';
        counts[bookId] = (counts[bookId] ?? 0) + 1;
      }
    }
    return counts;
  } catch (_) {
    return <String, int>{};
  }
});

// This student's own reservations (desktop's LibraryReservation) that are still
// active (waiting/ready) → the set of bookIds they already hold. Drives the
// "Reserved" chip and prevents duplicate holds.
final studentLibraryReservationsProvider =
    FutureProvider<Set<String>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    if (profile.id.isEmpty) return <String>{};
    final res = await api.get('/api/data/library_reservations');
    final list = _parseList(res.data);
    return list
        .where((r) =>
            '${r['studentId']}' == profile.id &&
            (('${r['status']}' == 'waiting') || ('${r['status']}' == 'ready')))
        .map((r) => '${r['bookId']}')
        .toSet();
  } catch (_) {
    return <String>{};
  }
});

// Place a real hold on a title — writes a LibraryReservation row the librarian
// desk (and the desktop app) can see. Position is computed from the current
// waiting queue for this book, matching desktop's requestHold().
Future<void> reserveLibraryBook(
  WidgetRef ref, {
  required String bookId,
  required String bookTitle,
}) async {
  final api = ref.read(apiClientProvider);
  final profile = await ref.read(studentProfileProvider.future);
  if (profile.id.isEmpty) {
    throw Exception('Your student record could not be found.');
  }
  // Count all students' current waiting holds for this book to set the position.
  int waiting = 0;
  try {
    final res = await api.get('/api/data/library_reservations');
    final list = _parseList(res.data);
    waiting = list
        .where((r) =>
            '${r['bookId']}' == bookId && '${r['status']}' == 'waiting')
        .length;
  } catch (_) {}
  await api.post('/api/data/library_reservations', data: {
    'bookId': bookId,
    'bookTitle': bookTitle,
    'studentId': profile.id,
    'studentName': profile.displayName,
    'requestedAt': DateTime.now().toIso8601String(),
    'status': 'waiting',
    'position': waiting + 1,
  });
}

// ─── Transport ────────────────────────────────────────────────────────────────
// The student's real bus allocation, resolved from the same tables the admin
// Transport module writes: transport_enrollments (allocation) → transport_routes
// (route + stops) → transport_vehicles (bus + driver) → staff (driver contact).
// If the student isn't enrolled, `allocation` is null → the screen shows a
// "not enrolled" empty state. No demo bus, no fake GPS.
class StudentTransportInfo {
  final Map<String, dynamic>? allocation;
  final Map<String, dynamic>? route;
  final Map<String, dynamic>? vehicle;
  final Map<String, dynamic>? driver; // staff record (Transport dept)
  final List<Map<String, dynamic>> stops;

  StudentTransportInfo({
    this.allocation,
    this.route,
    this.vehicle,
    this.driver,
    this.stops = const [],
  });

  bool get isEnrolled => allocation != null;
}

final studentTransportProvider = FutureProvider<StudentTransportInfo>((ref) async {
  final api = ref.watch(apiClientProvider);
  final profile = await ref.watch(studentProfileProvider.future);
  if (profile.id.isEmpty) return StudentTransportInfo();

  try {
    final allocRes = await api.get('/api/data/transport_enrollments');
    final allocs = _parseList(allocRes.data);
    Map<String, dynamic>? allocation;
    for (final a in allocs) {
      final matchesId = '${a['studentId']}' == profile.id;
      final matchesName = '${a['studentName']}'.toLowerCase() ==
          profile.displayName.toLowerCase();
      if (matchesId || matchesName) {
        allocation = a;
        break;
      }
    }
    if (allocation == null) return StudentTransportInfo();

    // Resolve route by name, then vehicle by reg number, then driver by name.
    Map<String, dynamic>? route;
    List<Map<String, dynamic>> stops = const [];
    try {
      final routeRes = await api.get('/api/data/transport_routes');
      final routes = _parseList(routeRes.data);
      route = routes.firstWhere(
        (r) => '${r['name']}' == '${allocation!['route']}',
        orElse: () => <String, dynamic>{},
      );
      if (route.isEmpty) route = null;
      final rawStops = route?['stopsList'];
      if (rawStops is List) {
        stops = rawStops.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}

    Map<String, dynamic>? vehicle;
    try {
      final vehRes = await api.get('/api/data/transport_vehicles');
      final vehicles = _parseList(vehRes.data);
      final target = '${route?['vehicle'] ?? allocation['vehicle'] ?? ''}';
      vehicle = vehicles.firstWhere(
        (v) => '${v['regNumber']}' == target || '${v['id']}' == target,
        orElse: () => <String, dynamic>{},
      );
      if (vehicle.isEmpty) vehicle = null;
    } catch (_) {}

    Map<String, dynamic>? driver;
    final driverName = '${vehicle?['driver'] ?? ''}';
    if (driverName.isNotEmpty) {
      try {
        final staffRes = await api.get('/api/data/staff');
        final staff = _parseList(staffRes.data);
        driver = staff.firstWhere(
          (s) => '${s['name']}' == driverName,
          orElse: () => <String, dynamic>{},
        );
        if (driver.isEmpty) driver = null;
      } catch (_) {}
    }

    return StudentTransportInfo(
      allocation: allocation,
      route: route,
      vehicle: vehicle,
      driver: driver,
      stops: stops,
    );
  } catch (_) {
    return StudentTransportInfo();
  }
});

// ── Calendar Events ──────────────────────────────────────────────────────────
// The desktop school calendar aggregates real dated entities. `calendar_events`
// is the primary store; when empty we still surface the student's real exams
// (published to students, grade-matched) and homework due dates so the calendar
// reflects live data — never fabricated events. Each item:
// {date, title, time, type}.
class CalendarEvent {
  final DateTime date;
  final String title;
  final String time;
  final String type; // Exam, Homework, Event
  const CalendarEvent({
    required this.date,
    required this.title,
    required this.time,
    required this.type,
  });
}

bool _calSectionMatches(String? eventSection, String studentSection) {
  final es = (eventSection ?? '').trim().toLowerCase();
  if (es.isEmpty || es == 'all sections' || es == 'all') return true;
  return canonSection(eventSection) == canonSection(studentSection);
}

final studentCalendarProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final out = <CalendarEvent>[];

  try {
    final profile = await ref.watch(studentProfileProvider.future);
    final sGrade = canonGrade(profile.grade);
    final sSection = profile.section;

    // 1) calendar_events (admin-published, school-wide) — primary source.
    try {
      final res = await api.get('/api/data/calendar_events');
      for (final e in _parseList(res.data)) {
        final raw = (e['date'] ?? e['startDate'] ?? e['start']) as String?;
        final d = DateTime.tryParse(raw ?? '');
        if (d == null) continue;
        out.add(CalendarEvent(
          date: DateTime(d.year, d.month, d.day),
          title: (e['title'] ?? e['name'] ?? 'Event').toString(),
          time: (e['time'] ?? '').toString(),
          type: (e['type'] ?? 'Event').toString(),
        ));
      }
    } catch (_) {}

    // 2) Exams published to students for this grade/section.
    try {
      final res = await api.get('/api/data/exams');
      for (final e in _parseList(res.data)) {
        if (e['publishedToStudents'] != true) continue;
        if (sGrade.isNotEmpty && canonGrade(e['grade'] as String?) != sGrade) continue;
        if (!_calSectionMatches(e['section'] as String?, sSection)) continue;
        final d = DateTime.tryParse((e['startDate'] as String?) ?? '');
        if (d == null) continue;
        out.add(CalendarEvent(
          date: DateTime(d.year, d.month, d.day),
          title: (e['name'] ?? e['title'] ?? 'Exam').toString(),
          time: (e['type'] ?? '').toString(),
          type: 'Exam',
        ));
      }
    } catch (_) {}

    // 3) Homework due dates for this grade/section.
    try {
      final res = await api.get('/api/data/homework');
      for (final e in _parseList(res.data)) {
        if (sGrade.isNotEmpty && canonGrade(e['grade'] as String?) != sGrade) continue;
        if (!_calSectionMatches(e['section'] as String?, sSection)) continue;
        final d = DateTime.tryParse((e['dueDate'] as String?) ?? '');
        if (d == null) continue;
        out.add(CalendarEvent(
          date: DateTime(d.year, d.month, d.day),
          title: (e['title'] ?? 'Homework').toString(),
          time: (e['subject'] ?? '').toString(),
          type: 'Homework',
        ));
      }
    } catch (_) {}

    return out;
  } catch (_) {
    return out;
  }
});

// ─── Assignment Submissions ──────────────────────────────────────────────────
Future<void> submitAssignmentSubmission(
  WidgetRef ref, {
  required String assignmentId,
  required String content,
  String? fileUrl,
}) async {
  final api = ref.read(apiClientProvider);
  final profile = await ref.read(studentProfileProvider.future);
  if (profile.id.isEmpty) {
    throw Exception('Your student record could not be found.');
  }
  await api.post('/api/data/assignment_submissions', data: {
    'assignmentId': assignmentId,
    'studentId': profile.id,
    'studentName': profile.displayName,
    'content': content,
    'fileUrl': fileUrl ?? '',
    'submittedAt': DateTime.now().toIso8601String(),
    'status': 'submitted',
  });
}

// ─── Fee Payment Simulation & Receipt ───────────────────────────────────────
Future<void> payFeeInvoice(
  WidgetRef ref, {
  required String invoiceNumber,
  required double amount,
  required String paymentMethod,
}) async {
  final api = ref.read(apiClientProvider);
  final profile = await ref.read(studentProfileProvider.future);
  await api.post('/api/data/invoices/$invoiceNumber/pay', data: {
    'studentId': profile.id,
    'paidAmount': amount,
    'paymentMethod': paymentMethod,
    'paidAt': DateTime.now().toIso8601String(),
    'status': 'paid',
  }).catchError((_) async {
    // Fallback update
    await api.post('/api/data/invoices', data: {
      'id': invoiceNumber,
      'invoiceNumber': invoiceNumber,
      'studentId': profile.id,
      'amount': amount,
      'paidAmount': amount,
      'dueAmount': 0,
      'status': 'paid',
      'paidAt': DateTime.now().toIso8601String(),
    });
  });
}

// ─── Cafeteria ─────────────────────────────────────────────────────────────────
final studentCafeteriaProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/api/data/cafeteria_items');
    return _parseList(res.data);
  } catch (_) {
    return [];
  }
});

Future<void> placeCafeteriaOrder(
  WidgetRef ref, {
  required String itemId,
  required String itemName,
  required double price,
}) async {
  final api = ref.read(apiClientProvider);
  final profile = await ref.read(studentProfileProvider.future);
  await api.post('/api/data/cafeteria_orders', data: {
    'studentId': profile.id,
    'studentName': profile.displayName,
    'itemId': itemId,
    'itemName': itemName,
    'amount': price,
    'orderedAt': DateTime.now().toIso8601String(),
    'status': 'confirmed',
  });
}

// ─── Health Records ────────────────────────────────────────────────────────────
// Reads from the same `health_records` table the admin Health module writes to.
final studentHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    if (profile.id.isEmpty) return {};
    final res = await api.get('/api/data/health_records');
    final list = _parseList(res.data);
    return list.firstWhere(
      (h) => '${h['studentId']}' == profile.id ||
             '${h['studentName']}'.toLowerCase() == profile.displayName.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );
  } catch (_) {
    return {};
  }
});

// ─── Certificates ──────────────────────────────────────────────────────────────
final studentCertificatesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    final res = await api.get('/api/data/certificates');
    final list = _parseList(res.data);
    return list.where((c) =>
      '${c['studentId']}' == profile.id || '${c['studentName']}'.toLowerCase() == profile.displayName.toLowerCase()
    ).toList();
  } catch (_) {
    return [];
  }
});

// ─── Achievements ──────────────────────────────────────────────────────────────
// Reads individual achievement records from the same `achievements` table the
// admin Achievements module writes to. Each record: {title, type, award,
// studentId, studentName, date, status}. Only Approved records are shown.
final studentAchievementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    final res = await api.get('/api/data/achievements');
    final list = _parseList(res.data);
    return list.where((a) {
      final matchesStudent = '${a['studentId']}' == profile.id ||
          '${a['studentName']}'.toLowerCase() == profile.displayName.toLowerCase();
      final isApproved = '${a['status']}'.toLowerCase() == 'approved';
      return matchesStudent && isApproved;
    }).toList();
  } catch (_) {
    return [];
  }
});

// ─── Flashcards ────────────────────────────────────────────────────────────────
// Reads FlashCardSet records from the same `flashcard_sets` table the admin
// FlashCards module writes to. Each set has a `cards` JSON array of
// {question, answer} objects. We flatten all accessible sets into individual
// cards with {id, subject, front, back} so the existing swipe UI works unchanged.
// Only sets with access "students" or "public" are shown.
final studentFlashcardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final profile = await ref.watch(studentProfileProvider.future);
    final res = await api.get('/api/data/flashcard_sets');
    final sets = _parseList(res.data);

    final sGrade = canonGrade(profile.grade);
    final sSection = canonSection(profile.section);

    final out = <Map<String, dynamic>>[];
    for (final s in sets) {
      final access = '${s['access'] ?? 'private'}';
      if (access == 'private') continue;

      // Filter by grade/section when the set specifies them.
      final setGrade = canonGrade('${s['grade'] ?? ''}');
      final setSection = canonSection('${s['section'] ?? 'All Sections'}');
      if (setGrade.isNotEmpty && sGrade.isNotEmpty && setGrade != sGrade) continue;
      if (setSection.isNotEmpty && setSection != 'ALL' && setSection != 'ALLSECTIONS' &&
          sSection.isNotEmpty && setSection != sSection) continue;

      final subject = '${s['subject'] ?? s['name'] ?? ''}';
      final setId = '${s['id'] ?? ''}';

      // Parse the cards array — stored as JSON string or already decoded list.
      dynamic rawCards = s['cards'];
      if (rawCards is String && rawCards.isNotEmpty) {
        try { rawCards = json.decode(rawCards); } catch (_) { rawCards = null; }
      }
      if (rawCards is! List) continue;

      for (var i = 0; i < rawCards.length; i++) {
        final c = rawCards[i];
        if (c is! Map) continue;
        final front = '${c['question'] ?? c['front'] ?? ''}'.trim();
        final back = '${c['answer'] ?? c['back'] ?? ''}'.trim();
        if (front.isEmpty && back.isEmpty) continue;
        out.add({
          'id': '${setId}_$i',
          'subject': subject,
          'front': front,
          'back': back,
        });
      }
    }
    return out;
  } catch (_) {
    return [];
  }
});

