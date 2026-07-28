import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../core/api_client.dart';
import '../core/offline_cache.dart';
import '../core/curriculum_config.dart';
import '../core/gradebook_engine.dart';
import '../core/gradebook_approval.dart';
import '../models/models.dart';
import 'auth_provider.dart';

// ── Selection State ─────────────────────────────────────────────────────────
final selectedClassProvider = StateProvider<ClassModel?>((ref) => null);
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Render a grade value as "Grade 3" with a SINGLE prefix — a backend value that
// already reads "Grade 3" / "grade 3" is not doubled to "Grade Grade 3".
String _gradeDisplay(dynamic g) {
  final raw = (g ?? '').toString().trim();
  if (raw.isEmpty) return 'Grade';
  final stripped = raw.replaceFirst(RegExp(r'^grade\s*', caseSensitive: false), '').trim();
  return 'Grade $stripped';
}

// ── Generic API Fetcher ────────────────────────────────────────────────────────
final _memCache = <String, List<Map<String, dynamic>>>{};

void clearCache() {
  _memCache.clear();
  OfflineCache.clear();
}

// ── All Students (from real DB — 110 Omani students) ─────────────────────────
final allStudentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll('students');
    return raw;
  } catch (_) {
    return [];
  }
});

// ── Classes Provider (real DB — 12 classes) ───────────────────────────────────
final classesProvider = FutureProvider<List<ClassModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];

  try {
    final raw = await ApiClient.instance.getAll('classes');
    if (raw.isNotEmpty) {
      return raw.map((j) => ClassModel(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        grade: _gradeDisplay(j['grade']),
        section: (j['sections'] is List) ? (j['sections'] as List).first.toString() : '',
        studentCount: (j['studentsCount'] as num?)?.toInt() ?? 28,
        subject: (j['subjects'] is List && (j['subjects'] as List).isNotEmpty)
            ? (j['subjects'] as List).first.toString()
            : 'General',
      )).toList();
    }
  } catch (_) {}

  // Use sections for more granular class list
  try {
    final sections = await ApiClient.instance.getAll('sections');
    if (sections.isNotEmpty) {
      return sections.map((s) => ClassModel(
        id: s['id'] as String? ?? '',
        name: '${s['className'] ?? ''} - ${s['name'] ?? ''}',
        grade: s['className'] as String? ?? '',
        section: s['name'] as String? ?? '',
        studentCount: (s['studentsCount'] as num?)?.toInt() ?? (s['capacity'] as num?)?.toInt() ?? 40,
        subject: 'General',
      )).toList();
    }
  } catch (_) {}

  // Real data only — no seed roster. Empty list drives an empty state in the UI.
  return [];
});

// ── Students Provider (filtered by classId from real DB) ──────────────────────
final studentsProvider = FutureProvider.family<List<StudentModel>, String>((ref, classId) async {
  ref.watch(authProvider);

  try {
    final allStudents = await ref.watch(allStudentsProvider.future);
    if (allStudents.isNotEmpty) {
      // Filter by classId or return all if classId is 'all'
      final filtered = classId == 'all'
          ? allStudents
          : allStudents.where((s) =>
              s['classId'] == classId ||
              s['sectionId'] == classId ||
              '${s['grade']}-${s['section']}'.toLowerCase() == classId.toLowerCase()
            ).toList();
      final source = filtered.isNotEmpty ? filtered : allStudents;
      return source.map((j) => StudentModel(
        id: j['id'] as String? ?? '',
        firstName: (j['name'] as String? ?? '').split(' ').first,
        lastName: (j['name'] as String? ?? '').split(' ').skip(1).join(' '),
        grade: _gradeDisplay(j['grade']),
        classSection: j['section'] as String? ?? '',
        classId: j['classId'] as String? ?? classId,
        rollNumber: j['rollNumber'] as String? ?? j['studentId'] as String? ?? '',
        photo: null,
        fatherEmail: j['fatherEmail'] as String? ?? '',
        motherEmail: j['motherEmail'] as String? ?? '',
      )).toList();
    }
  } catch (_) {}

  return [];
});

// ── Attendance Provider (reads the shared `TeacherAttendance` marks-map docs) ──
// The single source of truth for attendance is the per-session `TeacherAttendance`
// document the desktop TeacherAttendance.tsx writes:
//   {id:"attendance_Grade 3_B_2026-07-19", grade:"Grade 3", section:"B", date,
//    marks:{<studentId>:"P"|"A"|"L"|"E"|...}, remarks}
// The flat `attendance` table the mobile app read before is an UNRELATED store
// that student/parent portals no longer consume, so a teacher's saved marks were
// invisible to them. Reading (and writing) the marks-map doc keeps all three
// roles in sync. Scoped to the teacher's homeroom grade+section.
final attendanceRecordProvider = FutureProvider.family<List<AttendanceRecord>, String>((ref, classId) async {
  ref.watch(authProvider);
  final home = await ref.watch(teacherHomeroomProvider.future);
  // No real homeroom on file → no attendance to show (no demo Grade 3-B marks).
  if (home.isFallback) return const [];
  final g = canonGrade(home.grade);
  final s = canonSection(home.section);

  // Desktop mark codes → the status strings the attendance screen understands.
  const statusLabel = {
    'P': 'Present', 'A': 'Absent', 'L': 'Late', 'E': 'Leave',
    'H': 'Half day', 'S': 'Sick',
  };

  try {
    final rows = await ApiClient.instance.getAll('TeacherAttendance');
    final out = <AttendanceRecord>[];
    for (final r in rows) {
      if (canonGrade(r['grade']?.toString()) != g) continue;
      if (s.isNotEmpty && canonSection(r['section']?.toString()) != s) continue;
      final marks = r['marks'];
      if (marks is! Map) continue;
      final dateStr = r['date']?.toString() ?? '';
      final date = DateTime.tryParse(
          dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr);
      if (date == null) continue;
      marks.forEach((sid, code) {
        final id = sid.toString();
        if (id.isEmpty) return;
        out.add(AttendanceRecord(
          id: '${r['id'] ?? ''}_$id',
          studentId: id,
          studentName: '',
          date: date,
          status: statusLabel[code.toString().toUpperCase()] ?? 'Present',
        ));
      });
    }
    return out;
  } catch (_) {
    return [];
  }
});

// ── Assignments & Homework ─────────────────────────────────────────────────────
final assignmentsListProvider = FutureProvider<List<AssignmentModel>>((ref) async {
  ref.watch(authProvider);
  try {
    // Desktop teacher pages (TeacherAssignments.tsx, CreateAssignment.tsx)
    // store these under the raw "TeacherAssignment" entity, not `assignments`.
    final raw = await ApiClient.instance.getAll('TeacherAssignment');
    if (raw.isNotEmpty) {
      return raw.map((j) => AssignmentModel(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        subject: j['subject'] as String? ?? '',
        description: j['description'] as String? ?? '',
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate'].toString()) ?? DateTime.now() : DateTime.now(),
        submittedCount: (j['submittedCount'] as num?)?.toInt() ?? 0,
        totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
        classId: j['classId'] as String? ?? '',
        isHomework: j['isHomework'] as bool? ?? false,
      )).toList();
    }

    // Try homework entity
    final hw = await ApiClient.instance.getAll('homework');
    return hw.map((j) => AssignmentModel(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? '',
      subject: j['subject'] as String? ?? '',
      description: j['instructions'] as String? ?? j['description'] as String? ?? '',
      dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate'].toString()) ?? DateTime.now().add(const Duration(days: 7)) : DateTime.now().add(const Duration(days: 7)),
      submittedCount: 0,
      totalCount: 0,
      classId: j['classId'] as String? ?? '',
      isHomework: true,
    )).toList();
  } catch (_) {
    return [];
  }
});

// ── Exam Marks ─────────────────────────────────────────────────────────────────
final examMarksListProvider = FutureProvider.family<List<ExamMarkModel>, String>((ref, classId) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll('results');
    if (raw.isNotEmpty) {
      return raw.map((j) => ExamMarkModel(
        id: j['id']?.toString() ?? '',
        studentId: j['studentId']?.toString() ?? '',
        studentName: j['studentName']?.toString() ?? '',
        subject: j['subject']?.toString() ?? '',
        marks: double.tryParse(j['marks']?.toString() ?? j['score']?.toString() ?? '0') ?? 0,
        maxMarks: double.tryParse(j['maxMarks']?.toString() ?? j['total']?.toString() ?? '100') ?? 100,
        grade: j['grade']?.toString() ?? '',
        examName: j['examName']?.toString() ?? j['exam']?.toString() ?? 'Exam',
      )).toList();
    }
  } catch (_) {}
  return [];
});

// ── Timetable ─────────────────────────────────────────────────────────────────
// Mirrors desktop TeacherTimetable.tsx exactly: reads the single published
// compiled-grid record `timetable_slots/published-timetable-v3` (NOT the raw
// `timetable_entries` table the mobile app used to read, which is a different
// store). The grid has a fixed 5-period Mon–Fri shape with real admin-published
// times; there is no 6th period and no Saturday, and untimed slots are NOT
// invented — if nothing is published the teacher sees an honest empty state.
const _adminTimeSlots = <List<String>>[
  ['08:00', '09:00'],
  ['09:00', '10:00'],
  ['10:00', '11:00'],
  ['11:00', '12:00'],
  ['12:00', '01:00'],
];

// Same teaching days as desktop SCHOOL_DAYS — Monday..Friday only.
const _schoolDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

final teacherTimetableProvider = FutureProvider<List<TimetableSlot>>((ref) async {
  final auth = ref.watch(authProvider);
  final myName = normalizeTeacherName(auth.user?.displayName);
  if (myName.isEmpty) return const [];

  Map<String, dynamic>? doc;
  try {
    doc = await ApiClient.instance.getOne('timetable_slots', 'published-timetable-v3');
  } catch (_) {
    return const [];
  }
  if (doc == null || doc['error'] != null) return const [];

  final slots = <TimetableSlot>[];

  TimetableSlot buildSlot(Map cell, int periodIdx, int dayIdx, String grade, String section, String classKey) {
    final times = periodIdx < _adminTimeSlots.length ? _adminTimeSlots[periodIdx] : ['Period ${periodIdx + 1}', ''];
    final gs = [grade, section].where((s) => s.trim().isNotEmpty).join(' - ');
    return TimetableSlot(
      id: '$classKey-$periodIdx-$dayIdx',
      classId: classKey,
      className: gs.isEmpty ? classKey : gs,
      day: dayIdx + 1, // Monday=1
      startTime: times[0],
      endTime: times[1],
      subject: (cell['subject'] ?? '').toString(),
      room: (cell['room'] ?? '').toString(),
    );
  }

  // Source 1 (preferred): teacherJson — a per-teacher compiled schedule keyed
  // by teacher name. schedule[periodIdx][dayIdx] = cell | null.
  try {
    final rawTeachers = doc['teacherJson'];
    if (rawTeachers is String && rawTeachers.isNotEmpty) {
      final Map<String, dynamic> compiled = jsonDecode(rawTeachers) as Map<String, dynamic>;
      final key = compiled.keys.firstWhere(
        (k) => normalizeTeacherName(k) == myName,
        orElse: () => '',
      );
      if (key.isNotEmpty) {
        final entry = compiled[key] as Map<String, dynamic>;
        final schedule = entry['schedule'];
        final days = (entry['days'] is List) ? (entry['days'] as List).map((e) => e.toString()).toList() : _schoolDays;
        if (schedule is List) {
          for (var pi = 0; pi < schedule.length; pi++) {
            final row = schedule[pi];
            if (row is! List) continue;
            for (var di = 0; di < row.length; di++) {
              final cell = row[di];
              if (cell is! Map) continue;
              final dayName = di < days.length ? days[di] : (di < _schoolDays.length ? _schoolDays[di] : '');
              final realDayIdx = _schoolDays.indexOf(dayName);
              if (realDayIdx < 0) continue; // skips any Saturday/Sunday entries
              slots.add(buildSlot(cell, pi, realDayIdx,
                  (cell['grade'] ?? '').toString(), (cell['section'] ?? '').toString(),
                  (cell['classKey'] ?? '${cell['grade']}-${cell['section']}').toString()));
            }
          }
        }
        if (slots.isNotEmpty) return slots;
      }
    }
  } catch (_) {/* fall through to grid scan */}

  // Source 2 (fallback): gridJson — the full class grid keyed by "Grade-Section";
  // scan every cell and keep the ones taught by this teacher (by name match).
  try {
    final rawGrid = doc['gridJson'];
    if (rawGrid is String && rawGrid.isNotEmpty) {
      final Map<String, dynamic> grids = jsonDecode(rawGrid) as Map<String, dynamic>;
      grids.forEach((classKey, grid) {
        if (grid is! List) return;
        final dash = classKey.lastIndexOf('-');
        final gradeK = dash > 0 ? classKey.substring(0, dash).trim() : classKey;
        final sectionK = dash > 0 ? classKey.substring(dash + 1).trim() : '';
        for (var pi = 0; pi < grid.length; pi++) {
          final row = grid[pi];
          if (row is! List) continue;
          for (var di = 0; di < row.length; di++) {
            final cell = row[di];
            if (cell is! Map) continue;
            if (di >= _schoolDays.length) continue; // Mon–Fri only
            if (normalizeTeacherName((cell['teacher'] ?? '').toString()) == myName) {
              slots.add(buildSlot(cell, pi, di, gradeK, sectionK, classKey));
            }
          }
        }
      });
    }
  } catch (_) {/* return whatever we have */}

  return slots;
});

// ── Messages (shared chat model — same tables the DESKTOP web app uses) ───────
// The desktop `Messages.tsx` stores every conversation in the server-backed
// `chat_threads` / `chat_messages` tables, so BOTH participants read the exact
// same records. The mobile app previously read a disconnected flat `messages`
// table, which is why a teacher saw different / wrong information here than on
// desktop. These providers read the very same shared tables so the mobile
// inbox now shows the teacher's REAL conversations, in sync with the web app.

// A conversation thread, shared by every participant (mirrors ThreadRow).
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

// One message within a thread (mirrors MessageRow).
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

// Does this participant record refer to the signed-in teacher? The server emits
// chat events to BOTH `user:<uid>` and `user:<email>` rooms, so a thread may
// carry the teacher keyed by either — match on both.
bool _isMe(Map participant, String myUid, String myEmail) {
  final uid = (participant['uid'] ?? '').toString();
  final email = (participant['email'] ?? '').toString().toLowerCase();
  return (myUid.isNotEmpty && uid == myUid) ||
      (myEmail.isNotEmpty && email == myEmail);
}

// The teacher's own conversation threads, newest first — read from the shared
// `chat_threads` table and enriched with unread state from `chat_thread_states`.
final teacherChatThreadsProvider = FutureProvider<List<ChatThread>>((ref) async {
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
final chatMessagesProvider =
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

// Count of unread threads — drives the dashboard bell / inbox badge.
final teacherUnreadThreadsProvider = FutureProvider<int>((ref) async {
  final threads = await ref.watch(teacherChatThreadsProvider.future);
  return threads.where((t) => t.unread).length;
});

// ── Chat write helpers (shared thread model) ─────────────────────────────────
// Kept here (not in the widget) so both the inbox composer and the detail view
// post into the exact same shared tables the desktop reads.
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

// A person the teacher is allowed to start a conversation with.
class ChatContact {
  final String uid;
  final String name;
  final String email;
  final String role; // "staff" | "student" | "parent"
  final String subtitle; // e.g. "Grade 3-B" or a job title
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

// People the teacher can message — the mobile equivalent of the desktop
// contact list. The `users` table is admin-only for a teacher token, so we
// build the pool from the already-authorised staff + student providers
// (real backend rows, never seed data). De-duped by uid, excludes myself.
final chatContactsProvider = FutureProvider<List<ChatContact>>((ref) async {
  final me = ref.watch(authProvider).user;
  final myUid = me?.uid ?? '';
  final out = <String, ChatContact>{};

  // Colleagues (staff / teachers).
  try {
    final staff = await ref.watch(staffProvider.future);
    for (final s in staff) {
      final uid = (s['id'] ?? s['uid'] ?? '').toString();
      if (uid.isEmpty || uid == myUid) continue;
      final name = (s['name'] ?? s['displayName'] ?? 'Staff').toString();
      out[uid] = ChatContact(
        uid: uid,
        name: name,
        email: (s['email'] ?? '').toString(),
        role: 'staff',
        subtitle: (s['designation'] ?? s['jobTitle'] ?? s['department'] ?? 'Staff').toString(),
      );
    }
  } catch (_) {}

  // My students (homeroom-scoped).
  try {
    final students = await ref.watch(myStudentsProvider.future);
    for (final s in students) {
      final uid = (s['id'] ?? s['uid'] ?? '').toString();
      if (uid.isEmpty || uid == myUid) continue;
      final name = (s['name'] ?? s['displayName'] ?? 'Student').toString();
      final grade = (s['grade'] ?? s['gradeName'] ?? '').toString();
      final section = (s['section'] ?? '').toString();
      out[uid] = ChatContact(
        uid: uid,
        name: name,
        email: (s['email'] ?? '').toString(),
        role: 'student',
        subtitle: _gradeSectionLabel(grade, section),
      );
    }
  } catch (_) {}

  final list = out.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
});

// Render a "Grade 3-B" label from raw grade/section (single "Grade" prefix —
// per the agreed right format, never "Grade Grade 3").
String _gradeSectionLabel(String grade, String section) {
  var g = grade.trim();
  if (g.isEmpty) return section.trim();
  g = g.replaceFirst(RegExp(r'^grade\s*', caseSensitive: false), '');
  final s = section.trim().replaceFirst(RegExp(r'^section\s*', caseSensitive: false), '');
  return s.isEmpty ? 'Grade $g' : 'Grade $g-$s';
}

// ── Notifications ─────────────────────────────────────────────────────────────
final teacherNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll('notifications');
    if (raw.isNotEmpty) {
      return raw.map((j) => NotificationModel(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['message'] as String? ?? '',
        type: j['type'] as String? ?? 'general',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        read: j['read'] as bool? ?? false,
      )).toList();
    }
  } catch (_) {}
  return [];
});

// ── Study Materials ───────────────────────────────────────────────────────────
// Desktop StudyMaterials.tsx reads the "StudyMaterial" entity, which localDb
// normalizes to the single-word table `studymaterial` (localDb.ts entityMapping)
// — NOT `study_materials`, which is a different (empty) table the mobile app used
// to read. Match the desktop endpoint so mobile shows the same real uploads.
final teacherMaterialsProvider = FutureProvider<List<StudyMaterial>>((ref) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll('studymaterial');
    if (raw.isNotEmpty) {
      return raw.map((j) => StudyMaterial(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        subject: j['subject'] as String? ?? '',
        grade: j['grade'] as String? ?? '',
        type: j['type'] as String? ?? 'PDF',
        uploadedAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      )).toList();
    }
  } catch (_) {}
  return [];
});

// ── Behavior Incidents (real 100 DB records) ──────────────────────────────────
final teacherBehaviorProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    // Desktop TeacherBehavior.tsx stores these under the raw "BehaviorRecord"
    // entity (it is not in localDb's entityMapping), so mobile must match.
    return await ApiClient.instance.getAll('BehaviorRecord');
  } catch (_) {
    return [];
  }
});

// ── Leave Requests (real DB — /api/data/leave_requests) ───────────────────────
final teacherLeaveProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    return await ApiClient.instance.getAll('leave_requests');
  } catch (_) {
    return [];
  }
});

// ── Project Reports ───────────────────────────────────────────────────────────
// Desktop TeacherProjectReports.tsx has no `project_reports` table — it derives
// rows from "TeacherAssignment" (type == "project", homeroom grade/section) ×
// `assignment_submissions`. Mirror that join so both platforms show the same rows.
final teacherProjectReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  final home = await ref.watch(teacherHomeroomProvider.future);
  if (home.isFallback) return const [];
  final g = canonGrade(home.grade);
  final s = canonSection(home.section);
  try {
    final results = await Future.wait([
      ApiClient.instance.getAll('TeacherAssignment'),
      ApiClient.instance.getAll('assignment_submissions'),
    ]);
    final projects = results[0].where((a) {
      if ((a['type']?.toString() ?? '').toLowerCase() != 'project') return false;
      if (canonGrade(a['grade']?.toString()) != g) return false;
      final sec = canonSection(a['section']?.toString());
      return sec.isEmpty || sec == s;
    }).toList();

    final rows = <Map<String, dynamic>>[];
    for (final a in projects) {
      final subs = results[1].where((x) => '${x['assignmentId']}' == '${a['id']}');
      for (final sub in subs) {
        final status = '${sub['status']}';
        final graded = status == 'graded' || status == 'closed';
        final due = DateTime.tryParse('${a['dueDate']}');
        final submittedAt = DateTime.tryParse('${sub['submittedAt']}');
        final late = due != null && submittedAt != null && submittedAt.isAfter(due);
        rows.add({
          'id': sub['id'],
          'assignmentId': a['id'],
          'title': a['title'],
          'studentName': sub['studentName'] ?? '—',
          'subject': a['subject'] ?? '—',
          'submittedDate': sub['submittedAt'] ?? '',
          'dueDate': a['dueDate'],
          'status': graded ? 'Reviewed' : (late ? 'Late' : 'Submitted'),
          'feedback': sub['feedback'],
          'score': sub['marks'],
          'maxScore': a['totalMarks'] ?? 100,
        });
      }
    }
    return rows;
  } catch (_) {
    return [];
  }
});

// ── Flashcards ────────────────────────────────────────────────────────────────
// Desktop FlashCardContext persists decks via "FlashCardSet", which localDb
// maps to the `flashcard_sets` table. Desktop TeacherFlashcards.tsx then shows
// ONLY the decks whose classId belongs to one of the teacher's own sections
// (myClassIds) — never every deck in the school. We mirror that by resolving the
// teacher's scope set to real Class ids and filtering decks by classId.
final teacherFlashcardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    final scopes = await ref.watch(teacherScopeSetProvider.future);
    if (scopes.isEmpty) return const [];
    // Map each of the teacher's (grade, section) scopes to the real Class id.
    final classesRaw = await ApiClient.instance.getAll('classes');
    final myClassIds = <String>{};
    for (final c in classesRaw) {
      final g = canonGrade(c['grade']?.toString());
      final secs = <String>[];
      if (c['sections'] is List) {
        secs.addAll((c['sections'] as List).map((e) => canonSection(e.toString())));
      }
      final singleSec = canonSection(c['section']?.toString());
      if (singleSec.isNotEmpty) secs.add(singleSec);
      final id = (c['id'] ?? '').toString();
      if (id.isEmpty) continue;
      for (final sec in secs) {
        if (scopes.contains(TeacherScope(g, sec))) {
          myClassIds.add(id);
          break;
        }
      }
    }
    if (myClassIds.isEmpty) return const [];

    final decks = await ApiClient.instance.getAll('flashcard_sets');
    return decks.where((d) => myClassIds.contains((d['classId'] ?? '').toString())).toList();
  } catch (_) {
    return [];
  }
});

// ── Library (real 105 books) ──────────────────────────────────────────────────
final teacherLibraryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    return await ApiClient.instance.getAll('library');
  } catch (_) {
    return [];
  }
});

// ── Staff (real 56 staff members) ────────────────────────────────────────────
final staffProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    return await ApiClient.instance.getAll('staff');
  } catch (_) {
    return [];
  }
});

// ── Teacher name normalisation (matches web app normName) ─────────────────────
// Strips Mr./Mrs./Ms./Dr. prefixes and lowercases so the same person written
// "Mr. Abdullah Al-Riami" and "abdullah al-riami" compare equal.
String normalizeTeacherName(String? raw) {
  if (raw == null) return '';
  var s = raw.trim().toLowerCase();
  s = s.replaceFirst(RegExp(r'^(mr|mrs|ms|miss|dr|prof|sir|madam)\.?\s*'), '');
  return s.trim();
}

// ── Grade/Section canonicalisation (mirrors src/lib/studentGradeSection.ts) ───
// "Grade 1", "grade 1", "1" all compare equal; "Section B", "b", "B" all equal.
String canonGrade(String? g) =>
    (g ?? '').trim().toLowerCase().replaceFirst(RegExp(r'^grade\s*'), '').replaceAll(RegExp(r'\s+'), '');

String canonSection(String? s) =>
    (s ?? '').trim().toUpperCase().replaceFirst(RegExp(r'^SECTION\s*'), '').trim();

// A teacher scope is a (grade, section) pair the teacher owns, canonicalised.
class TeacherScope {
  final String grade; // canonical, e.g. "1"
  final String section; // canonical, e.g. "B"
  const TeacherScope(this.grade, this.section);
  @override
  bool operator ==(Object other) => other is TeacherScope && other.grade == grade && other.section == section;
  @override
  int get hashCode => Object.hash(grade, section);
}

// Whether a flat record with grade/section fields belongs to any of the
// teacher's scopes (matches web matchesGradeSection).
bool _flatInScopes(Map<String, dynamic> rec, Set<TeacherScope> scopes) {
  final g = canonGrade(rec['grade']?.toString());
  final s = canonSection(rec['section']?.toString());
  for (final sc in scopes) {
    if (sc.grade == g && (sc.section.isEmpty || sc.section == s)) return true;
  }
  return false;
}

// Whether an exam (with gradePlans[]) touches any of the teacher's scopes
// (mirrors web matchesSection over getGradePlans). Falls back to the exam's
// top-level grade/section when no gradePlans are present.
bool _examInScopes(Map<String, dynamic> exam, Set<TeacherScope> scopes) {
  final plans = exam['gradePlans'];
  final list = (plans is List && plans.isNotEmpty)
      ? plans
      : [
          {'grade': exam['grade'], 'section': exam['section'], 'sections': exam['sections']}
        ];
  for (final p in list) {
    if (p is! Map) continue;
    final g = canonGrade(p['grade']?.toString());
    final rawSecs = p['sections'];
    final secs = (rawSecs is List && rawSecs.isNotEmpty)
        ? rawSecs.map((e) => e.toString()).toList()
        : [p['section']?.toString() ?? ''];
    for (final rawSec in secs) {
      final sec = canonSection(rawSec);
      final isAll = sec.isEmpty || sec.replaceAll(' ', '') == 'ALLSECTIONS';
      for (final sc in scopes) {
        if (sc.grade != g) continue;
        if (isAll || sec == sc.section) return true;
      }
    }
  }
  return false;
}

// ── Subject Assignments (real 371 records) ────────────────────────────────────
// The single source of truth for WHICH grade/section/subject a teacher owns.
// The web app scopes every teacher page through this (see useTeacherScopes).
final subjectAssignmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    return await ApiClient.instance.getAll('subject_assignments');
  } catch (_) {
    return [];
  }
});

// ── The signed-in teacher's own scopes (grade+section+subject they teach) ─────
// Filters subject_assignments by the logged-in teacher's displayName/email.
final myTeacherScopesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final user = auth.user;
  if (user == null) return [];
  final myName = normalizeTeacherName(user.displayName);
  final myEmail = user.email.toLowerCase().trim();
  final all = await ref.watch(subjectAssignmentsProvider.future);
  return all.where((a) {
    final an = normalizeTeacherName(a['teacherName']?.toString());
    final ae = (a['teacherEmail']?.toString() ?? '').toLowerCase().trim();
    return (myName.isNotEmpty && an == myName) || (myEmail.isNotEmpty && ae == myEmail);
  }).toList();
});

// ── The teacher's canonical (grade,section) scope set ─────────────────────────
// Built from their subject_assignments rows (unioned) PLUS their homeroom class,
// exactly like the web useTeacherScopes (which does add(homeroom) then unions
// every subject_assignment). A subject teacher grades in every section they're
// assigned to, AND their own homeroom — every teacher-scoped page filters
// records through this set.
final teacherScopeSetProvider = FutureProvider<Set<TeacherScope>>((ref) async {
  final mine = await ref.watch(myTeacherScopesProvider.future);
  final home = await ref.watch(teacherHomeroomProvider.future);
  final set = mine
      .map((a) => TeacherScope(canonGrade(a['grade']?.toString()), canonSection(a['section']?.toString())))
      .toSet();
  // Union the homeroom class (web adds this first, before the assignments) —
  // but ONLY when it's a real assignment, never the demo Grade 3-B fallback.
  final hg = canonGrade(home.grade);
  final hs = canonSection(home.section);
  if (!home.isFallback && hg.isNotEmpty && hs.isNotEmpty) set.add(TeacherScope(hg, hs));
  return set;
});

// ── Exams (scoped to the teacher's grade/section via gradePlans) ──────────────
// Web parity: TeacherExams.tsx filters allExams by scopes.some(matchesSection).
final teacherExamsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  final scopes = await ref.watch(teacherScopeSetProvider.future);
  try {
    final all = await ApiClient.instance.getAll('exams');
    if (scopes.isEmpty) return const [];
    // Web parity: scopes.some(matchesSection) AND publishedToTeachers !== false.
    return all
        .where((e) =>
            e['publishedToTeachers'] != false && _examInScopes(e, scopes))
        .toList();
  } catch (_) {
    return [];
  }
});

// ── Exam Results (real marks, exactly what the desktop gradebook pulls) ───────
// The teacher marks-entry flow (desktop TeacherExams.tsx → persistExamMarks)
// writes to the `exam_marks` table (localDb "ExamMark"), NOT a flat
// `exam_results` table. Each row is a per-exam blob:
//     { id: <examId>, <subject>: { <studentId>: <mark> }, uid, createdAt, ... }
// The exam's display name + max marks live on the `exams` row. The mobile
// gradebook/results screens previously read `exam_results` (a table the teacher
// flow never populates), so they showed empty/stale data that didn't match the
// web. Here we join exam_marks ⋈ exams ⋈ students and flatten to one row per
// (exam, subject, student), scoped to the teacher — identical to what the
// desktop gradebook auto-pulls.
const _examMarkMetaKeys = {'id', 'uid', 'createdby', 'createdat', 'updatedat', 'updatedby'};

final teacherExamResultsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  final scopes = await ref.watch(teacherScopeSetProvider.future);
  if (scopes.isEmpty) return const [];
  try {
    final fetched = await Future.wait([
      ApiClient.instance.getAll('exam_marks'),
      ApiClient.instance.getAll('exams'),
      ref.watch(allStudentsProvider.future),
    ]);
    final markRows = fetched[0];
    final exams = fetched[1];
    final students = fetched[2];

    // examId → { name, maxMarks }.
    final examMeta = <String, Map<String, dynamic>>{};
    for (final e in exams) {
      final id = (e['id'] ?? '').toString();
      if (id.isEmpty) continue;
      examMeta[id] = {
        'name': (e['name'] ?? e['examName'] ?? e['title'] ?? 'Exam').toString(),
        'maxMarks': (e['maxMarks'] as num?)?.toDouble() ??
            double.tryParse('${e['maxMarks'] ?? ''}') ?? 100.0,
        'passingMarks': (e['passingMarks'] as num?)?.toDouble() ??
            double.tryParse('${e['passingMarks'] ?? ''}') ?? 40.0,
      };
    }

    // studentId → { name, grade, section }.
    final studentMeta = <String, Map<String, dynamic>>{};
    for (final s in students) {
      final id = (s['id'] ?? s['uid'] ?? '').toString();
      if (id.isEmpty) continue;
      studentMeta[id] = {
        'name': (s['name'] ?? s['displayName'] ?? 'Student').toString(),
        'grade': (s['grade'] ?? s['gradeName'] ?? '').toString(),
        'section': (s['section'] ?? '').toString(),
      };
    }

    final rows = <Map<String, dynamic>>[];
    for (final mr in markRows) {
      final examId = (mr['id'] ?? '').toString();
      final meta = examMeta[examId];
      final examName = (meta?['name'] ?? 'Exam').toString();
      final maxMarks = (meta?['maxMarks'] as double?) ?? 100.0;
      final passingMarks = (meta?['passingMarks'] as double?) ?? 40.0;

      // Every non-meta key on the blob is a subject → { studentId: mark } map.
      mr.forEach((subject, byStudent) {
        if (_examMarkMetaKeys.contains(subject.toLowerCase())) return;
        if (byStudent is! Map) return;
        byStudent.forEach((sid, mark) {
          final studentId = sid.toString();
          final sm = studentMeta[studentId];
          final grade = (sm?['grade'] ?? '').toString();
          final section = (sm?['section'] ?? '').toString();
          // Only this teacher's grade/section scope (web parity).
          if (!_flatInScopes({'grade': grade, 'section': section}, scopes)) return;
          final obtained = (mark is num)
              ? mark.toDouble()
              : double.tryParse(mark.toString());
          if (obtained == null) return; // ungraded cell — skip, never fabricate
          rows.add({
            'studentId': studentId,
            'studentName': (sm?['name'] ?? 'Student').toString(),
            'grade': grade,
            'section': section,
            'examName': examName,
            'subject': subject.toString(),
            'marksObtained': obtained,
            'totalMarks': maxMarks,
            'status': obtained >= passingMarks ? 'pass' : 'fail',
          });
        });
      });
    }
    return rows;
  } catch (_) {
    return [];
  }
});

// ── Teacher homeroom (mirrors web useTeacherClass exactly) ────────────────────
// The web dashboard "Students" stat and the Students page both scope to the
// teacher's SINGLE homeroom section — NOT the union of every subject they
// teach. The homeroom comes from the teacher's own User record
// (assignedGrade/assignedSection, else a parseable classSection like
// "Grade 1-A"); when the record has none of those it falls all the way through
// to DEFAULT_CLASS (Grade 3-B) — the same demo roster the web shows. Keeping
// this identical is what makes the mobile student count match the web so the
// user isn't confused.
class TeacherHomeroom {
  final String grade; // display form, e.g. "Grade 3"
  final String section; // e.g. "B"
  // True when this account has NO real homeroom assignment on file and we've
  // fallen through to the demo Grade 3-B values. Mirrors the web
  // useTeacherClass `isDefaultFallback`: homeroom-scoped screens must show an
  // honest "not assigned" empty state instead of presenting the demo roster
  // (and its attendance / homework / stats) as if it were the teacher's real
  // data. Only ever true when a user record WAS fetched but carried no
  // homeroom fields — never on loading / fetch-failure (rec == null).
  final bool isFallback;
  const TeacherHomeroom(this.grade, this.section, {this.isFallback = false});
}

const _defaultHomeroom = TeacherHomeroom('Grade 3', 'B');
// Same values, but explicitly flagged as the unassigned fallback so callers
// can distinguish "real Grade 3-B teacher" from "no class assigned".
const _fallbackHomeroom = TeacherHomeroom('Grade 3', 'B', isFallback: true);

// Parse "Grade 1-A" / "Grade 1 A" → (grade:"Grade 1", section:"A").
TeacherHomeroom? _parseClassSection(String? cs) {
  final m = RegExp(r'^(.+?)[\s-]+([A-Za-z])$').firstMatch((cs ?? '').trim());
  if (m == null) return null;
  return TeacherHomeroom(m.group(1)!.trim(), m.group(2)!.toUpperCase());
}

final teacherHomeroomProvider = FutureProvider<TeacherHomeroom>((ref) async {
  final auth = ref.watch(authProvider);
  final email = auth.user?.email;
  if (email == null || email.isEmpty) return _defaultHomeroom;
  Map<String, dynamic>? rec;
  try {
    rec = await ApiClient.instance.getOne('users', email);
  } catch (_) {
    rec = null;
  }
  if (rec == null) return _defaultHomeroom;
  final ag = rec['assignedGrade']?.toString();
  final asec = rec['assignedSection']?.toString();
  if (ag != null && ag.isNotEmpty && asec != null && asec.isNotEmpty) {
    return TeacherHomeroom(ag, asec.toUpperCase());
  }
  final parsed = _parseClassSection(rec['classSection']?.toString());
  if (parsed != null) return parsed;
  // A record WAS fetched but carries no homeroom fields → this account has no
  // real class assignment. Flag it so homeroom-scoped screens show an honest
  // "No class assigned" state instead of the demo Grade 3-B roster (web parity
  // with useTeacherClass.isDefaultFallback).
  return _fallbackHomeroom;
});

// ── My Students (single homeroom section — mirrors web useTeacherClass) ───────
// Filters the full roster to just the teacher's homeroom (grade,section), so
// the count matches the web dashboard/Students page exactly.
final myStudentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  final home = await ref.watch(teacherHomeroomProvider.future);
  // No real homeroom on file → show nothing, never the demo Grade 3-B roster.
  if (home.isFallback) return const [];
  final scope = {TeacherScope(canonGrade(home.grade), canonSection(home.section))};
  try {
    final all = await ref.watch(allStudentsProvider.future);
    return all.where((s) => _flatInScopes(s, scope)).toList();
  } catch (_) {
    return [];
  }
});

// ── My Classes (union of subject_assignments grade-section — web myClassesCount)
// The web dashboard "My Classes N" counts DISTINCT grade-section pairs from the
// teacher's subject_assignments. Each entry is one class card the teacher owns.
final myClassesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  final mine = await ref.watch(myTeacherScopesProvider.future);
  // Collapse to distinct grade+section, keeping the subjects taught in each.
  final byKey = <String, Map<String, dynamic>>{};
  for (final a in mine) {
    final grade = (a['grade'] ?? '').toString();
    final section = (a['section'] ?? '').toString();
    final key = '${canonGrade(grade)}-${canonSection(section)}';
    final subj = (a['subject'] ?? '').toString();
    if (byKey.containsKey(key)) {
      final subs = byKey[key]!['subjects'] as List<String>;
      if (subj.isNotEmpty && !subs.contains(subj)) subs.add(subj);
    } else {
      byKey[key] = {
        'grade': grade,
        'section': section,
        'subjects': <String>[if (subj.isNotEmpty) subj],
      };
    }
  }

  // Always include the teacher's homeroom class so assignment/assessment/etc.
  // dropdowns show the assigned class even when subject_assignments don't match
  // (or don't exist). Mirrors the web myCombos, which seeds with the homeroom.
  // Skip the demo Grade 3-B fallback — an unassigned teacher gets no class card.
  final home = await ref.watch(teacherHomeroomProvider.future);
  final hg = canonGrade(home.grade);
  final hs = canonSection(home.section);
  if (!home.isFallback && hg.isNotEmpty && hs.isNotEmpty) {
    final key = '$hg-$hs';
    if (!byKey.containsKey(key)) {
      byKey[key] = {
        'grade': home.grade,
        'section': home.section,
        'subjects': <String>[],
      };
    }
  }

  return byKey.values.toList();
});

// ── Homework (scoped to homeroom grade+section — mirrors web Homework.tsx) ─────
// Web filters homework to the teacher's homeroom grade+section. The `homework`
// entity carries flat grade/section fields.
final teacherHomeworkProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  final home = await ref.watch(teacherHomeroomProvider.future);
  if (home.isFallback) return const [];
  final g = canonGrade(home.grade);
  final s = canonSection(home.section);
  try {
    // Strictly the `homework` table (desktop watch("Homework")) — no fallback
    // to a different entity, which would show rows desktop never shows.
    final raw = await ApiClient.instance.getAll('homework');
    return raw.where((h) =>
        canonGrade(h['grade']?.toString()) == g &&
        canonSection(h['section']?.toString()) == s).toList();
  } catch (_) {
    return [];
  }
});

// ── Behavior (scoped to the teacher's homeroom students — web TeacherBehavior) ─
final teacherBehaviorScopedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    final students = await ref.watch(myStudentsProvider.future);
    final ids = students.map((s) => s['id']?.toString()).whereType<String>().toSet();
    final names = students
        .map((s) => (s['name'] ?? '').toString().trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet();
    if (ids.isEmpty && names.isEmpty) return const [];
    final all = await ApiClient.instance.getAll('BehaviorRecord');
    return all.where((b) {
      final sid = b['studentId']?.toString();
      if (sid != null && ids.contains(sid)) return true;
      final sname = (b['studentName'] ?? '').toString().trim().toLowerCase();
      return sname.isNotEmpty && names.contains(sname);
    }).toList();
  } catch (_) {
    return [];
  }
});

// ── Assignments (scoped to homeroom grade+section — web TeacherAssignments) ────
// Reads the same raw "TeacherAssignment" entity as desktop TeacherAssignments.tsx.
final teacherAssignmentsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  final home = await ref.watch(teacherHomeroomProvider.future);
  if (home.isFallback) return const [];
  final g = canonGrade(home.grade);
  final s = canonSection(home.section);
  try {
    final raw = await ApiClient.instance.getAll('TeacherAssignment');
    return raw.where((a) =>
        canonGrade(a['grade']?.toString()) == g &&
        canonSection(a['section']?.toString()) == s).toList();
  } catch (_) {
    return [];
  }
});

// ── Submissions to review (real join, like desktop) ──────────────────────────
// Real student submissions live in the separate `assignment_submissions` table
// (a "TeacherAssignment" is created with an empty embedded submissions array).
// Desktop joins that table against the teacher's assignments — mirror it here so
// the Submissions Review tab shows real rows instead of always-empty embedded
// arrays. Each returned row carries the parent title + its own submission id so
// a grade can be persisted straight back onto the correct submission record.
final teacherSubmissionsReviewProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final assignments = await ref.watch(teacherAssignmentsListProvider.future);
  if (assignments.isEmpty) return const [];
  final byId = {for (final a in assignments) '${a['id'] ?? a['_id']}': a};
  List<Map<String, dynamic>> subs;
  try {
    subs = await ApiClient.instance.getAll('assignment_submissions');
  } catch (_) {
    return const [];
  }
  final rows = <Map<String, dynamic>>[];
  for (final sub in subs) {
    final a = byId['${sub['assignmentId']}'];
    if (a == null) continue; // submission for another class's assignment
    rows.add({
      'id': sub['id'],
      'assignmentId': sub['assignmentId'],
      'assignmentTitle': a['title'] ?? '',
      'studentName': sub['studentName'] ?? sub['student'] ?? '',
      'submittedAt': sub['submittedAt'] ?? '',
      'status': sub['status'] ?? '',
      'score': sub['marks'] ?? sub['score'],
      'feedback': sub['feedback'] ?? '',
      'file': sub['fileUrl'] ?? sub['file'] ?? sub['attachmentUrl'] ?? '',
      'maxScore': a['totalMarks'] ?? 100,
    });
  }
  return rows;
});

// ── Assessments (scoped by teacher name — web Assessments.tsx list filter) ────
final teacherAssessmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final myName = normalizeTeacherName(auth.user?.displayName);
  try {
    final all = await ApiClient.instance.getAll('assessments');
    if (myName.isEmpty) return const [];
    return all.where((a) {
      final t = normalizeTeacherName(a['teacher']?.toString());
      if (t.isEmpty) return false; // no teacher assigned → not this teacher's
      return t == myName || t.contains(myName) || myName.contains(t);
    }).toList();
  } catch (_) {
    return [];
  }
});

// ── LMS Courses (scoped by teacher name) ──────────────────────────────────────
final teacherLmsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final myName = normalizeTeacherName(auth.user?.displayName);
  try {
    final all = await ApiClient.instance.getAll('lms_courses');
    if (myName.isEmpty) return const [];
    return all.where((c) {
      final t = normalizeTeacherName(c['teacher']?.toString());
      if (t.isEmpty) return false;
      return t == myName || t.contains(myName) || myName.contains(t);
    }).toList();
  } catch (_) {
    return [];
  }
});

// ── PTM / Parent Meetings (real DB — may be empty) ────────────────────────────
// Desktop TeacherPTM.tsx reads the raw "PTMSession" entity (not in localDb's
// mapping, so sent verbatim) — NOT the `ptm_meetings` table the mobile app used
// to read. It then keeps only sessions that belong to this teacher: booked for
// one of the teacher's own students (by id or name) OR addressed to the teacher
// by name. We mirror that scoping so a teacher never sees other teachers' PTMs.
final teacherPtmProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final myName = normalizeTeacherName(auth.user?.displayName);
  List<Map<String, dynamic>> rows;
  try {
    rows = await ApiClient.instance.getAll('PTMSession');
  } catch (_) {
    return [];
  }
  if (rows.isEmpty) return [];

  final students = await ref.watch(myStudentsProvider.future);
  final studentIds = students.map((s) => (s['id'] ?? s['uid'] ?? '').toString()).where((s) => s.isNotEmpty).toSet();
  final studentNames = students.map((s) => (s['name'] ?? s['displayName'] ?? '').toString().toLowerCase()).where((s) => s.isNotEmpty).toSet();

  return rows.where((s) {
    final sid = (s['studentId'] ?? '').toString();
    if (sid.isNotEmpty && studentIds.contains(sid)) return true;
    final sName = (s['student'] ?? s['studentName'] ?? '').toString().toLowerCase();
    if (sName.isNotEmpty && studentNames.contains(sName)) return true;
    final t = normalizeTeacherName((s['teacher'] ?? '').toString());
    if (myName.isNotEmpty && t == myName) return true;
    return false;
  }).toList();
});

// ── Calendar Events (real DB — may be empty) ──────────────────────────────────
// Desktop useTeacherCalendarEvents reads the raw "CalendarEvent" entity (not in
// localDb's mapping → verbatim) — NOT the `calendar_events` table the mobile app
// used to read — then applies the shared announcement-audience filter. For a
// teacher (staff group) that means: only Published events whose audience is
// "All" or "Staff" (plus per-family recipientStudentId events, which staff may
// always see). This hides admin drafts and student/parent-only events.
final teacherCalendarProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  List<Map<String, dynamic>> rows;
  try {
    rows = await ApiClient.instance.getAll('CalendarEvent');
  } catch (_) {
    return [];
  }
  return rows.where((e) {
    final status = (e['status'] ?? '').toString();
    if (status.isNotEmpty && status != 'Published') return false;
    // Per-family events are visible to staff regardless of audience.
    if ((e['recipientStudentId'] ?? '').toString().isNotEmpty) return true;
    final audience = (e['targetAudience'] ?? 'All').toString();
    return audience == 'All' || audience == 'Staff';
  }).toList();
});

// ═════════════════════════════════════════════════════════════════════════════
// WEIGHTED GRADEBOOK — active curriculum + raw sources + class compute.
// Mirrors desktop useCurriculum + loadGradebookSources + computeClassGradebook.
// The engine (gradebook_engine.dart) needs every raw mark UNFILTERED, then
// filters per-student itself, so these providers deliberately do NOT reuse the
// homeroom-scoped assignment/assessment providers above.
// ═════════════════════════════════════════════════════════════════════════════

// The school's active curriculum, from school_config/active_curriculum.
// Desktop useCurriculum: smartDb.getOne('school_config','active_curriculum')
//   .curriculumId ?? 'qatar'. A missing row / fetch error → the default.
final activeCurriculumProvider = FutureProvider<CurriculumConfig>((ref) async {
  ref.watch(authProvider);
  try {
    final rec = await ApiClient.instance.getOne('school_config', 'active_curriculum');
    final id = rec?['curriculumId']?.toString();
    return getCurriculum(id); // getCurriculum falls back to 'qatar' on null/unknown
  } catch (_) {
    return getCurriculum(defaultCurriculumId);
  }
});

// All raw gradebook source tables, loaded once and computed many times.
// Mirrors desktop loadGradebookSources (Promise.all over the six stores).
final gradebookSourcesProvider = FutureProvider<GradebookSources>((ref) async {
  ref.watch(authProvider);
  final api = ApiClient.instance;
  // getAll swallows errors → []; a partially-available backend still computes
  // whatever real marks it can, and renders honest gaps for the rest.
  final results = await Future.wait([
    api.getAll('TeacherAssignment'),
    api.getAll('assignment_submissions'),
    api.getAll('assessments'),
    api.getAll('assessment_attempts'),
    api.getAll('exams'),
    api.getAll('exam_marks'),
    api.getAll('MarkOverride'),
  ]);
  return GradebookSources(
    assignments: results[0],
    submissions: results[1],
    assessments: results[2],
    attempts: results[3],
    exams: results[4],
    examMarks: buildExamMarks(results[5]),
    overrides: results[6].map(MarkOverride.fromJson).toList(),
  );
});

// The (grade, section, term) a gradebook view is computed for.
class GradebookQuery {
  final String grade; // display or raw — canonicalised internally
  final String section;
  final String? term; // null → all terms (overrides match any term)
  final String? subject; // null → all subjects (class overview); set → one subject
  const GradebookQuery(this.grade, this.section, {this.term, this.subject});

  @override
  bool operator ==(Object other) =>
      other is GradebookQuery &&
      canonGrade(other.grade) == canonGrade(grade) &&
      canonSection(other.section) == canonSection(section) &&
      other.term == term &&
      other.subject == subject;

  @override
  int get hashCode => Object.hash(canonGrade(grade), canonSection(section), term, subject);
}

/// A whole class's weighted gradebook, ranked — the desktop TeacherGradebook view.
/// Pulls the roster for (grade, section), the active curriculum band for the
/// grade, and every raw mark, then runs computeClassGradebook. Empty roster →
/// empty list (honest empty state, never fabricated rows).
final classGradebookProvider =
    FutureProvider.family<List<StudentGradebook>, GradebookQuery>((ref, query) async {
  final curriculum = await ref.watch(activeCurriculumProvider.future);
  final src = await ref.watch(gradebookSourcesProvider.future);
  final allStudents = await ref.watch(allStudentsProvider.future);

  final g = canonGrade(query.grade);
  final s = canonSection(query.section);
  final roster = allStudents.where((st) =>
      canonGrade(st['grade']?.toString()) == g &&
      canonSection(st['section']?.toString()) == s).toList();
  if (roster.isEmpty) return const [];

  // Resolve the grade's band using the roster's own grade string so a value
  // like "Grade 3" or "3" both land on the right band.
  final band = getBandForGrade(curriculum, roster.first['grade']?.toString() ?? query.grade);

  final students = [
    for (final st in roster)
      GradebookStudent(
        id: (st['id'] ?? st['uid'] ?? '').toString(),
        name: (st['name'] ?? st['displayName'] ?? '').toString(),
        grade: (st['grade'] ?? query.grade).toString(),
        section: (st['section'] ?? query.section).toString(),
      )
  ];

  // A subject filter narrows the computed gradebook to that one subject so the
  // overall %/rank reflect just it; null keeps the full multi-subject overview.
  final subjectList = (query.subject != null && query.subject!.isNotEmpty) ? [query.subject!] : null;
  return computeClassGradebook(students, band, src, subjectList: subjectList, term: query.term);
});

// The approval-workflow record for one (grade, section, subject, term), or null
// if the Subject Teacher hasn't submitted it yet. Mirrors desktop findSubmission.
final gradebookSubmissionProvider =
    FutureProvider.family<GradebookSubmission?, GradebookQuery>((ref, query) async {
  ref.watch(authProvider);
  // A submission is per-subject per-term; a query missing either yields none.
  final term = query.term;
  final subject = query.subject;
  if (term == null || term.isEmpty || subject == null || subject.isEmpty) return null;
  return GradebookApprovalService.instance
      .findSubmission(query.grade, query.section, subject, term);
});



