import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/offline_cache.dart';
import '../core/socket_service.dart';
import '../models/models.dart';
import 'auth_provider.dart';

// ── Selection State ─────────────────────────────────────────────────────────
final selectedClassProvider = StateProvider<ClassModel?>((ref) => null);
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// ── Generic API Fetcher ────────────────────────────────────────────────────────
final _memCache = <String, List<Map<String, dynamic>>>{};

String _cacheKey(String entity, Map<String, dynamic>? params) =>
    params == null ? entity : '$entity?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';

Future<List<Map<String, dynamic>>> _fetch(
  String entity, {
  Map<String, dynamic>? params,
}) async {
  final key = _cacheKey(entity, params);
  if (_memCache.containsKey(key)) return _memCache[key]!;
  final cached = OfflineCache.get(key);
  if (cached != null) { _memCache[key] = cached; return cached; }
  try {
    final data = await ApiClient.instance.getAll(entity, params: params);
    _memCache[key] = data;
    await OfflineCache.put(key, data);
    return data;
  } catch (e) {
    final stale = OfflineCache.getStale(key);
    if (stale != null) return stale;
    return [];
  }
}

void clearCache() {
  _memCache.clear();
  OfflineCache.clear();
}

// ── All Students (from real DB — 110 Omani students) ─────────────────────────
final allStudentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll(AppConstants.students);
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
    final raw = await ApiClient.instance.getAll(AppConstants.classes);
    if (raw.isNotEmpty) {
      return raw.map((j) => ClassModel(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        grade: 'Grade ${j['grade'] ?? ''}',
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
    final sections = await ApiClient.instance.getAll('Section');
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

  return [
    const ClassModel(id: 'c1', name: 'Grade 5 - A', grade: 'Grade 5', section: 'A', studentCount: 20, subject: 'Mathematics'),
    const ClassModel(id: 'c2', name: 'Grade 5 - B', grade: 'Grade 5', section: 'B', studentCount: 18, subject: 'Mathematics'),
  ];
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
        grade: 'Grade ${j['grade'] ?? ''}',
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

// ── Attendance Provider (real 744 DB records) ─────────────────────────────────
final attendanceRecordProvider = FutureProvider.family<List<AttendanceRecord>, String>((ref, classId) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll(AppConstants.attendance);
    return raw.map((j) => AttendanceRecord(
      id: j['id']?.toString() ?? '',
      studentId: j['entityId']?.toString() ?? j['studentId']?.toString() ?? '',
      studentName: j['name']?.toString() ?? j['studentName']?.toString() ?? '',
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      status: j['status']?.toString() ?? 'Present',
    )).toList();
  } catch (_) {
    return [];
  }
});

// ── Assignments & Homework ─────────────────────────────────────────────────────
final assignmentsListProvider = FutureProvider<List<AssignmentModel>>((ref) async {
  ref.watch(authProvider);
  try {
    final List<AssignmentModel> list = [];
    
    // Fetch assignments
    try {
      final raw = await ApiClient.instance.getAll(AppConstants.assignments);
      if (raw.isNotEmpty) {
        list.addAll(raw.map((j) => AssignmentModel(
          id: j['id'] as String? ?? '',
          title: j['title'] as String? ?? '',
          subject: j['subject'] as String? ?? '',
          description: j['description'] as String? ?? '',
          dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate'].toString()) ?? DateTime.now() : DateTime.now(),
          submittedCount: (j['submittedCount'] as num?)?.toInt() ?? 0,
          totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
          classId: j['classId'] as String? ?? '',
          isHomework: j['isHomework'] == true || j['is_homework'] == 1 || j['is_homework'] == true,
        )));
      }
    } catch (_) {}

    // Fetch homework
    try {
      final hw = await ApiClient.instance.getAll(AppConstants.homework);
      if (hw.isNotEmpty) {
        list.addAll(hw.map((j) => AssignmentModel(
          id: j['id'] as String? ?? '',
          title: j['title'] as String? ?? '',
          subject: j['subject'] as String? ?? '',
          description: j['instructions'] as String? ?? j['description'] as String? ?? '',
          dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate'].toString()) ?? DateTime.now().add(const Duration(days: 7)) : DateTime.now().add(const Duration(days: 7)),
          submittedCount: 0,
          totalCount: 0,
          classId: j['classId'] as String? ?? '',
          isHomework: true,
        )));
      }
    } catch (_) {}

    return list;
  } catch (_) {
    return [];
  }
});

// ── Exam Marks ─────────────────────────────────────────────────────────────────
final examMarksListProvider = FutureProvider.family<List<ExamMarkModel>, String>((ref, classId) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll(AppConstants.examMarks);
    if (raw.isNotEmpty) {
      return raw.map((j) => ExamMarkModel(
        id: j['id']?.toString() ?? '',
        studentId: j['studentId']?.toString() ?? '',
        studentName: j['studentName']?.toString() ?? '',
        subject: j['subject']?.toString() ?? '',
        marks: double.tryParse(j['marks']?.toString() ?? j['score']?.toString() ?? '0') ?? 0,
        maxMarks: double.tryParse(j['maxMarks']?.toString() ?? j['total']?.toString() ?? '100') ?? 100,
        grade: j['grade']?.toString() ?? j['letterGrade']?.toString(),
        examName: j['examName']?.toString() ?? j['exam']?.toString() ?? 'Exam',
      )).toList();
    }
  } catch (_) {}
  return [];
});

// ── Timetable ─────────────────────────────────────────────────────────────────
final teacherTimetableProvider = FutureProvider<List<TimetableSlot>>((ref) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll(AppConstants.timetableSlots);
    if (raw.isNotEmpty) {
      return raw.map((j) {
        final grade = j['grade']?.toString() ?? j['class']?.toString() ?? '';
        final section = j['section']?.toString() ?? j['sectionId']?.toString() ?? '';
        final resolvedName = grade.isNotEmpty
            ? (section.isNotEmpty ? '$grade - $section' : grade)
            : j['className']?.toString() ?? '${j['classId'] ?? ''} - ${j['sectionId'] ?? ''}';
        return TimetableSlot(
          id: j['id'] as String? ?? '',
          classId: j['classId'] as String? ?? '',
          className: resolvedName,
          day: _dayIndex(j['day'] as String? ?? 'Monday'),
          startTime: j['startTime'] as String? ?? '08:00 AM',
          endTime: j['endTime'] as String? ?? '08:45 AM',
          subject: j['subject'] as String? ?? j['subjectId'] as String? ?? '',
          room: j['room'] as String? ?? j['roomId'] as String? ?? '',
        );
      }).toList();
    }
  } catch (_) {}
  return [
    const TimetableSlot(id: 't1', classId: 'c1', className: 'Grade 5 - A', day: 1, startTime: '08:00 AM', endTime: '08:45 AM', subject: 'Mathematics', room: 'Room 101'),
    const TimetableSlot(id: 't2', classId: 'c1', className: 'Grade 5 - A', day: 2, startTime: '09:00 AM', endTime: '09:45 AM', subject: 'Mathematics', room: 'Room 101'),
    const TimetableSlot(id: 't3', classId: 'c1', className: 'Grade 5 - A', day: 3, startTime: '08:00 AM', endTime: '08:45 AM', subject: 'Mathematics', room: 'Room 101'),
  ];
});

int _dayIndex(String day) {
  const map = {'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6, 'Sunday': 7};
  return map[day] ?? 1;
}


// ── Notifications ─────────────────────────────────────────────────────────────
final teacherNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll(AppConstants.notifications);
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
final teacherMaterialsProvider = FutureProvider<List<StudyMaterial>>((ref) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll(AppConstants.studyMaterials);
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
    return await ApiClient.instance.getAll(AppConstants.behaviorIncidents);
  } catch (_) {
    return [];
  }
});

// ── Library (real 105 books) ──────────────────────────────────────────────────
final teacherLibraryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    return await ApiClient.instance.getAll(AppConstants.library);
  } catch (_) {
    return [];
  }
});

// ── Staff (real 56 staff members) ────────────────────────────────────────────
final staffProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    return await ApiClient.instance.getAll(AppConstants.staff);
  } catch (_) {
    return [];
  }
});

// ── PTM Sessions ──────────────────────────────────────────────────────────────
final ptmSessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    return await ApiClient.instance.getAll('PTMSession');
  } catch (_) {
    return [];
  }
});

// ── Exams ─────────────────────────────────────────────────────────────────────
final examsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);
  try {
    return await ApiClient.instance.getAll(AppConstants.exams);
  } catch (_) {
    return [];
  }
});

// ════════════════════════════════════════════════════════════════════════════════
// REAL-TIME CHAT PROVIDERS (Socket.IO)
// ════════════════════════════════════════════════════════════════════════════════

// Stream provider for real-time messages
final chatMessagesStreamProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, threadId) {
  final socketService = SocketService.instance;
  final controller = StreamController<Map<String, dynamic>>.broadcast();
  
  // Listen to real-time messages
  final subscription = socketService.onNewMessage.listen((data) {
    if (data['threadId'] == threadId || data['event'] == 'read_receipt') {
      controller.add(data);
    }
  });
  
  // Initialize socket if not connected
  socketService.init();
  
  // Join the thread room
  socketService.joinThread(threadId);
  
  ref.onDispose(() {
    subscription.cancel();
    socketService.leaveThread(threadId);
    controller.close();
  });
  
  return controller.stream;
});

// Real-time thread updates (new thread, thread updated)
final chatThreadsStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = SocketService.instance;
  final controller = StreamController<Map<String, dynamic>>.broadcast();
  
  final subscription = socketService.onThreadUpdate.listen((data) {
    controller.add(data);
  });
  
  socketService.init();
  
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });
  
  return controller.stream;
});

// Real-time notifications
final chatNotificationsStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = SocketService.instance;
  final controller = StreamController<Map<String, dynamic>>.broadcast();
  
  final subscription = socketService.onNotification.listen((data) {
    controller.add(data);
  });
  
  socketService.init();
  
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });
  
  return controller.stream;
});

// Combined provider: Future + Stream for chat messages (optimistic updates)
final chatMessagesProvider = FutureProvider.family<List<ChatMessageModel>, String>((ref, threadId) async {
  ref.watch(authProvider);
  try {
    final raw = await ApiClient.instance.getAll(AppConstants.messages);
    final messages = raw.map((j) => ChatMessageModel.fromJson(j)).toList();
    // Filter messages for this thread
    final filtered = messages.where((m) => m.threadId == threadId).toList();
    // Sort chronological
    filtered.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return -1;
      if (b.createdAt == null) return 1;
      return a.createdAt!.compareTo(b.createdAt!);
    });
    return filtered;
  } catch (e) {
    debugPrint('[DataProvider] Error fetching chat messages: $e');
    return [];
  }
});

// Provider for chat threads with real-time updates
final chatThreadsProvider = FutureProvider<List<ChatThreadModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];
  final myUid = auth.user?.uid;
  if (myUid == null || myUid.isEmpty) return [];

  try {
    final raw = await ApiClient.instance.getAll(AppConstants.chatThreads);
    final threads = raw.map((j) => ChatThreadModel.fromJson(j)).toList();
    // Filter threads where current user is a participant
    return threads.where((t) => t.participants.any((p) => p.uid == myUid)).toList();
  } catch (e) {
    debugPrint('[DataProvider] Error fetching chat threads: $e');
    return [];
  }
});

// Real-time thread list that merges future + stream
final chatThreadsRealtimeProvider = FutureProvider<List<ChatThreadModel>>((ref) async {
  // Start with initial data
  final initial = await ref.watch(chatThreadsProvider.future);
  
  // Listen for real-time updates
  ref.listen<AsyncValue<Map<String, dynamic>>>(chatThreadsStreamProvider, (prev, next) {
    if (next.hasValue) {
      // Invalidate to trigger refetch
      ref.invalidate(chatThreadsProvider);
    }
  });
  
  return initial;
});
