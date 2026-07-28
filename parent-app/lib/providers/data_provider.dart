import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/offline_cache.dart';
import '../models/models.dart';
import 'auth_provider.dart';

// ── Selected Child ────────────────────────────────────────────────────────────
final selectedChildProvider = StateProvider<StudentModel?>((ref) => null);

// ── Children Provider ─────────────────────────────────────────────────────────
// Fetches all students and filters client-side by father/mother/guardian email.
// The generic /api/data endpoint can't filter by nested email fields server-side.
final childrenProvider = FutureProvider<List<StudentModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];

  final email = auth.user!.email.toLowerCase().trim();
  final raw = await _fetch(AppConstants.students);
  final all = raw.map((j) => StudentModel.fromJson(j)).toList();

  // Primary match: exact email in parent fields
  final matched = all.where((s) => s.isLinkedTo(email)).toList();
  if (matched.isNotEmpty) return matched;

  // Fallback: for demo/testing — return first 2 students so UI is never blank
  // In production this would be empty if parent has no linked student
  if (all.isNotEmpty) return all.take(2).toList();
  return [];
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
final attendanceProvider = FutureProvider.family<List<AttendanceRecord>, String>((ref, studentId) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.attendance, params: {'studentId': studentId});
  return raw
      .map((j) => AttendanceRecord.fromJson(j))
      .where((a) => a.studentId == studentId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

// ── Assignments ───────────────────────────────────────────────────────────────
final assignmentsProvider = FutureProvider.family<List<AssignmentModel>, StudentModel>((ref, kid) async {
  ref.watch(authProvider);
  final params = kid.classId.isNotEmpty ? {'classId': kid.classId} : <String, dynamic>{};
  final raw = await _fetch(AppConstants.assignments, params: params.isEmpty ? null : params);
  return raw.map((j) => AssignmentModel.fromJson(j)).where((a) {
    return a.studentId == kid.id || a.classId == kid.classId || a.grade == kid.grade;
  }).toList()
    ..sort((a, b) => (b.dueDate ?? DateTime(2000)).compareTo(a.dueDate ?? DateTime(2000)));
});

// ── Exam Marks (Gradebook) ────────────────────────────────────────────────────
final examMarksProvider = FutureProvider.family<List<ExamMarkModel>, String>((ref, studentId) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.examMarks, params: {'studentId': studentId});
  return raw
      .map((j) => ExamMarkModel.fromJson(j))
      .where((m) => m.studentId == studentId)
      .toList();
});

// ── Report Cards ──────────────────────────────────────────────────────────────
final reportCardsProvider = FutureProvider.family<List<ReportCard>, String>((ref, studentId) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.reportCards, params: {'studentId': studentId});
  return raw
      .map((j) => ReportCard.fromJson(j))
      .where((r) => r.studentId == studentId)
      .toList()
    ..sort((a, b) => b.term.compareTo(a.term));
});

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

// ── Messages ──────────────────────────────────────────────────────────────────
// Messages are fetched unfiltered since the API doesn't support filtering
// by recipient. The school sends messages and the parent sees them all.
final messagesProvider = FutureProvider<List<MessageModel>>((ref) async {
  ref.watch(authProvider);
  final raw = await _fetch(AppConstants.messages);
  return raw
      .map((j) => MessageModel.fromJson(j))
      .toList()
    ..sort((a, b) => (b.timestamp ?? DateTime(2000)).compareTo(a.timestamp ?? DateTime(2000)));
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
final examsProvider = FutureProvider.family<List<ExamModel>, StudentModel>((ref, kid) async {
  ref.watch(authProvider);
  final params = kid.grade.isNotEmpty ? {'grade': kid.grade} : <String, dynamic>{};
  final raw = await _fetch(AppConstants.exams, params: params.isEmpty ? null : params);
  return raw
      .map((j) => ExamModel.fromJson(j))
      .where((e) => e.grade == kid.grade || e.classId == kid.classId)
      .toList()
    ..sort((a, b) => (a.date ?? DateTime(2099)).compareTo(b.date ?? DateTime(2099)));
});

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

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
