// ─────────────────────────────────────────────────────────────────────────────
// Gradebook approval workflow + manual mark overrides — a Dart port of the
// desktop `src/lib/gradebookApproval.ts` (and the pushNotify helper from
// `src/lib/pushNotifications.ts`).
//
// A computed term gradebook is not final until it clears the approval chain:
//
//   Subject Teacher → Class Teacher → Grade Coordinator → Principal
//
// Each hop persists a `GradebookSubmission` record, appends to its history, and
// pushes a real notification to the next approver (and, on final approval, back
// to everyone who signed off). A Class Teacher may return the book to the
// Subject Teacher with a reason. Alongside the chain, a reviewer may enter a
// `MarkOverride` — a human correction that the compute engine always honours
// over the auto-pulled mark.
//
// All reads/writes go through the same `/api/data/<entity>` backend the desktop
// uses, so a submission raised on mobile is visible on the web and vice-versa.
// ─────────────────────────────────────────────────────────────────────────────
import 'api_client.dart';
import 'gradebook_engine.dart';

// Ordered stages of the approval chain. The string values match the desktop
// SubmissionStatus union EXACTLY — they are the shared contract in the DB.
enum SubmissionStatus {
  draft('Draft'),
  submittedToClassTeacher('Submitted to Class Teacher'),
  returnedToSubjectTeacher('Returned to Subject Teacher'),
  submittedToGradeCoordinator('Submitted to Grade Coordinator'),
  submittedToPrincipal('Submitted to Principal'),
  approvedByPrincipal('Approved by Principal');

  final String label;
  const SubmissionStatus(this.label);

  static SubmissionStatus fromLabel(String? s) {
    for (final v in SubmissionStatus.values) {
      if (v.label == s) return v;
    }
    return SubmissionStatus.draft;
  }
}

/// One entry in a submission's audit trail.
class SubmissionHistory {
  final String at; // ISO timestamp
  final String by; // actor name
  final String action;
  final String? note;
  const SubmissionHistory({required this.at, required this.by, required this.action, this.note});

  Map<String, dynamic> toJson() => {'at': at, 'by': by, 'action': action, if (note != null) 'note': note};

  factory SubmissionHistory.fromJson(Map<String, dynamic> j) => SubmissionHistory(
        at: (j['at'] ?? '').toString(),
        by: (j['by'] ?? '').toString(),
        action: (j['action'] ?? '').toString(),
        note: j['note']?.toString(),
      );
}

/// The routing record for one (grade, section, subject, term) gradebook.
class GradebookSubmission {
  final String id;
  final String grade;
  final String section;
  final String subject;
  final String term;
  final SubmissionStatus status;
  final String? subjectTeacherName;
  final String? classTeacherName;
  final String? gradeCoordinatorName;
  final String? principalName;
  final String? returnReason;
  final List<SubmissionHistory> history;
  final String createdAt;
  final String updatedAt;

  const GradebookSubmission({
    required this.id,
    required this.grade,
    required this.section,
    required this.subject,
    required this.term,
    required this.status,
    this.subjectTeacherName,
    this.classTeacherName,
    this.gradeCoordinatorName,
    this.principalName,
    this.returnReason,
    this.history = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'grade': grade,
        'section': section,
        'subject': subject,
        'term': term,
        'status': status.label,
        if (subjectTeacherName != null) 'subjectTeacherName': subjectTeacherName,
        if (classTeacherName != null) 'classTeacherName': classTeacherName,
        if (gradeCoordinatorName != null) 'gradeCoordinatorName': gradeCoordinatorName,
        if (principalName != null) 'principalName': principalName,
        if (returnReason != null) 'returnReason': returnReason,
        'history': history.map((h) => h.toJson()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory GradebookSubmission.fromJson(Map<String, dynamic> j) => GradebookSubmission(
        id: (j['id'] ?? '').toString(),
        grade: (j['grade'] ?? '').toString(),
        section: (j['section'] ?? '').toString(),
        subject: (j['subject'] ?? '').toString(),
        term: (j['term'] ?? '').toString(),
        status: SubmissionStatus.fromLabel(j['status']?.toString()),
        subjectTeacherName: j['subjectTeacherName']?.toString(),
        classTeacherName: j['classTeacherName']?.toString(),
        gradeCoordinatorName: j['gradeCoordinatorName']?.toString(),
        principalName: j['principalName']?.toString(),
        returnReason: j['returnReason']?.toString(),
        history: (j['history'] is List)
            ? (j['history'] as List)
                .whereType<Map>()
                .map((e) => SubmissionHistory.fromJson(e.cast<String, dynamic>()))
                .toList()
            : const [],
        createdAt: (j['createdAt'] ?? '').toString(),
        updatedAt: (j['updatedAt'] ?? '').toString(),
      );

  GradebookSubmission copyWith({
    SubmissionStatus? status,
    String? subjectTeacherName,
    String? classTeacherName,
    String? gradeCoordinatorName,
    String? principalName,
    String? returnReason,
    List<SubmissionHistory>? history,
    String? updatedAt,
  }) =>
      GradebookSubmission(
        id: id,
        grade: grade,
        section: section,
        subject: subject,
        term: term,
        status: status ?? this.status,
        subjectTeacherName: subjectTeacherName ?? this.subjectTeacherName,
        classTeacherName: classTeacherName ?? this.classTeacherName,
        gradeCoordinatorName: gradeCoordinatorName ?? this.gradeCoordinatorName,
        principalName: principalName ?? this.principalName,
        returnReason: returnReason ?? this.returnReason,
        history: history ?? this.history,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Stable key for a submission — `${grade}|${section}|${subject}|${term}`.
String submissionKey(String grade, String section, String subject, String term) =>
    '$grade|$section|$subject|$term';

/// Stable id for a MarkOverride — `${studentId}|${subject}|${columnKey}|${term}`.
String overrideKey(String studentId, String subject, String columnKey, String term) =>
    '$studentId|$subject|$columnKey|$term';

// ── notifications (ports pushNotifications.ts pushNotify) ──────────────────────

/// Post a real notification row, matching the desktop pushNotify payload shape.
Future<void> pushNotify({
  required String title,
  required String message,
  String type = 'info',
  String entity = 'assignment',
  String category = 'academic',
  String audienceRole = 'student',
  String? recipientGrade,
  String? recipientSection,
  String? recipientUid,
  String? recipientName,
  String uid = 'admin',
}) async {
  final now = DateTime.now();
  final id = 'ntf-${now.millisecondsSinceEpoch}-${now.microsecond}';
  await ApiClient.instance.createRecord('notifications', {
    'id': id,
    'type': type,
    'entity': entity,
    'category': category,
    'audienceRole': audienceRole,
    if (recipientGrade != null) 'recipientGrade': recipientGrade,
    if (recipientSection != null) 'recipientSection': recipientSection,
    if (recipientUid != null) 'recipientUid': recipientUid,
    if (recipientName != null) 'recipientName': recipientName,
    'title': title,
    'message': message,
    'time': now.toIso8601String(),
    'uid': uid,
    'read': false,
  });
}

// ── submission workflow service ───────────────────────────────────────────────

class GradebookApprovalService {
  GradebookApprovalService._();
  static final GradebookApprovalService instance = GradebookApprovalService._();

  String _nowIso() => DateTime.now().toIso8601String();

  /// Load every submission (used to find the one for a grade/section/subject/term).
  Future<List<GradebookSubmission>> loadSubmissions() async {
    final rows = await ApiClient.instance.getAll('GradebookSubmission');
    return rows.map(GradebookSubmission.fromJson).toList();
  }

  /// Find the submission for a specific gradebook, or null if none raised yet.
  Future<GradebookSubmission?> findSubmission(
      String grade, String section, String subject, String term) async {
    final key = submissionKey(grade, section, subject, term);
    for (final s in await loadSubmissions()) {
      if (submissionKey(s.grade, s.section, s.subject, s.term) == key) return s;
    }
    return null;
  }

  Future<GradebookSubmission> _save(GradebookSubmission sub) async {
    final withStamp = sub.copyWith(updatedAt: _nowIso());
    await ApiClient.instance.createRecord('GradebookSubmission', {
      ...withStamp.toJson(),
      'id': withStamp.id,
    });
    return withStamp;
  }

  GradebookSubmission _appendHistory(GradebookSubmission sub, String by, String action, [String? note]) =>
      sub.copyWith(history: [
        ...sub.history,
        SubmissionHistory(at: _nowIso(), by: by, action: action, note: note),
      ]);

  /// Subject Teacher submits the book to the Class Teacher.
  Future<GradebookSubmission> submitToClassTeacher({
    required String grade,
    required String section,
    required String subject,
    required String term,
    required String subjectTeacherName,
    required String classTeacherName,
  }) async {
    final existing = await findSubmission(grade, section, subject, term);
    final base = existing ??
        GradebookSubmission(
          id: submissionKey(grade, section, subject, term),
          grade: grade,
          section: section,
          subject: subject,
          term: term,
          status: SubmissionStatus.draft,
          createdAt: _nowIso(),
          updatedAt: _nowIso(),
        );
    var sub = base.copyWith(
      status: SubmissionStatus.submittedToClassTeacher,
      subjectTeacherName: subjectTeacherName,
      classTeacherName: classTeacherName,
      returnReason: null,
    );
    sub = _appendHistory(sub, subjectTeacherName, 'Submitted to Class Teacher');
    final saved = await _save(sub);
    await pushNotify(
      title: 'Gradebook submitted',
      message: '$subjectTeacherName submitted $subject ($grade-$section, $term) for your review.',
      audienceRole: 'teacher',
      recipientName: classTeacherName,
      recipientGrade: grade,
      recipientSection: section,
      uid: subjectTeacherName,
    );
    return saved;
  }

  /// Class Teacher approves → routes to the Grade Coordinator.
  Future<GradebookSubmission> classTeacherApprove({
    required GradebookSubmission submission,
    required String classTeacherName,
    required String gradeCoordinatorName,
  }) async {
    var sub = submission.copyWith(
      status: SubmissionStatus.submittedToGradeCoordinator,
      classTeacherName: classTeacherName,
      gradeCoordinatorName: gradeCoordinatorName,
    );
    sub = _appendHistory(sub, classTeacherName, 'Approved by Class Teacher');
    final saved = await _save(sub);
    await pushNotify(
      title: 'Gradebook approved by Class Teacher',
      message:
          '${submission.subject} (${submission.grade}-${submission.section}, ${submission.term}) needs your approval.',
      audienceRole: 'teacher',
      recipientName: gradeCoordinatorName,
      uid: classTeacherName,
    );
    if (submission.subjectTeacherName != null) {
      await pushNotify(
        title: 'Gradebook moved forward',
        message: 'Your ${submission.subject} gradebook was approved and sent to the Grade Coordinator.',
        audienceRole: 'teacher',
        recipientName: submission.subjectTeacherName,
        uid: classTeacherName,
      );
    }
    return saved;
  }

  /// Class Teacher returns the book to the Subject Teacher with a reason.
  Future<GradebookSubmission> classTeacherReturn({
    required GradebookSubmission submission,
    required String classTeacherName,
    required String reason,
  }) async {
    var sub = submission.copyWith(
      status: SubmissionStatus.returnedToSubjectTeacher,
      classTeacherName: classTeacherName,
      returnReason: reason,
    );
    sub = _appendHistory(sub, classTeacherName, 'Returned to Subject Teacher', reason);
    final saved = await _save(sub);
    if (submission.subjectTeacherName != null) {
      await pushNotify(
        title: 'Gradebook returned',
        message:
            'Your ${submission.subject} gradebook was returned for changes: $reason',
        type: 'warning',
        audienceRole: 'teacher',
        recipientName: submission.subjectTeacherName,
        uid: classTeacherName,
      );
    }
    return saved;
  }

  /// Grade Coordinator approves → routes to the Principal.
  Future<GradebookSubmission> gradeCoordinatorApprove({
    required GradebookSubmission submission,
    required String gradeCoordinatorName,
    required String principalName,
  }) async {
    var sub = submission.copyWith(
      status: SubmissionStatus.submittedToPrincipal,
      gradeCoordinatorName: gradeCoordinatorName,
      principalName: principalName,
    );
    sub = _appendHistory(sub, gradeCoordinatorName, 'Approved by Grade Coordinator');
    final saved = await _save(sub);
    await pushNotify(
      title: 'Gradebook awaiting final approval',
      message:
          '${submission.subject} (${submission.grade}-${submission.section}, ${submission.term}) needs your final approval.',
      audienceRole: 'principal',
      recipientName: principalName,
      uid: gradeCoordinatorName,
    );
    return saved;
  }

  /// Principal grants final approval → notifies everyone who signed off.
  Future<GradebookSubmission> principalApprove({
    required GradebookSubmission submission,
    required String principalName,
  }) async {
    var sub = submission.copyWith(
      status: SubmissionStatus.approvedByPrincipal,
      principalName: principalName,
    );
    sub = _appendHistory(sub, principalName, 'Approved by Principal');
    final saved = await _save(sub);
    final recipients = {
      submission.subjectTeacherName,
      submission.classTeacherName,
      submission.gradeCoordinatorName,
    }.whereType<String>().where((n) => n.isNotEmpty);
    for (final name in recipients) {
      await pushNotify(
        title: 'Gradebook approved',
        message:
            '${submission.subject} (${submission.grade}-${submission.section}, ${submission.term}) is fully approved.',
        type: 'success',
        audienceRole: 'teacher',
        recipientName: name,
        uid: principalName,
      );
    }
    return saved;
  }

  /// Look up the school's principal name (users where role == 'principal').
  Future<String?> getPrincipalName() async {
    try {
      final users = await ApiClient.instance.getAll('users');
      for (final u in users) {
        if ((u['role'] ?? '').toString().toLowerCase() == 'principal') {
          return (u['displayName'] ?? u['name'] ?? '').toString();
        }
      }
    } catch (_) {}
    return null;
  }
}

// ── mark overrides ─────────────────────────────────────────────────────────────

class MarkOverrideService {
  MarkOverrideService._();
  static final MarkOverrideService instance = MarkOverrideService._();

  /// All overrides for one (grade, section, subject, term).
  Future<List<MarkOverride>> getOverridesFor(
      String grade, String section, String subject, String term) async {
    final rows = await ApiClient.instance.getAll('MarkOverride');
    return rows
        .map(MarkOverride.fromJson)
        .where((o) =>
            o.grade == grade && o.section == section && o.subject == subject && o.term == term)
        .toList();
  }

  /// Persist a manual mark correction (create-or-replace by deterministic id).
  Future<void> saveMarkOverride({
    required String studentId,
    required String studentName,
    required String grade,
    required String section,
    required String subject,
    required String term,
    required String columnKey,
    required String columnLabel,
    required double? originalValue,
    required double overrideValue,
    required String reason,
    required String overriddenBy,
  }) async {
    final id = overrideKey(studentId, subject, columnKey, term);
    await ApiClient.instance.createRecord('MarkOverride', {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'grade': grade,
      'section': section,
      'subject': subject,
      'term': term,
      'columnKey': columnKey,
      'columnLabel': columnLabel,
      'originalValue': originalValue,
      'overrideValue': overrideValue,
      'reason': reason,
      'overriddenBy': overriddenBy,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
