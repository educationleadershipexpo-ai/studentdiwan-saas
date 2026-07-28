import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/offline_cache.dart';
import '../core/ptm_availability.dart';
import '../models/models.dart';
import 'auth_provider.dart';
// The unified gradebook engine + curriculum band weights are already ported to
// the teacher module and are the single source of truth for grades. The parent
// gradebook computes the SAME weighted composite for the selected child rather
// than re-deriving an (incorrect) unweighted mean.
import '../../teacher/core/curriculum_config.dart' as gb;
import '../../teacher/core/gradebook_engine.dart' as gb;

// ── Selected Child ────────────────────────────────────────────────────────────
final selectedChildProvider = StateProvider<StudentModel?>((ref) => null);

// Persist the parent's active-child choice so it survives app restarts. We store
// only the child id (the full record is re-derived from childrenProvider on
// launch); the whole app reads selectedChildProvider, so restoring it restores
// the entire viewing context.
Future<void> persistSelectedChild(String childId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.selectedChildKey, childId);
  } catch (_) {}
}

Future<String?> readPersistedChildId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.selectedChildKey);
  } catch (_) {
    return null;
  }
}

// Set the active child everywhere: update state, drop the per-child caches so the
// next screen fetches the newly-selected child's data, and remember the choice.
void selectChild(WidgetRef ref, StudentModel kid) {
  ref.read(selectedChildProvider.notifier).state = kid;
  clearCache();
  persistSelectedChild(kid.id);
}

// ── Children Provider ─────────────────────────────────────────────────────────
// Fetches all students and filters client-side by father/mother/guardian email.
// The generic /api/data endpoint can't filter by nested email fields server-side.
final childrenProvider = FutureProvider<List<StudentModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];

  final email = auth.user!.email.toLowerCase().trim();
  final raw = await _fetch(AppConstants.students);
  final all = raw.map((j) => StudentModel.fromJson(j)).toList();

  // Match: exact email in parent fields (father/mother/guardian).
  // Real data only — if no student is linked, the UI shows an empty state.
  return all.where((s) => s.isLinkedTo(email)).toList();
});


// ── Generic cached data fetcher ───────────────────────────────────────────────
// Two-level cache: in-memory (instant, per-session) + Hive (persistent, survives restarts).
// On network failure, stale Hive data is returned so the app stays usable offline.
final _memCache = <String, List<Map<String, dynamic>>>{};

String _cacheKey(String entity, Map<String, dynamic>? params) =>
    params == null ? entity : '$entity?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';

Future<List<Map<String, dynamic>>> _fetch(
  String entity, {
  Map<String, dynamic>? params,
}) async {
  final key = _cacheKey(entity, params);

  // 1. In-memory hit (fastest path)
  if (_memCache.containsKey(key)) return _memCache[key]!;

  // 2. Valid Hive hit (still fresh)
  final cached = OfflineCache.get(key);
  if (cached != null) {
    _memCache[key] = cached;
    return cached;
  }

  // 3. Network fetch
  try {
    final data = await ApiClient.instance.getAll(entity, params: params);
    _memCache[key] = data;
    await OfflineCache.put(key, data);
    return data;
  } catch (e) {
    // 4. Offline fallback — return stale Hive data rather than crashing
    final stale = OfflineCache.getStale(key);
    if (stale != null) return stale;
    rethrow; // nothing cached at all — let the UI show ErrorState
  }
}

void clearCache() {
  _memCache.clear();
  OfflineCache.clear();
}

// ── Invoices (Fees) ───────────────────────────────────────────────────────────
final feesProvider = FutureProvider.family<List<InvoiceModel>, String>((ref, studentId) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.invoices, params: {'studentId': studentId});
  return raw
      .map((j) => InvoiceModel.fromJson(j))
      .where((inv) => inv.studentId == studentId)
      .toList()
    ..sort((a, b) => (b.dueDate ?? DateTime(2000)).compareTo(a.dueDate ?? DateTime(2000)));
});

// ── Attendance ────────────────────────────────────────────────────────────────
// Reads the SAME source as the desktop Parent portal (ParentAttendance.tsx): the
// per-session `TeacherAttendance` documents — {grade:"Grade 3", section:"B", date,
// marks:{<studentId>:"P"|"A"|"L"|"H"}}. The flat `attendance` table the mobile app
// read before is a different, unrelated store and showed the wrong data.
//
// Keyed by the child (StudentModel) rather than a bare id so we have the child's
// grade + section to match the session document.
final attendanceProvider =
    FutureProvider.family<List<AttendanceRecord>, StudentModel>((ref, kid) async {
  ref.watch(authProvider);
  if (kid.id.isEmpty) return [];

  final sGrade = _canonGrade(kid.grade);
  final sSection = _canonSection(kid.classSection);

  final rows = await _fetch(AppConstants.teacherAttendance);

  // Desktop mark codes → the status strings this screen colours.
  const statusLabel = {
    'P': 'Present', 'A': 'Absent', 'L': 'Late', 'H': 'Half day',
    'E': 'Excused', 'S': 'Sick',
  };

  final out = <AttendanceRecord>[];
  for (final r in rows) {
    // Match this child's class (grade + section), tolerant of "Grade 3"/"3".
    if (_canonGrade(r['grade']?.toString()) != sGrade) continue;
    if (sSection.isNotEmpty && _canonSection(r['section']?.toString()) != sSection) continue;

    final marks = r['marks'];
    if (marks is! Map) continue;
    final mark = marks[kid.id];
    if (mark == null) continue; // child not in this session's roster

    final dateStr = (r['date']?.toString()) ??
        (r['createdAt']?.toString().substring(0, 10)) ?? '';
    final date = _parseAttDate(dateStr);
    if (date == null) continue;

    out.add(AttendanceRecord(
      id: '${r['id'] ?? ''}_${kid.id}',
      studentId: kid.id,
      date: date,
      status: statusLabel[mark.toString().toUpperCase()] ?? 'Present',
    ));
  }
  out.sort((a, b) => b.date.compareTo(a.date));
  return out;
});

DateTime? _parseAttDate(String raw) {
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw.length > 10 ? raw.substring(0, 10) : raw);
}

// ── Absence Requests ──────────────────────────────────────────────────────────
// A parent's real absence requests for the selected child, read from the shared
// `StudentAbsenceRequest` table (the same table the class teacher reviews). Newest
// first. Real data only — no request is shown that the parent didn't submit.
final absenceRequestsProvider =
    FutureProvider.family<List<AbsenceRequestModel>, String>((ref, studentId) async {
  ref.watch(authProvider);
  if (studentId.isEmpty) return [];
  final rows = await _fetch('StudentAbsenceRequest').catchError((_) => <Map<String, dynamic>>[]);
  final out = rows
      .where((r) => (r['studentId']?.toString() ?? r['student_id']?.toString()) == studentId)
      .map((r) => AbsenceRequestModel.fromJson(r))
      .toList();
  out.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
  return out;
});

// Submit a real absence request to the school. Mirrors ParentAttendance.tsx
// handleSubmit exactly: writes the `StudentAbsenceRequest` (status "Pending")
// and best-effort notifies the child's class teacher so it reaches their real
// Attendance review panel. Throws on the primary write so the UI can surface an
// honest error.
class AbsenceService {
  static Future<void> submit({
    required StudentModel kid,
    required String parentUid,
    required String parentEmail,
    required String date,
    required String reason,
    String note = '',
  }) async {
    final id = 'ABSREQ-${kid.id}-${DateTime.now().millisecondsSinceEpoch}';
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await ApiClient.instance.createRecord('StudentAbsenceRequest', {
      'id': id,
      'studentId': kid.id,
      'studentName': kid.fullName,
      'grade': kid.grade,
      'section': kid.classSection,
      'parentUid': parentUid,
      'parentEmail': parentEmail,
      'date': date,
      'reason': reason,
      'note': note,
      'status': 'Pending',
      'createdAt': nowIso,
    });

    // Best-effort: alert the child's class teacher(s) by name so the request
    // surfaces in their real Attendance review panel sooner.
    try {
      final teachers = await _resolveAssignedTeachers(kid);
      final classTeacher = teachers.firstWhere(
        (t) => t.role == 'Class Teacher',
        orElse: () => teachers.isNotEmpty ? teachers.first : const AssignedTeacher(name: '', role: ''),
      );
      if (classTeacher.name.isNotEmpty) {
        await ApiClient.instance.createRecord('notifications', {
          'id': 'ntf-abs-$id',
          'title': 'Absence Request',
          'message': '${kid.fullName} — absence requested for $date ($reason).',
          'audienceRole': 'staff',
          'recipientName': classTeacher.name,
          'category': 'attendance',
          'entity': 'StudentAbsenceRequest',
          'type': 'absence_request_submitted',
          'read': false,
          'time': nowIso,
          'createdAt': nowIso,
          'uid': parentUid,
        });
      }
    } catch (_) {}
  }
}

// Canonicalise a grade to a bare comparable token: "Grade 3" / "grade 3" / "3" → "3".
String _canonGrade(String? raw) {
  var g = (raw ?? '').trim().toLowerCase();
  if (g.isEmpty) return '';
  g = g.replaceFirst(RegExp(r'^grade\s+'), '');
  return g.trim();
}

// Canonicalise a section to a bare comparable token: "Section B" / "B" → "b".
String _canonSection(String? raw) {
  var s = (raw ?? '').trim().toLowerCase();
  if (s.isEmpty) return '';
  s = s.replaceFirst(RegExp(r'^section\s+'), '');
  return s.trim();
}

// ── Assignments ───────────────────────────────────────────────────────────────
final assignmentsProvider = FutureProvider.family<List<AssignmentModel>, StudentModel>((ref, kid) async {
  ref.watch(authProvider);
  // Desktop ParentAssignments merges `homework` and "TeacherAssignment" rows,
  // then resolves each child's REAL status from `assignment_submissions`
  // (matched by studentId+assignmentId) — not the due date. Without the join,
  // an assignment a child already submitted or was graded on would show
  // "Pending"/"Overdue" forever, since the assignment record never changes.
  final results = await Future.wait([
    _fetch(AppConstants.homework).catchError((_) => <Map<String, dynamic>>[]),
    _fetch(AppConstants.assignments).catchError((_) => <Map<String, dynamic>>[]),
    _fetch('assignment_submissions').catchError((_) => <Map<String, dynamic>>[]),
  ]);
  // This child's submissions, keyed by assignmentId (last one wins).
  final mySubs = <String, Map<String, dynamic>>{};
  for (final s in results[2]) {
    if (s['studentId']?.toString() != kid.id) continue;
    final aid = s['assignmentId']?.toString() ?? s['assignment_id']?.toString();
    if (aid == null || aid.isEmpty) continue;
    mySubs[aid] = s;
  }
  final seen = <String>{};
  final merged = <AssignmentModel>[];
  for (final j in [...results[0], ...results[1]]) {
    final a = AssignmentModel.fromJson(j);
    if (a.id.isEmpty || !seen.add(a.id)) continue;
    final gradeOk = _canonGrade(a.grade) == _canonGrade(kid.grade);
    final rowSection = _canonSection(j['section']?.toString());
    final sectionOk = rowSection.isEmpty ||
        rowSection == 'all' ||
        rowSection == _canonSection(kid.classSection);
    if (!(a.studentId == kid.id ||
        (a.classId != null && a.classId == kid.classId) ||
        (gradeOk && sectionOk))) {
      continue;
    }
    // Enrich with the child's real submission status, if any.
    final sub = mySubs[a.id];
    if (sub != null) {
      final st = (sub['status'] ?? '').toString().toLowerCase();
      final graded = st == 'graded' || st == 'closed';
      merged.add(a.copyWith(
        submitted: true, // a submission row exists → the child has acted
        graded: graded,
        feedback: sub['feedback']?.toString(),
      ));
    } else {
      merged.add(a);
    }
  }
  return merged
    ..sort((a, b) => (b.dueDate ?? DateTime(2000)).compareTo(a.dueDate ?? DateTime(2000)));
});

// ── Weighted-composite Gradebook (parity with desktop ParentGradebook.tsx) ─────
// The parent gradebook must show the SAME weighted composite the teacher/admin
// gradebook computes — NOT a flat average of exam papers. It reuses the shared
// engine (teacher/core/gradebook_engine.dart), which auto-pulls the child's real
// Assignment + Assessment + Exam marks and weights them by the active
// curriculum's band for the child's grade. Real data only: an unmarked component
// contributes nothing and is never fabricated.

// The school's active curriculum (school_config/active_curriculum → default).
final parentCurriculumProvider = FutureProvider<gb.CurriculumConfig>((ref) async {
  ref.watch(authProvider);
  try {
    final rec = await ApiClient.instance.getOne('school_config', 'active_curriculum');
    final id = rec?['curriculumId']?.toString();
    return gb.getCurriculum(id);
  } catch (_) {
    return gb.getCurriculum(gb.defaultCurriculumId);
  }
});

// All raw gradebook source tables, loaded once (mirrors desktop loadGradebookSources).
final parentGradebookSourcesProvider = FutureProvider<gb.GradebookSources>((ref) async {
  ref.watch(authProvider);
  final results = await Future.wait([
    _fetch(AppConstants.assignments).catchError((_) => <Map<String, dynamic>>[]),
    _fetch('assignment_submissions').catchError((_) => <Map<String, dynamic>>[]),
    _fetch(AppConstants.assessments).catchError((_) => <Map<String, dynamic>>[]),
    _fetch(AppConstants.assessmentAttempts).catchError((_) => <Map<String, dynamic>>[]),
    _fetch(AppConstants.exams).catchError((_) => <Map<String, dynamic>>[]),
    _fetch(AppConstants.examMarks).catchError((_) => <Map<String, dynamic>>[]),
    _fetch('MarkOverride').catchError((_) => <Map<String, dynamic>>[]),
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

// The selected child's whole weighted gradebook (all subjects + overall %),
// optionally scoped to a term. Honest empty state when the child has no marks.
class ParentGradebookQuery {
  final StudentModel kid;
  final String? term; // null → all terms combined
  const ParentGradebookQuery(this.kid, {this.term});

  @override
  bool operator ==(Object other) =>
      other is ParentGradebookQuery && other.kid.id == kid.id && other.term == term;

  @override
  int get hashCode => Object.hash(kid.id, term);
}

final parentGradebookProvider =
    FutureProvider.family<gb.StudentGradebook, ParentGradebookQuery>((ref, q) async {
  final curriculum = await ref.watch(parentCurriculumProvider.future);
  final src = await ref.watch(parentGradebookSourcesProvider.future);
  final band = gb.getBandForGrade(curriculum, q.kid.grade);
  final student = gb.GradebookStudent(
    id: q.kid.id,
    name: q.kid.fullName,
    grade: q.kid.grade,
    section: q.kid.classSection,
  );
  return gb.computeStudentGradebook(student, band, src, term: q.term);
});

// The term labels for the active curriculum, so the parent can pick a term like
// the desktop's term selector (mirrors getPeriodLabels).
final parentTermLabelsProvider = FutureProvider<List<String>>((ref) async {
  final curriculum = await ref.watch(parentCurriculumProvider.future);
  return gb.getPeriodLabels(curriculum);
});

// ── Assessments ───────────────────────────────────────────────────────────────
// Real quizzes/tests/exams published via the teacher/admin Assessments module,
// with the child's own attempt folded in. Direct port of ParentAssessments.tsx:
//   • Only Active/Completed assessments for the child's canonical grade+section.
//   • Status comes from the real `assessment_attempts` row (merged with the
//     legacy `assessment_submissions` table), NOT the date alone.
//   • A score is shown only once the teacher has RELEASED results — the same
//     resultsReleased/resultVisibility gate the student app enforces. Without it,
//     a parent could see a graded score before it was released to the student.
final parentAssessmentsProvider =
    FutureProvider.family<List<AssessmentRow>, StudentModel>((ref, kid) async {
  ref.watch(authProvider);
  if (kid.id.isEmpty) return const [];

  final wantG = _canonGrade(kid.grade);
  final wantS = _canonSection(kid.classSection);

  final results = await Future.wait([
    _fetch(AppConstants.assessments).catchError((_) => <Map<String, dynamic>>[]),
    _fetch(AppConstants.assessmentAttempts).catchError((_) => <Map<String, dynamic>>[]),
    _fetch(AppConstants.assessmentSubmissions).catchError((_) => <Map<String, dynamic>>[]),
  ]);
  final rawAssessments = results[0];
  final rawAttempts = results[1];
  final rawLegacy = results[2];

  // Merge canonical attempts with legacy submissions (canonical wins on dupes),
  // keyed to this child only. Mirrors getAllAttempts() + the studentId filter.
  final myAttempts = <String, Map<String, dynamic>>{}; // assessmentId → attempt
  for (final a in rawAttempts) {
    if ((a['studentId'] ?? a['student_id'] ?? '').toString() != kid.id) continue;
    final aid = (a['assessmentId'] ?? a['assessment_id'] ?? '').toString();
    if (aid.isEmpty) continue;
    myAttempts[aid] = a;
  }
  for (final a in rawLegacy) {
    if ((a['student_id'] ?? a['studentId'] ?? '').toString() != kid.id) continue;
    final aid = (a['assessment_id'] ?? a['assessmentId'] ?? '').toString();
    if (aid.isEmpty || myAttempts.containsKey(aid)) continue;
    myAttempts[aid] = a;
  }

  final now = DateTime.now();
  final out = <AssessmentRow>[];
  for (final a in rawAssessments) {
    final status = (a['status'] ?? '').toString();
    if (status != 'Active' && status != 'Completed') continue;
    if (_canonGrade(a['grade']?.toString()) != wantG) continue;
    final rowSection = _canonSection(a['section']?.toString());
    if (rowSection.isNotEmpty && rowSection != wantS) continue;

    final attempt = myAttempts[(a['id'] ?? '').toString()];
    out.add(_mapAssessment(a, attempt, now));
  }
  return out;
});

// Fold an assessment + optional attempt into the parent-visible row, applying
// the exact release gate from ParentAssessments.tsx:mapAssessment.
AssessmentRow _mapAssessment(
  Map<String, dynamic> a,
  Map<String, dynamic>? attempt,
  DateTime now,
) {
  final testDate = DateTime.tryParse((a['date'] ?? '').toString());
  final visibility = (a['resultVisibility'] ?? '').toString();
  final resultsAvailable = a['resultsReleased'] == true ||
      visibility == 'immediate' ||
      visibility.isEmpty;

  final rawScore = attempt?['score'] ?? attempt?['marks_obtained'] ?? attempt?['marksObtained'];
  final isMarked = attempt != null &&
      (attempt['isMarked'] == true ||
          attempt['is_marked'] == true ||
          rawScore != null);
  final isGraded = isMarked && resultsAvailable;

  final String status;
  if (isGraded) {
    status = 'Graded';
  } else if (attempt != null) {
    status = 'Awaiting Marks';
  } else {
    status = (testDate != null && testDate.isBefore(now)) ? 'Missed' : 'Upcoming';
  }

  return AssessmentRow(
    id: (a['id'] ?? '').toString(),
    title: (a['title'] ?? '').toString().isEmpty ? 'Assessment' : (a['title']).toString(),
    subject: (a['subject'] ?? '').toString().isEmpty ? 'General' : (a['subject']).toString(),
    type: (a['type'] ?? '').toString().isEmpty ? 'Test' : (a['type']).toString(),
    date: (a['date'] ?? '').toString().isEmpty ? '—' : (a['date']).toString(),
    status: status,
    grade: (a['grade'] ?? '').toString().isEmpty ? null : (a['grade']).toString(),
    score: isGraded && rawScore != null ? double.tryParse(rawScore.toString()) : null,
    totalMarks: double.tryParse((a['totalMarks'] ?? '').toString()),
  );
}

// ── Report Cards ──────────────────────────────────────────────────────────────
final reportCardsProvider = FutureProvider.family<List<ReportCard>, String>((ref, studentId) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.reportCards, params: {'studentId': studentId});
  final cards = raw
      .map((j) => ReportCard.fromJson(j))
      .where((r) => r.studentId == studentId)
      // Only report cards the school has actually published reach a parent —
      // draft/submitted/verified/approved records are internal to staff.
      .where((r) => r.isVisibleToParent)
      .toList();
  // Chronological order, newest first. A plain string compare on `term`
  // ("Term 10" < "Term 2") is wrong; sort by academic year then by the term's
  // numeric index (falling back to the store's monotonic generatedAt stamp).
  cards.sort((a, b) {
    final yc = _yearKey(b.year).compareTo(_yearKey(a.year));
    if (yc != 0) return yc;
    final tc = _termIndex(b.term).compareTo(_termIndex(a.term));
    if (tc != 0) return tc;
    return b.generatedAt.compareTo(a.generatedAt);
  });
  return cards;
});

// Numeric key for an academic year label ("2024-2025" → 2024, "2025" → 2025).
int _yearKey(String year) {
  final m = RegExp(r'\d{4}').firstMatch(year);
  return m == null ? 0 : int.parse(m.group(0)!);
}

// The ordinal of a term/semester label: "Term 2" → 2, "Semester 1" → 1.
// Unnumbered labels sort to 0 so they never jump ahead of a numbered term.
int _termIndex(String term) {
  final m = RegExp(r'(\d+)').firstMatch(term);
  return m == null ? 0 : int.parse(m.group(1)!);
}

// ── Behaviour ─────────────────────────────────────────────────────────────────
final behaviourProvider = FutureProvider.family<List<BehaviorIncident>, String>((ref, studentId) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.behaviorIncidents, params: {'studentId': studentId});
  return raw
      .map((j) => BehaviorIncident.fromJson(j))
      .where((b) => b.studentId == studentId)
      .toList()
    ..sort((a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)));
});

// ── Achievements ──────────────────────────────────────────────────────────────
final achievementsProvider = FutureProvider.family<List<AchievementModel>, String>((ref, studentId) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.achievements, params: {'studentId': studentId});
  return raw
      .map((j) => AchievementModel.fromJson(j))
      .where((a) => a.studentId == studentId)
      .toList()
    ..sort((a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)));
});

// ── Health Records ────────────────────────────────────────────────────────────
final healthProvider = FutureProvider.family<List<HealthRecord>, String>((ref, studentId) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.healthRecords, params: {'studentId': studentId});
  return raw.map((j) => HealthRecord.fromJson(j)).where((h) => h.studentId == studentId).toList();
});

// ── Library Loans ─────────────────────────────────────────────────────────────
final libraryProvider = FutureProvider.family<List<LibraryLoan>, String>((ref, studentId) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.libraryLoans, params: {'studentId': studentId});
  return raw.map((j) => LibraryLoan.fromJson(j)).where((l) => l.studentId == studentId).toList()
    ..sort((a, b) => (b.borrowedDate ?? DateTime(2000)).compareTo(a.borrowedDate ?? DateTime(2000)));
});

// ── Transport ─────────────────────────────────────────────────────────────────
final transportProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, studentId) async {
  ref.watch(authProvider);

  final enrollRaw = await _fetch(AppConstants.transportEnrollments, params: {'studentId': studentId});
  final enrollment = enrollRaw
      .map((j) => TransportEnrollment.fromJson(j))
      .where((e) => e.studentId == studentId)
      .firstOrNull;

  TransportRoute? route;
  TransportVehicle? vehicle;

  if (enrollment != null) {
    final routeRaw = await _fetch(AppConstants.transportRoutes);
    final vehicleRaw = await _fetch(AppConstants.transportVehicles);
    route = routeRaw
        .map((j) => TransportRoute.fromJson(j))
        .where((r) => r.id == enrollment.routeId)
        .firstOrNull;
    vehicle = vehicleRaw
        .map((j) => TransportVehicle.fromJson(j))
        .where((v) => v.id == enrollment.vehicleId)
        .firstOrNull;
  }

  return {'enrollment': enrollment, 'route': route, 'vehicle': vehicle};
});

// ── Timetable ─────────────────────────────────────────────────────────────────
// The admin panel publishes the ENTIRE school timetable as a single record
// (id: "published-timetable-v3") in the `timetable_slots` table. Its `gridJson`
// is a JSON object keyed by class ("Grade 8-B") whose value is a 2-D grid:
//   grid[classKey][periodRow][dayCol] = { subject, teacher, room, mode }
// This is the exact same source the desktop Student/Parent web portals read, so
// the mobile app must decode it identically instead of expecting per-slot rows.
//
// Period rows in the admin grid map to the visible time slots below (matching
// the desktop ParentTimetable.tsx layout — periods 0,1,2 then a break, then 3,4).
const List<Map<String, String>> kTimetableSlots = [
  {'start': '08:00', 'end': '08:45'}, // adminPeriod 0
  {'start': '08:45', 'end': '09:30'}, // adminPeriod 1
  {'start': '09:30', 'end': '10:15'}, // adminPeriod 2
  {'start': '10:35', 'end': '11:20'}, // adminPeriod 3
  {'start': '11:20', 'end': '12:05'}, // adminPeriod 4
  {'start': '12:05', 'end': '12:50'}, // adminPeriod 5
];

// Normalize a child's grade to the admin's published class-key form ("Grade 3").
String _normalizeGrade(String raw) {
  final g = raw.trim();
  if (g.isEmpty) return '';
  if (RegExp(r'^grade\s', caseSensitive: false).hasMatch(g)) {
    return g.replaceFirst(RegExp(r'^grade\s+', caseSensitive: false), 'Grade ');
  }
  if (RegExp(r'^(pre-?kg|lkg|ukg|kg)', caseSensitive: false).hasMatch(g)) return g;
  return 'Grade $g';
}

String _stripKey(String k) => k.replaceAll(RegExp(r'\s+'), '').toLowerCase();

// Bumping this tick forces timetableProvider to re-run and pull a fresh copy
// from the server (bypassing the 15-min cache). The Timetable screen bumps it
// on a 15s poll, on pull-to-refresh, and when the app resumes — mirroring the
// desktop portal's 10s poll + socket refresh.
final timetableRefreshTick = StateProvider<int>((ref) => 0);

final timetableProvider =
    FutureProvider.family<Map<int, List<TimetableSlot>>, StudentModel>((ref, kid) async {
  ref.watch(authProvider);
  final tick = ref.watch(timetableRefreshTick);

  // Fetch the single published-timetable blob. Any tick > 0 forces a network
  // pull so re-published timetables show up without an app restart.
  final record = await _fetchTimetableBlob(forceNetwork: tick > 0);
  final gridJson = record?['gridJson'];
  if (gridJson is! String || gridJson.isEmpty) return {};

  Map<String, dynamic> allGrids;
  try {
    allGrids = jsonDecode(gridJson) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }

  // Resolve this child's class grid ("Grade 3-B"), tolerant of spacing/case.
  final grade = _normalizeGrade(kid.grade);
  final section = kid.classSection.trim().toUpperCase();
  final classKey = (grade.isNotEmpty && section.isNotEmpty) ? '$grade-$section' : '';
  dynamic classGrid;
  if (classKey.isNotEmpty) {
    classGrid = allGrids[classKey];
    if (classGrid == null) {
      final target = _stripKey(classKey);
      final match = allGrids.keys.firstWhere(
        (k) => _stripKey(k) == target,
        orElse: () => '',
      );
      if (match.isNotEmpty) classGrid = allGrids[match];
    }
  }
  if (classGrid is! List) return {};

  // classGrid[periodRow][dayCol] = cell. Day columns are 0=Mon .. 5=Sat; the
  // mobile UI shows Mon–Fri (day 1..5), so we map dayCol (0-based) → day (1-based).
  final Map<int, List<TimetableSlot>> grouped = {};
  for (int period = 0; period < classGrid.length && period < kTimetableSlots.length; period++) {
    final row = classGrid[period];
    if (row is! List) continue;
    final times = kTimetableSlots[period];
    for (int dayCol = 0; dayCol < row.length && dayCol < 5; dayCol++) {
      final cell = row[dayCol];
      if (cell is! Map) continue;
      final subject = (cell['subject'] ?? '').toString().trim();
      if (subject.isEmpty) continue;
      final day = dayCol + 1; // 1=Mon .. 5=Fri
      grouped.putIfAbsent(day, () => []).add(TimetableSlot(
            id: '${classKey}_${period}_$dayCol',
            classId: kid.classId,
            grade: kid.grade,
            day: day,
            startTime: times['start']!,
            endTime: times['end']!,
            subject: subject,
            teacher: (cell['teacher'] ?? '').toString().trim().isEmpty
                ? null
                : cell['teacher'].toString().trim(),
            room: (cell['room'] ?? '').toString().trim().isEmpty
                ? null
                : cell['room'].toString().trim(),
          ));
    }
  }
  for (final list in grouped.values) {
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  return grouped;
});

// Fetches the published-timetable blob with the same two-level cache as _fetch,
// but for a single record (getOne) rather than a list.
//
// [forceNetwork] skips the fresh-cache short-circuit so a poll / pull-to-refresh
// always pulls the newest published version from the server (the admin panel
// overwrites the same "published-timetable-v3" record on every publish). On a
// network error we still fall back to whatever is cached so the screen never
// goes blank offline.
Future<Map<String, dynamic>?> _fetchTimetableBlob({bool forceNetwork = false}) async {
  const key = 'timetable_slots/published-timetable-v3';
  if (!forceNetwork) {
    final cached = OfflineCache.get(key);
    if (cached != null && cached.isNotEmpty) return cached.first;
  }
  try {
    final rec = await ApiClient.instance.getOne(
      AppConstants.timetableSlots,
      'published-timetable-v3',
    );
    if (rec != null && rec['error'] == null) {
      await OfflineCache.put(key, [rec]);
      return rec;
    }
    // Server reachable but no record — fall back to any cached copy.
    final stale = OfflineCache.getStale(key);
    if (stale != null && stale.isNotEmpty) return stale.first;
    return null;
  } catch (_) {
    final stale = OfflineCache.getStale(key);
    if (stale != null && stale.isNotEmpty) return stale.first;
    rethrow;
  }
}

// ── Notices (Announcements) ───────────────────────────────────────────────────
final noticesProvider = FutureProvider<List<NoticeModel>>((ref) async {
  ref.watch(authProvider);
  // Filter to Published notices visible to parents/all
  final raw = await _fetch(AppConstants.notices, params: {'status': 'Published'});
  return raw.map((j) => NoticeModel.fromJson(j)).where((n) {
    final role = (n.targetRole ?? '').toLowerCase();
    return role.isEmpty || role.contains('parent') || role.contains('all');
  }).toList()
    ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
});

// ── Calendar Events (school functions, holidays, meetings) ────────────────────
// Reads the same `calendar_events` table the desktop ParentCalendar merges in.
// Failures degrade to an empty list so the calendar still renders exams,
// assignments and notices if this table is empty or unavailable.
final calendarEventsProvider = FutureProvider<List<CalendarEventModel>>((ref) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.calendarEvents)
      .catchError((_) => <Map<String, dynamic>>[]);
  return raw.map((j) => CalendarEventModel.fromJson(j)).toList();
});

// ── Notifications ─────────────────────────────────────────────────────────────
// Filter server-side by the parent's UID so only their notifications are shown.
final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];
  final uid = auth.user!.uid;
  // Try uid-specific first; the server stores notifications with uid = recipient
  final raw = await ApiClient.instance.getAll(
    AppConstants.notifications,
    params: {'uid': uid},
  );
  // If empty (e.g. notifications were sent broadcast with audienceRole='parent'),
  // fall back to fetching audience-targeted ones.
  final List<Map<String, dynamic>> combined;
  if (raw.isEmpty) {
    final broadcast = await ApiClient.instance.getAll(
      AppConstants.notifications,
      params: {'audienceRole': 'parent'},
    );
    combined = broadcast;
  } else {
    combined = raw;
  }
  return combined
      .map((j) => NotificationModel.fromJson(j))
      .toList()
    ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
});

// ── Exams ─────────────────────────────────────────────────────────────────────
// Faithful mirror of desktop ParentExams.tsx. An exam record is visible to a
// child only when it (a) matches the child's grade AND section and (b) has been
// published to students (`publishedToStudents != false`). Each record is
// expanded into one row per subject slot (using the plan for THIS child's grade,
// not the record's first grade). A released score is surfaced only when the exam
// is Published/Completed and a real mark exists for this child+subject in
// `exam_marks` — otherwise score/letter stay null (never a fabricated zero).
String _examStatusFromStore(Map<String, dynamic> e) {
  final s = (e['status'] ?? '').toString();
  return (s == 'Published' || s == 'Completed') ? 'Completed' : 'Upcoming';
}

final examsProvider = FutureProvider.family<List<ExamModel>, StudentModel>((ref, kid) async {
  ref.watch(authProvider);
  final results = await Future.wait([
    _fetch(AppConstants.exams).catchError((_) => <Map<String, dynamic>>[]),
    _fetch(AppConstants.examMarks).catchError((_) => <Map<String, dynamic>>[]),
  ]);
  final rawExams = results[0];
  final examMarks = gb.buildExamMarks(results[1]); // examId → subject → studentId → mark

  final student = gb.GradebookStudent(
    id: kid.id, name: kid.fullName, grade: kid.grade, section: kid.classSection);

  final out = <ExamModel>[];
  for (final rec in rawExams) {
    // Section match + publish gate — identical to the desktop filter.
    if (!gb.examMatchesSection(rec, kid.grade, kid.classSection)) continue;
    if (rec['publishedToStudents'] == false) continue;

    final recId = (rec['id'] ?? '').toString();
    final status = _examStatusFromStore(rec);
    final maxMarks = _examMax(rec);
    final mode = rec['mode']?.toString();
    final seat = rec['seatNumber']?.toString() ?? rec['seat']?.toString();
    final baseName = rec['name']?.toString() ?? rec['title']?.toString() ?? 'Exam';
    final baseVenue = rec['venue']?.toString() ?? rec['room']?.toString() ?? 'Main Hall';

    double? scoreFor(String subject) => examMarks[recId]?[subject]?[kid.id];

    final slots = gb.examSlotsForStudent(rec, student);
    if (slots.isEmpty) {
      // No subject timetable — one summary row for the whole record.
      final subject = rec['subjects']?.toString() ?? rec['subject']?.toString();
      final score = subject == null ? null : scoreFor(subject);
      final pct = (score != null && maxMarks > 0) ? (score / maxMarks * 100) : null;
      out.add(ExamModel(
        id: recId,
        examRecordId: recId,
        name: baseName,
        subject: (subject == null || subject.isEmpty) ? 'All Subjects' : subject,
        grade: kid.grade,
        classId: kid.classId,
        date: _parseAttDate(rec['startDate']?.toString() ?? rec['date']?.toString() ?? ''),
        time: rec['time']?.toString() ?? '09:00',
        venue: baseVenue,
        seatNumber: seat,
        mode: mode,
        totalMarks: maxMarks,
        score: score,
        letter: pct != null ? gb.letterFromPct(pct) : null,
        status: status,
      ));
    } else {
      // One row per subject slot in this child's grade plan.
      for (var i = 0; i < slots.length; i++) {
        final sl = slots[i];
        final subject = sl['subject']?.toString() ?? 'Subject';
        final score = scoreFor(subject);
        final pct = (score != null && maxMarks > 0) ? (score / maxMarks * 100) : null;
        final room = sl['room']?.toString() ?? baseVenue;
        out.add(ExamModel(
          id: '$recId-$i',
          examRecordId: recId,
          name: baseName,
          subject: subject,
          grade: kid.grade,
          classId: kid.classId,
          date: _parseAttDate(sl['date']?.toString() ?? rec['startDate']?.toString() ?? ''),
          time: sl['start']?.toString() ?? rec['time']?.toString(),
          venue: seat != null && seat.isNotEmpty ? '$room · Seat $seat' : room,
          seatNumber: seat,
          mode: mode,
          totalMarks: maxMarks,
          score: score,
          letter: pct != null ? gb.letterFromPct(pct) : null,
          status: status,
        ));
      }
    }
  }
  out.sort((a, b) => (a.date ?? DateTime(2099)).compareTo(b.date ?? DateTime(2099)));
  return out;
});

double _examMax(Map<String, dynamic> rec) {
  final v = rec['maxMarks'] ?? rec['totalMarks'];
  final n = (v is num) ? v.toDouble() : double.tryParse('${v ?? ''}');
  return (n == null || n == 0) ? 100.0 : n;
}

// ── Study Materials ───────────────────────────────────────────────────────────
final studyMaterialsProvider = FutureProvider.family<List<StudyMaterial>, StudentModel>((ref, kid) async {
  ref.watch(authProvider);
  final params = kid.grade.isNotEmpty ? {'grade': kid.grade} : <String, dynamic>{};
  final raw = await _fetch(AppConstants.studyMaterials, params: params.isEmpty ? null : params);
  return raw
      .map((j) => StudyMaterial.fromJson(j))
      .where((m) => m.grade == kid.grade || m.classId == kid.classId)
      .toList()
    ..sort((a, b) => (b.uploadedAt ?? DateTime(2000)).compareTo(a.uploadedAt ?? DateTime(2000)));
});

// ── Student Documents ─────────────────────────────────────────────────────────
final documentsProvider = FutureProvider.family<List<StudentDocument>, String>((ref, studentId) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.studentDocuments, params: {'studentId': studentId});
  return raw.map((j) => StudentDocument.fromJson(j)).where((d) => d.studentId == studentId).toList();
});

// ── Messages (shared chat model — the SAME tables the desktop web app uses) ──
// The desktop `Messages.tsx` / `ParentMessages.tsx` store every conversation in
// the server-backed `chat_threads` / `chat_messages` tables, so BOTH the parent
// and the teacher read the exact same records — a reply here shows up in the
// teacher app and on desktop. The mobile parent portal previously read a
// disconnected flat `messages` table (read-only, no reply). These providers read
// the shared tables so the parent can have a REAL two-way conversation.
//
// This mirrors the mobile teacher portal's chat engine
// (teacher/providers/data_provider.dart) — same models, same ChatService, same
// deterministic `dm_<sortedUids>` thread id — so a conversation opened from
// either side dedupes to ONE shared thread. Only the contact pool differs.

// A conversation thread, shared by every participant (mirrors the desktop ThreadRow).
class ChatThread {
  final String id;
  final String type; // "direct" | "group"
  final String rawName; // creator-typed name (only meaningful for groups)
  final List<Map<String, dynamic>> participants;
  final String createdBy;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderUid;
  final bool unread;
  final String displayName; // resolved per-viewer (the OTHER party for direct)
  final String otherRole; // role of the other participant (direct only)
  final String otherEmail;

  const ChatThread({
    required this.id,
    required this.type,
    required this.rawName,
    required this.participants,
    required this.createdBy,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderUid,
    this.unread = false,
    required this.displayName,
    this.otherRole = '',
    this.otherEmail = '',
  });

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// One message within a thread (mirrors the desktop MessageRow).
class ChatMessage {
  final String id;
  final String threadId;
  final String senderUid;
  final String senderName;
  final String text;
  final List<Map<String, dynamic>> attachments;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderUid,
    required this.senderName,
    required this.text,
    this.attachments = const [],
    required this.createdAt,
  });
}

// Does this participant record refer to the signed-in parent? The server emits
// chat events to BOTH `user:<uid>` and `user:<email>` rooms, so a thread may
// carry the parent keyed by either — match on both.
bool _isMe(Map participant, String myUid, String myEmail) {
  final uid = (participant['uid'] ?? '').toString();
  final email = (participant['email'] ?? '').toString().toLowerCase();
  return (myUid.isNotEmpty && uid == myUid) ||
      (myEmail.isNotEmpty && email == myEmail);
}

// The parent's own conversation threads, newest first — read from the shared
// `chat_threads` table and enriched with unread state from `chat_thread_states`.
final parentChatThreadsProvider = FutureProvider<List<ChatThread>>((ref) async {
  final auth = ref.watch(authProvider);
  final me = auth.user;
  if (me == null) return const [];
  final myUid = me.uid;
  final myEmail = me.email.toLowerCase().trim();

  try {
    final rawThreads = await ApiClient.instance.getAll('chat_threads');
    final rawStates = await ApiClient.instance.getAll('chat_thread_states');

    // My per-thread read state (id == "<threadId>__<myUid>").
    final myLastRead = <String, DateTime>{};
    for (final s in rawStates) {
      if ((s['uid'] ?? '').toString() != myUid) continue;
      final tId = (s['threadId'] ?? '').toString();
      final lr = DateTime.tryParse((s['lastReadAt'] ?? '').toString());
      if (tId.isNotEmpty && lr != null) myLastRead[tId] = lr;
    }

    final mine = <ChatThread>[];
    for (final t in rawThreads) {
      final participants = ((t['participants'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
      if (!participants.any((p) => _isMe(p, myUid, myEmail))) continue;

      final type = (t['type'] ?? 'direct').toString();
      final other = participants.firstWhere(
        (p) => !_isMe(p, myUid, myEmail),
        orElse: () => <String, dynamic>{},
      );
      final display = type == 'group'
          ? (t['name'] ?? 'Group').toString()
          : (other['name'] ?? t['name'] ?? 'Conversation').toString();

      final id = (t['id'] ?? '').toString();
      final lastAt = DateTime.tryParse((t['lastMessageAt'] ?? t['createdAt'] ?? '').toString());
      final lastSender = (t['lastSenderUid'] ?? '').toString();
      final read = myLastRead[id];
      final unread = lastSender.isNotEmpty &&
          lastSender != myUid &&
          lastAt != null &&
          (read == null || lastAt.isAfter(read));

      mine.add(ChatThread(
        id: id,
        type: type,
        rawName: (t['name'] ?? '').toString(),
        participants: participants,
        createdBy: (t['createdBy'] ?? '').toString(),
        lastMessage: (t['lastMessage'] ?? '').toString(),
        lastMessageAt: lastAt,
        lastSenderUid: lastSender,
        unread: unread,
        displayName: display,
        otherRole: (other['role'] ?? '').toString(),
        otherEmail: (other['email'] ?? '').toString(),
      ));
    }

    mine.sort((a, b) {
      final ax = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bx = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bx.compareTo(ax);
    });
    return mine;
  } catch (_) {
    return const [];
  }
});

// Full message history for one thread, oldest → newest (shared across parties).
final parentChatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, threadId) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll('chat_messages');
    final msgs = raw
        .where((m) => (m['threadId'] ?? '').toString() == threadId)
        .map((m) => ChatMessage(
              id: (m['id'] ?? '').toString(),
              threadId: threadId,
              senderUid: (m['senderUid'] ?? '').toString(),
              senderName: (m['senderName'] ?? 'Unknown').toString(),
              text: (m['text'] ?? m['content'] ?? '').toString(),
              attachments: ((m['attachments'] as List?) ?? const [])
                  .whereType<Map>()
                  .map((a) => Map<String, dynamic>.from(a))
                  .toList(),
              createdAt: DateTime.tryParse((m['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0),
            ))
        .toList();
    msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return msgs;
  } catch (_) {
    return const [];
  }
});

// Count of unread threads — drives the inbox badge.
final parentUnreadThreadsProvider = FutureProvider<int>((ref) async {
  final threads = await ref.watch(parentChatThreadsProvider.future);
  return threads.where((t) => t.unread).length;
});

// ── Chat write helpers (shared thread model) ─────────────────────────────────
// Posts into the exact same shared tables the desktop reads. Copied verbatim
// from the teacher portal so both sides behave identically.
class ChatService {
  // Send a message into an existing thread and bump the thread's summary.
  static Future<void> sendToThread({
    required String threadId,
    required List<Map<String, dynamic>> participants,
    required String senderUid,
    required String senderName,
    required String text,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await ApiClient.instance.createRecord('chat_messages', {
      'threadId': threadId,
      'senderUid': senderUid,
      'senderName': senderName,
      'text': text,
      'attachments': const [],
      'createdAt': now,
    });
    await ApiClient.instance.updateRecord('chat_threads', threadId, {
      'lastMessage': text,
      'lastMessageAt': now,
      'lastSenderUid': senderUid,
    });
    await markThreadRead(threadId: threadId, myUid: senderUid);
  }

  // Upsert my per-user read state for a thread (id == "<threadId>__<uid>").
  static Future<void> markThreadRead({
    required String threadId,
    required String myUid,
  }) async {
    final id = '${threadId}__$myUid';
    await ApiClient.instance.createRecord('chat_thread_states', {
      'id': id,
      'threadId': threadId,
      'uid': myUid,
      'lastReadAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // Find an existing direct thread with `otherUid`, or create a shared one.
  // Returns the thread id. Deterministic id (sorted uids) matches the desktop
  // so a conversation started on either side dedupes to ONE shared thread.
  static Future<String> startDirectThread({
    required String myUid,
    required String myName,
    required String myEmail,
    required String myRole,
    required String otherUid,
    required String otherName,
    required String otherEmail,
    required String otherRole,
  }) async {
    final existing = await ApiClient.instance.getAll('chat_threads');
    for (final t in existing) {
      if ((t['type'] ?? '').toString() != 'direct') continue;
      final parts = ((t['participants'] as List?) ?? const []).whereType<Map>();
      final hasMe = parts.any((p) => (p['uid'] ?? '') == myUid);
      final hasOther = parts.any((p) => (p['uid'] ?? '') == otherUid);
      if (hasMe && hasOther) return (t['id'] ?? '').toString();
    }
    final ids = [myUid, otherUid]..sort();
    final id = 'dm_${ids.join('_')}';
    await ApiClient.instance.createRecord('chat_threads', {
      'id': id,
      'type': 'direct',
      'name': otherName,
      'participants': [
        {'uid': myUid, 'name': myName, 'role': myRole, 'email': myEmail},
        {'uid': otherUid, 'name': otherName, 'role': otherRole, 'email': otherEmail},
      ],
      'createdBy': myUid,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    return id;
  }
}

// A person the parent is allowed to start a conversation with.
class ChatContact {
  final String uid;
  final String name;
  final String email;
  final String role; // "staff"
  final String subtitle; // e.g. "Class Teacher", "Mathematics", "School Office"
  const ChatContact({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.subtitle = '',
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── Assigned teachers for a child (shared by PTM booking + chat contacts) ─────
// A teacher the school has really assigned to this child's class — the Class
// Teacher (homeroom) from `classes`, and the Subject Teachers from
// `subject_assignments`. Mirrors ParentPTM.tsx's resolution exactly, using the
// same master data the school itself edits (never a guessed/stale field).
class AssignedTeacher {
  final String name;
  final String role; // "Class Teacher" | "Subject Teacher"
  final String? subject;
  const AssignedTeacher({required this.name, required this.role, this.subject});
}

// Resolve the child's assigned teachers from `classes` + `subject_assignments`.
Future<List<AssignedTeacher>> _resolveAssignedTeachers(StudentModel kid) async {
  if (kid.grade.trim().isEmpty) return const [];
  final results = await Future.wait([
    _fetch('classes').catchError((_) => <Map<String, dynamic>>[]),
    _fetch('subject_assignments').catchError((_) => <Map<String, dynamic>>[]),
  ]);
  final classes = results[0];
  final subjectAssignments = results[1];

  final wantGrade = _canonGrade(kid.grade);
  final wantSection = _canonSection(kid.classSection);

  final teachers = <AssignedTeacher>[];

  // Class Teacher — the homeroom `teacher` on the matched Class row. A Class
  // record often carries its section only inside `name` ("Grade 3 Section A"),
  // so fall back to parsing the name when the `section` field is blank.
  final cls = classes.firstWhere(
    (c) =>
        _canonGrade(c['grade']?.toString()) == wantGrade &&
        _canonSection(_classSection(c)) == wantSection,
    orElse: () => <String, dynamic>{},
  );
  final classTeacher = (cls['teacher'] ?? '').toString().trim();
  if (classTeacher.isNotEmpty) {
    teachers.add(AssignedTeacher(name: classTeacher, role: 'Class Teacher'));
  }

  // Subject Teachers — every subject_assignment row for this grade+section.
  for (final a in subjectAssignments) {
    if (_canonGrade(a['grade']?.toString()) != wantGrade) continue;
    if (_canonSection(a['section']?.toString()) != wantSection) continue;
    final name = (a['teacherName'] ?? a['teacher'] ?? '').toString().trim();
    if (name.isEmpty) continue;
    final subject = (a['subject'] ?? a['subjectName'] ?? '').toString().trim();
    final dup = teachers.any((t) => t.name == name && t.subject == (subject.isEmpty ? null : subject));
    if (!dup) {
      teachers.add(AssignedTeacher(
        name: name,
        role: 'Subject Teacher',
        subject: subject.isEmpty ? null : subject,
      ));
    }
  }
  return teachers;
}

// A Class row's section — most Class records only carry the section inside
// `name` (e.g. "Grade 3 Section A"), leaving the dedicated `section` field
// blank. Falls back to parsing `name`, mirroring studentGradeSection.ts.
String _classSection(Map<String, dynamic> cls) {
  final s = (cls['section'] ?? '').toString().trim();
  if (s.isNotEmpty) return s;
  final name = (cls['name'] ?? '').toString();
  final m = RegExp(r'Section\s+([A-Za-z])\s*$', caseSensitive: false).firstMatch(name) ??
      RegExp(r'-\s*([A-Za-z])\s*$').firstMatch(name);
  return m != null ? m.group(1)! : '';
}

// The child's assigned teachers — public provider (used by the PTM booking flow
// and, resolved to real accounts, by the chat contact pool).
final assignedTeachersProvider =
    FutureProvider.family<List<AssignedTeacher>, StudentModel>((ref, kid) async {
  ref.watch(authProvider);
  return _resolveAssignedTeachers(kid);
});

// People the parent can message: the selected child's real teachers (resolved
// from names to chat accounts via `staff`) plus the School Office (admin /
// principal / vice-principal staff). The `users` table is admin-only for a
// parent token, so we resolve accounts through `staff` (real backend rows,
// which carry uid/email/role) — never seed data. De-duped by uid.
final parentChatContactsProvider = FutureProvider<List<ChatContact>>((ref) async {
  final me = ref.watch(authProvider).user;
  final myUid = me?.uid ?? '';
  final kid = ref.watch(selectedChildProvider);

  List<Map<String, dynamic>> staff;
  try {
    staff = await _fetch('staff');
  } catch (_) {
    staff = const [];
  }

  // Index staff by lower-cased name for the name→account join.
  Map<String, dynamic>? staffByName(String name) {
    final target = name.trim().toLowerCase();
    if (target.isEmpty) return null;
    for (final s in staff) {
      final sn = (s['name'] ?? s['displayName'] ?? '').toString().trim().toLowerCase();
      if (sn == target) return s;
    }
    return null;
  }

  final out = <String, ChatContact>{};

  // 1. The child's assigned teachers → resolve each name to a real staff account.
  if (kid != null) {
    try {
      final teachers = await _resolveAssignedTeachers(kid);
      for (final t in teachers) {
        final s = staffByName(t.name);
        if (s == null) continue; // no account → can't open a real thread
        final uid = (s['uid'] ?? s['id'] ?? '').toString();
        if (uid.isEmpty || uid == myUid) continue;
        out[uid] = ChatContact(
          uid: uid,
          name: (s['name'] ?? s['displayName'] ?? t.name).toString(),
          email: (s['email'] ?? '').toString(),
          role: 'staff',
          subtitle: t.subject != null && t.subject!.isNotEmpty ? t.subject! : t.role,
        );
      }
    } catch (_) {}
  }

  // 2. School Office — admin / principal / vice-principal staff.
  const officeRoles = {'admin', 'principal', 'vice_principal', 'vice-principal'};
  for (final s in staff) {
    final role = (s['role'] ?? '').toString().toLowerCase().trim();
    if (!officeRoles.contains(role)) continue;
    final uid = (s['uid'] ?? s['id'] ?? '').toString();
    if (uid.isEmpty || uid == myUid) continue;
    out.putIfAbsent(uid, () => ChatContact(
      uid: uid,
      name: (s['name'] ?? s['displayName'] ?? 'School Office').toString(),
      email: (s['email'] ?? '').toString(),
      role: 'staff',
      subtitle: 'School Office',
    ));
  }

  final list = out.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
});

// ── PTM (Parent-Teacher Meeting) sessions ────────────────────────────────────
// Reads the shared raw `PTMSession` entity (same rows the desktop ParentPTM and
// the teacher app read). Scoped to the selected child by id OR name, exactly as
// ParentPTM.tsx:58. Real data only.
final parentPtmSessionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, StudentModel>((ref, kid) async {
  ref.watch(authProvider);
  if (kid.id.isEmpty && kid.fullName.trim().isEmpty) return const [];
  try {
    final rows = await ApiClient.instance.getAll('PTMSession');
    final mine = rows.where((s) {
      final sid = (s['studentId'] ?? '').toString();
      final sname = (s['student'] ?? '').toString();
      return (sid.isNotEmpty && sid == kid.id) ||
          (sname.isNotEmpty && sname == kid.fullName);
    }).toList();
    mine.sort((a, b) {
      final ad = (a['date'] ?? '').toString();
      final bd = (b['date'] ?? '').toString();
      return bd.compareTo(ad);
    });
    return mine;
  } catch (_) {
    return const [];
  }
});

// ── PTM booking / cancellation writes ────────────────────────────────────────
// Mirrors ParentPTM.tsx handleBook / handleCancel exactly, against the same
// shared entities (PTMSession, CalendarEvent, notifications). Every write is
// real backend data — a booking here shows up in the teacher app and on the
// desktop, and lands on the parent's own Calendar. No mock/seed data.
class PtmService {
  // Book a meeting: create the Pending PTMSession, a private CalendarEvent for
  // this family, and a notification to the teacher. Returns the created
  // PTMSession id. Throws on the primary PTMSession failure so the caller can
  // surface an honest error; the calendar + notification are best-effort.
  static Future<String> book({
    required StudentModel kid,
    required String parentName,
    required String parentUid,
    required String teacherName,
    required String meetingWith, // "Class Teacher" | "Subject Teacher"
    required String meetingType, // "Offline" | "Online"
    required String time,
    required String date,
    String? subject,
    String? purpose,
  }) async {
    final id = 'ptm-${DateTime.now().millisecondsSinceEpoch}';
    final isOnline = meetingType == 'Online';
    final resolvedSubject = (subject != null && subject.trim().isNotEmpty)
        ? subject.trim()
        : (meetingWith == 'Class Teacher' ? 'General' : '');
    final meetingLink = isOnline ? generateJitsiLink('$teacherName-${kid.fullName}') : null;
    final location = isOnline
        ? null
        : '${kid.grade} - Section ${kid.classSection} classroom';
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final cleanPurpose = (purpose ?? '').trim();

    await ApiClient.instance.createRecord('PTMSession', {
      'id': id,
      'date': date,
      'timeRange': time,
      'nextSlot': time,
      'teacher': teacherName,
      'subject': resolvedSubject,
      'student': kid.fullName,
      'studentId': kid.id,
      'studentGrade': kid.grade,
      'studentSection': kid.classSection,
      'status': 'Pending',
      'parent': parentName.isNotEmpty ? parentName : 'Parent',
      if (cleanPurpose.isNotEmpty) 'purpose': cleanPurpose,
      'meetingMode': meetingType,
      'allowOnline': isOnline,
      'allowOffline': !isOnline,
      if (isOnline) 'platform': 'Jitsi Meet',
      if (meetingLink != null) 'meetingLink': meetingLink,
      if (location != null) 'location': location,
      'uid': parentUid,
      'createdAt': nowIso,
    });

    // Private calendar entry for this family (deterministic id → cancellable).
    try {
      await ApiClient.instance.createRecord('CalendarEvent', {
        'id': 'cal-$id',
        'title': 'PTM with $teacherName',
        if (cleanPurpose.isNotEmpty) 'description': cleanPurpose,
        'date': date,
        'time': time,
        'location': location ?? (isOnline ? 'Online' : ''),
        'category': 'Meetings',
        'color': 'bg-purple-500',
        'source': 'PTM',
        'recipientStudentId': kid.id,
        'createdBy': parentUid,
        'createdAt': nowIso,
      });
    } catch (_) {}

    // Notify the teacher (mirrors notifyPTMEvent("requested") / pushNotify).
    try {
      await _pushPtmNotify(
        title: 'New PTM Request',
        message:
            '${parentName.isNotEmpty ? parentName : "A parent"} requested a meeting about ${kid.fullName} for $date at $time.',
        recipientName: teacherName,
        uid: parentUid,
      );
    } catch (_) {}

    return id;
  }

  // Cancel a meeting: flip status to Cancelled, remove the calendar entry, and
  // notify the teacher (mirrors handleCancel + notifyPTMEvent("cancelled-by-parent")).
  static Future<void> cancel({
    required Map<String, dynamic> session,
    required String parentUid,
  }) async {
    final id = (session['id'] ?? '').toString();
    if (id.isEmpty) return;
    await ApiClient.instance.updateRecord('PTMSession', id, {'status': 'Cancelled'});
    try {
      await ApiClient.instance.deleteRecord('CalendarEvent', 'cal-$id');
    } catch (_) {}
    try {
      final student = (session['student'] ?? '').toString();
      final teacher = (session['teacher'] ?? '').toString();
      final date = (session['date'] ?? '').toString();
      final time = (session['timeRange'] ?? session['nextSlot'] ?? '').toString();
      final parent = (session['parent'] ?? '').toString();
      await _pushPtmNotify(
        title: 'PTM Cancelled',
        message:
            '${parent.isNotEmpty ? parent : "The parent"} cancelled the meeting about $student ($date at $time).',
        recipientName: teacher,
        uid: parentUid,
      );
    } catch (_) {}
  }

  // Real notification write, mirroring the desktop pushNotify payload shape so
  // the teacher app / desktop inbox picks it up.
  static Future<void> _pushPtmNotify({
    required String title,
    required String message,
    required String recipientName,
    required String uid,
  }) async {
    final now = DateTime.now();
    await ApiClient.instance.createRecord('notifications', {
      'id': 'ntf-${now.millisecondsSinceEpoch}',
      'title': title,
      'message': message,
      'audienceRole': 'staff',
      'recipientName': recipientName,
      'category': 'ptm',
      'entity': 'PTMSession',
      'read': false,
      'time': now.toUtc().toIso8601String(),
      'createdAt': now.toUtc().toIso8601String(),
      'uid': uid,
    });
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
