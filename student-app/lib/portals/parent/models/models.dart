// ── All data models for Student Diwan Parent App ─────────────────────────────

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String phone;
  // Notification-channel preferences persisted on the user's own row
  // (emailNotif / smsNotif are in the server's USER_SELF_WRITABLE_FIELDS).
  final bool emailNotif;
  final bool smsNotif;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phone = '',
    this.emailNotif = true,
    this.smsNotif = false,
  });

  static bool _asBool(dynamic v, bool fallback) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid']?.toString() ?? json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    displayName: json['displayName']?.toString() ?? json['name']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
    phone: json['phone']?.toString() ?? json['mobile']?.toString() ?? '',
    emailNotif: _asBool(json['emailNotif'], true),
    smsNotif: _asBool(json['smsNotif'], false),
  );

  UserModel copyWith({
    String? displayName,
    String? phone,
    bool? emailNotif,
    bool? smsNotif,
  }) => UserModel(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        role: role,
        phone: phone ?? this.phone,
        emailNotif: emailNotif ?? this.emailNotif,
        smsNotif: smsNotif ?? this.smsNotif,
      );

  String get initials {
    final parts = displayName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class StudentModel {
  final String id;
  final String firstName;
  final String lastName;
  final String grade;
  final String classSection;
  final String classId;
  final String rollNumber;
  final String? photo;
  final String fatherEmail;
  final String motherEmail;
  final String guardianEmail;

  const StudentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.grade,
    required this.classSection,
    required this.classId,
    required this.rollNumber,
    this.photo,
    required this.fatherEmail,
    required this.motherEmail,
    required this.guardianEmail,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
    id: json['id']?.toString() ?? json['studentId']?.toString() ?? '',
    firstName: json['firstName']?.toString() ?? json['first_name']?.toString() ?? json['name']?.toString() ?? '',
    lastName: json['lastName']?.toString() ?? json['last_name']?.toString() ?? '',
    grade: json['grade']?.toString() ?? json['gradeLevel']?.toString() ?? '',
    classSection: json['classSection']?.toString() ?? json['section']?.toString() ?? json['className']?.toString() ?? '',
    classId: json['classId']?.toString() ?? json['class_id']?.toString() ?? '',
    rollNumber: json['rollNumber']?.toString() ?? json['roll_number']?.toString() ?? json['rollNo']?.toString() ?? '',
    photo: json['photo']?.toString() ?? json['profilePhoto']?.toString() ?? json['avatar']?.toString(),
    fatherEmail: (json['fatherEmail'] ?? json['father_email'] ?? '').toString().toLowerCase().trim(),
    motherEmail: (json['motherEmail'] ?? json['mother_email'] ?? '').toString().toLowerCase().trim(),
    guardianEmail: (json['guardianEmail'] ?? json['guardian_email'] ?? '').toString().toLowerCase().trim(),
  );

  String get fullName => '$firstName $lastName'.trim();

  // Renders in the required "Grade 3" / "Grade 3-B" format: strip any leading
  // "grade " from the raw value, then prefix exactly once (never "Grade Grade 3").
  String get gradeLabel {
    final g = grade.trim();
    if (g.isEmpty) return classSection.trim();
    final bare = g.replaceFirst(RegExp(r'^grade\s+', caseSensitive: false), '');
    final base = 'Grade $bare';
    final sec = classSection.trim();
    return sec.isEmpty ? base : '$base-$sec';
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  @override
  bool operator ==(Object other) => other is StudentModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  bool isLinkedTo(String email) {
    final e = email.toLowerCase().trim();
    return fatherEmail == e || motherEmail == e || guardianEmail == e;
  }
}

class InvoiceModel {
  final String id;
  final String studentId;
  final String description;
  final double amount;
  final String status;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final String? paymentMethod;

  const InvoiceModel({
    required this.id,
    required this.studentId,
    required this.description,
    required this.amount,
    required this.status,
    this.dueDate,
    this.paidDate,
    this.paymentMethod,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    description: json['description']?.toString() ?? json['title']?.toString() ?? json['type']?.toString() ?? 'Fee',
    amount: double.tryParse(json['amount']?.toString() ?? json['totalAmount']?.toString() ?? '0') ?? 0,
    status: json['status']?.toString() ?? 'Due',
    dueDate: _parseDate(json['dueDate'] ?? json['due_date']),
    paidDate: _parseDate(json['paidDate'] ?? json['paid_date']),
    paymentMethod: json['paymentMethod']?.toString() ?? json['payment_method']?.toString(),
  );

  bool get isPaid => status == 'Paid' || status == 'paid';
  bool get isOverdue {
    if (isPaid) return false;
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final DateTime date;
  final String status; // Present, Absent, Late, Holiday

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    date: _parseDate(json['date']) ?? DateTime.now(),
    status: json['status']?.toString() ?? 'Unknown',
  );
}

// A parent's real absence request, backed by the shared `StudentAbsenceRequest`
// table the class teacher reviews from their Attendance page. status is the
// server's review state: Pending → Approved / Rejected.
class AbsenceRequestModel {
  final String id;
  final String studentId;
  final String date; // ISO date the child will be absent
  final String reason;
  final String note;
  final String status; // Pending | Approved | Rejected
  final DateTime? createdAt;

  const AbsenceRequestModel({
    required this.id,
    required this.studentId,
    required this.date,
    required this.reason,
    required this.note,
    required this.status,
    this.createdAt,
  });

  factory AbsenceRequestModel.fromJson(Map<String, dynamic> json) => AbsenceRequestModel(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    reason: json['reason']?.toString() ?? '',
    note: json['note']?.toString() ?? '',
    status: json['status']?.toString() ?? 'Pending',
    createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
  );
}

class AssignmentModel {
  final String id;
  final String title;
  final String subject;
  final String description;
  final DateTime? dueDate;
  final bool submitted;
  final String? classId;
  final String? grade;
  final String? studentId;
  // Real submission-derived state (joined from `assignment_submissions` by the
  // provider). `graded` is true once the teacher has marked/closed it; `feedback`
  // carries the teacher's note. Null status → not yet resolved against a submission.
  final bool graded;
  final String? feedback;

  const AssignmentModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    this.dueDate,
    required this.submitted,
    this.classId,
    this.grade,
    this.studentId,
    this.graded = false,
    this.feedback,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) => AssignmentModel(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? json['name']?.toString() ?? 'Assignment',
    subject: json['subject']?.toString() ?? json['subjectName']?.toString() ?? 'General',
    description: json['description']?.toString() ?? json['instructions']?.toString() ?? '',
    dueDate: _parseDate(json['dueDate'] ?? json['due_date']),
    submitted: json['submitted'] == true || json['submittedAt'] != null,
    classId: json['classId']?.toString() ?? json['class_id']?.toString(),
    grade: json['grade']?.toString(),
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString(),
  );

  AssignmentModel copyWith({bool? submitted, bool? graded, String? feedback}) => AssignmentModel(
    id: id,
    title: title,
    subject: subject,
    description: description,
    dueDate: dueDate,
    submitted: submitted ?? this.submitted,
    classId: classId,
    grade: grade,
    studentId: studentId,
    graded: graded ?? this.graded,
    feedback: feedback ?? this.feedback,
  );

  // The parent-facing status label, mirroring desktop ParentAssignments:
  // Graded > Submitted > Overdue > Pending.
  String get status {
    if (graded) return 'Graded';
    if (submitted) return 'Submitted';
    if (dueDate != null && DateTime.now().isAfter(dueDate!)) return 'Overdue';
    return 'Pending';
  }

  bool get isOverdue {
    if (submitted || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }
}


// A published assessment (quiz/test/exam) as the parent sees it, with the
// child's real attempt folded in. Mirrors ParentAssessments.tsx's AssessmentRow
// + mapAssessment: status is derived from the attempt AND the teacher's
// results-release gate, never from the date alone.
class AssessmentRow {
  final String id;
  final String title;
  final String subject;
  final String type;
  final String date;
  final String status; // Upcoming | Awaiting Marks | Graded | Missed
  final String? grade;
  final double? score;
  final double? totalMarks;

  const AssessmentRow({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.date,
    required this.status,
    this.grade,
    this.score,
    this.totalMarks,
  });
}

class TimetableSlot {
  final String id;
  final String classId;
  final String? grade;
  final int day; // 1=Mon, 2=Tue, ..., 5=Fri
  final String startTime;
  final String endTime;
  final String subject;
  final String? teacher;
  final String? room;

  const TimetableSlot({
    required this.id,
    required this.classId,
    this.grade,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.teacher,
    this.room,
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json) => TimetableSlot(
    id: json['id']?.toString() ?? '',
    classId: json['classId']?.toString() ?? json['class_id']?.toString() ?? '',
    grade: json['grade']?.toString(),
    day: int.tryParse(json['day']?.toString() ?? json['dayOfWeek']?.toString() ?? json['dayNum']?.toString() ?? '1') ?? 1,
    startTime: json['startTime']?.toString() ?? json['start_time']?.toString() ?? json['time']?.toString() ?? '',
    endTime: json['endTime']?.toString() ?? json['end_time']?.toString() ?? '',
    subject: json['subject']?.toString() ?? json['subjectName']?.toString() ?? 'Class',
    teacher: json['teacher']?.toString() ?? json['teacherName']?.toString(),
    room: json['room']?.toString() ?? json['venue']?.toString() ?? json['classroom']?.toString(),
  );
}

class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String? targetRole;
  final DateTime? createdAt;
  final String? author;
  final String? category;

  const NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    this.targetRole,
    this.createdAt,
    this.author,
    this.category,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) => NoticeModel(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? json['subject']?.toString() ?? 'Notice',
    content: json['content']?.toString() ?? json['body']?.toString() ?? json['description']?.toString() ?? '',
    targetRole: json['targetRole']?.toString() ?? json['audience']?.toString(),
    createdAt: _parseDate(json['createdAt'] ?? json['date'] ?? json['publishedAt']),
    author: json['author']?.toString() ?? json['createdBy']?.toString(),
    category: json['category']?.toString() ?? json['type']?.toString(),
  );
}

// School-wide calendar events (holidays, functions, meetings) — the same
// `calendar_events` table the desktop ParentCalendar reads. Field fallbacks
// mirror the desktop parser: title ← title/name, date ← startDate/date/start,
// location ← location.
class CalendarEventModel {
  final String id;
  final String title;
  final DateTime? date;
  final String? location;
  final String? type;

  const CalendarEventModel({
    required this.id,
    required this.title,
    this.date,
    this.location,
    this.type,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) => CalendarEventModel(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? json['name']?.toString() ?? 'Event',
    date: _parseDate(json['startDate'] ?? json['start_date'] ?? json['date'] ?? json['start']),
    location: json['location']?.toString() ?? json['venue']?.toString(),
    type: json['type']?.toString() ?? json['eventType']?.toString(),
  );
}

class BehaviorIncident {
  final String id;
  final String studentId;
  final String description;
  final String type;
  final DateTime? date;
  final String? action;
  final String status;

  const BehaviorIncident({
    required this.id,
    required this.studentId,
    required this.description,
    required this.type,
    this.date,
    this.action,
    required this.status,
  });

  factory BehaviorIncident.fromJson(Map<String, dynamic> json) => BehaviorIncident(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    description: json['description']?.toString() ?? json['incident']?.toString() ?? '',
    type: json['type']?.toString() ?? json['category']?.toString() ?? 'General',
    date: _parseDate(json['date'] ?? json['createdAt']),
    action: json['action']?.toString() ?? json['consequence']?.toString(),
    status: json['status']?.toString() ?? 'Noted',
  );
}

class AchievementModel {
  final String id;
  final String studentId;
  final String title;
  final String description;
  final DateTime? date;
  final String category;
  final String level;

  const AchievementModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    this.date,
    required this.category,
    required this.level,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) => AchievementModel(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    title: json['title']?.toString() ?? json['name']?.toString() ?? 'Achievement',
    description: json['description']?.toString() ?? '',
    date: _parseDate(json['date'] ?? json['awardedAt'] ?? json['createdAt']),
    category: json['category']?.toString() ?? json['type']?.toString() ?? 'Academic',
    level: json['level']?.toString() ?? json['scope']?.toString() ?? 'School',
  );
}

class HealthRecord {
  final String id;
  final String studentId;
  final String? bloodGroup;
  final String? allergies;
  final String? medicalConditions;
  final String? height;
  final String? weight;
  final DateTime? lastCheckup;
  final String? emergencyContact;

  const HealthRecord({
    required this.id,
    required this.studentId,
    this.bloodGroup,
    this.allergies,
    this.medicalConditions,
    this.height,
    this.weight,
    this.lastCheckup,
    this.emergencyContact,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    bloodGroup: json['bloodGroup']?.toString() ?? json['blood_group']?.toString(),
    allergies: json['allergies']?.toString(),
    medicalConditions: json['medicalConditions']?.toString() ?? json['medical_conditions']?.toString() ?? json['conditions']?.toString(),
    height: json['height']?.toString(),
    weight: json['weight']?.toString(),
    lastCheckup: _parseDate(json['lastCheckup'] ?? json['last_checkup']),
    emergencyContact: json['emergencyContact']?.toString() ?? json['emergency_contact']?.toString(),
  );
}

class LibraryLoan {
  final String id;
  final String studentId;
  final String bookTitle;
  final String? author;
  final DateTime? borrowedDate;
  final DateTime? dueDate;
  final bool returned;

  const LibraryLoan({
    required this.id,
    required this.studentId,
    required this.bookTitle,
    this.author,
    this.borrowedDate,
    this.dueDate,
    required this.returned,
  });

  factory LibraryLoan.fromJson(Map<String, dynamic> json) => LibraryLoan(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    bookTitle: json['bookTitle']?.toString() ?? json['book_title']?.toString() ?? json['title']?.toString() ?? 'Book',
    author: json['author']?.toString(),
    borrowedDate: _parseDate(json['borrowedDate'] ?? json['issueDate'] ?? json['issue_date']),
    dueDate: _parseDate(json['dueDate'] ?? json['returnDate'] ?? json['due_date']),
    returned: json['returned'] == true || json['status'] == 'Returned',
  );

  bool get isOverdue {
    if (returned || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }
}

class TransportEnrollment {
  final String id;
  final String studentId;
  final String? routeId;
  final String? vehicleId;
  final String? stopName;
  final String? pickupTime;
  final String? dropoffTime;

  const TransportEnrollment({
    required this.id,
    required this.studentId,
    this.routeId,
    this.vehicleId,
    this.stopName,
    this.pickupTime,
    this.dropoffTime,
  });

  factory TransportEnrollment.fromJson(Map<String, dynamic> json) => TransportEnrollment(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    routeId: json['routeId']?.toString() ?? json['route_id']?.toString(),
    vehicleId: json['vehicleId']?.toString() ?? json['vehicle_id']?.toString(),
    stopName: json['stopName']?.toString() ?? json['stop']?.toString() ?? json['stop_name']?.toString(),
    pickupTime: json['pickupTime']?.toString() ?? json['pickup_time']?.toString(),
    dropoffTime: json['dropoffTime']?.toString() ?? json['dropoff_time']?.toString() ?? json['dropTime']?.toString(),
  );
}

// A single published stop on a transport route. Mirrors the desktop
// ParentTransport `stopsList` shape: { id, name, address?, time }.
class TransportStop {
  final String id;
  final String name;
  final String? address;
  final String? time;

  const TransportStop({required this.id, required this.name, this.address, this.time});

  factory TransportStop.fromJson(Map<String, dynamic> json) => TransportStop(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? json['stopName']?.toString() ?? json['stop']?.toString() ?? '',
    address: json['address']?.toString(),
    time: json['time']?.toString() ?? json['pickupTime']?.toString() ?? json['dropTime']?.toString(),
  );
}

class TransportRoute {
  final String id;
  final String name;
  final String? routeNumber;
  // Ordered stops published for this route (same source the desktop portal
  // reads). Empty when the admin hasn't published stop details yet.
  final List<TransportStop> stopsList;

  const TransportRoute({
    required this.id,
    required this.name,
    this.routeNumber,
    this.stopsList = const [],
  });

  factory TransportRoute.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stopsList'] ?? json['stops'] ?? json['stop_list'];
    final stops = <TransportStop>[];
    if (rawStops is List) {
      for (final s in rawStops) {
        if (s is Map) stops.add(TransportStop.fromJson(s.cast<String, dynamic>()));
      }
    }
    return TransportRoute(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['routeName']?.toString() ?? '',
      routeNumber: json['routeNumber']?.toString() ?? json['route_number']?.toString(),
      stopsList: stops,
    );
  }
}

class TransportVehicle {
  final String id;
  final String vehicleNumber;
  final String? driverName;
  final String? driverContact;

  const TransportVehicle({required this.id, required this.vehicleNumber, this.driverName, this.driverContact});

  factory TransportVehicle.fromJson(Map<String, dynamic> json) => TransportVehicle(
    id: json['id']?.toString() ?? '',
    vehicleNumber: json['vehicleNumber']?.toString() ?? json['vehicle_number']?.toString() ?? json['plateNumber']?.toString() ?? '',
    driverName: json['driverName']?.toString() ?? json['driver_name']?.toString() ?? json['driver']?.toString(),
    driverContact: json['driverContact']?.toString() ?? json['driver_contact']?.toString() ?? json['driverPhone']?.toString(),
  );
}

class ReportCardSubject {
  final String subject;
  final double obtained; // weighted marks obtained (out of `max`)
  final double max; // weight present (≤100)
  final double pct; // 0..100
  final String letter;

  const ReportCardSubject({
    required this.subject,
    required this.obtained,
    required this.max,
    required this.pct,
    required this.letter,
  });

  factory ReportCardSubject.fromJson(Map<String, dynamic> j) {
    double toNum(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
    return ReportCardSubject(
      subject: j['subject']?.toString() ?? '',
      obtained: toNum(j['obtained']),
      max: toNum(j['max']),
      pct: toNum(j['pct']),
      letter: j['letter']?.toString() ?? '—',
    );
  }
}

class ReportCard {
  final String id;
  final String studentId;
  final String term;
  final String year;
  final double? percentage;
  final String? overallGrade;
  final int? rank;
  final int? totalStudents;
  final String? teacherComments;
  final DateTime? publishedAt;
  final List<ReportCardSubject> subjects; // per-subject breakdown (desktop parity)
  final String? classTeacherRemark;
  final String? principalRemark;
  final String? teacherName;
  final String? status; // draft | submitted | verified | approved | published
  final bool publishedToParents;
  final String generatedAt; // sort stamp from the store (chronological order key)

  const ReportCard({
    required this.id,
    required this.studentId,
    required this.term,
    required this.year,
    this.percentage,
    this.overallGrade,
    this.rank,
    this.totalStudents,
    this.teacherComments,
    this.publishedAt,
    this.subjects = const [],
    this.classTeacherRemark,
    this.principalRemark,
    this.teacherName,
    this.status,
    this.publishedToParents = false,
    this.generatedAt = '',
  });

  // Is this report card actually released to the parent? Matches the desktop
  // visibility rule (only published records reach a parent).
  bool get isVisibleToParent =>
      status == null || status == 'published' || publishedToParents;

  factory ReportCard.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjects'];
    final subjects = <ReportCardSubject>[];
    if (rawSubjects is List) {
      for (final s in rawSubjects) {
        if (s is Map) subjects.add(ReportCardSubject.fromJson(s.cast<String, dynamic>()));
      }
    }
    return ReportCard(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
      term: json['term']?.toString() ?? json['semester']?.toString() ?? 'Term',
      year: json['year']?.toString() ?? json['academicYear']?.toString() ?? '',
      percentage: double.tryParse(
          json['overallPct']?.toString() ?? json['percentage']?.toString() ?? json['overallPercentage']?.toString() ?? ''),
      overallGrade: json['overallGrade']?.toString() ?? json['grade']?.toString(),
      rank: int.tryParse(json['rank']?.toString() ?? ''),
      totalStudents: int.tryParse(json['totalStudents']?.toString() ?? json['classSize']?.toString() ?? ''),
      teacherComments: json['classTeacherRemark']?.toString() ??
          json['teacherComments']?.toString() ??
          json['remarks']?.toString() ??
          json['comments']?.toString(),
      publishedAt: _parseDate(json['publishedAt'] ?? json['date']),
      subjects: subjects,
      classTeacherRemark: json['classTeacherRemark']?.toString(),
      principalRemark: json['principalRemark']?.toString(),
      teacherName: json['teacherName']?.toString(),
      status: json['status']?.toString(),
      publishedToParents: json['publishedToParents'] == true,
      generatedAt: json['generatedAt']?.toString() ?? '',
    );
  }
}

class ExamModel {
  final String id;
  final String examRecordId; // parent exam record (many slots share one record)
  final String name;
  final String? subject;
  final String? grade;
  final String? classId;
  final DateTime? date;
  final String? time;
  final String? venue;
  final String? seatNumber;
  final String? mode; // Offline | Online | Hybrid
  final double? totalMarks;
  // Released result — only present once the exam is published/completed AND a
  // mark exists for this child+subject. Null means "not released / no mark yet"
  // (never a fabricated zero).
  final double? score;
  final String? letter;
  final String status; // Upcoming | Completed

  const ExamModel({
    required this.id,
    String? examRecordId,
    required this.name,
    this.subject,
    this.grade,
    this.classId,
    this.date,
    this.time,
    this.venue,
    this.seatNumber,
    this.mode,
    this.totalMarks,
    this.score,
    this.letter,
    this.status = 'Upcoming',
  }) : examRecordId = examRecordId ?? id;

  factory ExamModel.fromJson(Map<String, dynamic> json) => ExamModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? json['title']?.toString() ?? json['examName']?.toString() ?? 'Exam',
    subject: json['subject']?.toString() ?? json['subjectName']?.toString(),
    grade: json['grade']?.toString(),
    classId: json['classId']?.toString() ?? json['class_id']?.toString(),
    date: _parseDate(json['date'] ?? json['examDate']),
    time: json['time']?.toString() ?? json['startTime']?.toString(),
    venue: json['venue']?.toString() ?? json['hall']?.toString() ?? json['room']?.toString(),
    seatNumber: json['seatNumber']?.toString() ?? json['seat']?.toString(),
  );

  bool get isUpcoming {
    if (date == null) return true;
    return date!.isAfter(DateTime.now());
  }
}

class StudyMaterial {
  final String id;
  final String title;
  final String subject;
  final String? grade;
  final String? classId;
  final String type;
  final DateTime? uploadedAt;
  final String? teacherName;
  final String? fileUrl;

  const StudyMaterial({
    required this.id,
    required this.title,
    required this.subject,
    this.grade,
    this.classId,
    required this.type,
    this.uploadedAt,
    this.teacherName,
    this.fileUrl,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> json) => StudyMaterial(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? json['name']?.toString() ?? 'Material',
    subject: json['subject']?.toString() ?? json['subjectName']?.toString() ?? 'General',
    grade: json['grade']?.toString(),
    classId: json['classId']?.toString() ?? json['class_id']?.toString(),
    type: json['type']?.toString() ?? json['fileType']?.toString() ?? 'PDF',
    uploadedAt: _parseDate(json['uploadedAt'] ?? json['createdAt'] ?? json['date']),
    teacherName: json['teacherName']?.toString() ?? json['teacher']?.toString() ?? json['uploadedBy']?.toString(),
    fileUrl: json['fileUrl']?.toString() ?? json['url']?.toString() ?? json['file']?.toString(),
  );
}

class StudentDocument {
  final String id;
  final String studentId;
  final String title;
  final String documentType;
  final DateTime? uploadedAt;
  final String? fileUrl;
  final String status;

  const StudentDocument({
    required this.id,
    required this.studentId,
    required this.title,
    required this.documentType,
    this.uploadedAt,
    this.fileUrl,
    required this.status,
  });

  factory StudentDocument.fromJson(Map<String, dynamic> json) => StudentDocument(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    title: json['title']?.toString() ?? json['name']?.toString() ?? 'Document',
    documentType: json['documentType']?.toString() ?? json['type']?.toString() ?? 'General',
    uploadedAt: _parseDate(json['uploadedAt'] ?? json['createdAt']),
    fileUrl: json['fileUrl']?.toString() ?? json['url']?.toString(),
    status: json['status']?.toString() ?? 'Active',
  );
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime? createdAt;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.createdAt,
    required this.read,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? json['subject']?.toString() ?? 'Notification',
    body: json['body']?.toString() ?? json['content']?.toString() ?? json['message']?.toString() ?? '',
    type: json['type']?.toString() ?? json['category']?.toString() ?? 'General',
    createdAt: _parseDate(json['createdAt'] ?? json['date'] ?? json['timestamp']),
    read: json['read'] == true || json['isRead'] == true,
  );
}

// ── Helper ──────────────────────────────────────────────────────────────────
DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}
