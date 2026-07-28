// ── All data models for Student Diwan Parent App ─────────────────────────────

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    displayName: json['displayName']?.toString() ?? json['name']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
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
  String get gradeLabel => [grade, classSection].where((s) => s.isNotEmpty).join(' – ');

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

  bool get isOverdue {
    if (submitted || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }
}

class ExamMarkModel {
  final String id;
  final String studentId;
  final String subject;
  final double marks;
  final double maxMarks;
  final String? grade;
  final String? teacherName;
  final String? examName;

  const ExamMarkModel({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.marks,
    required this.maxMarks,
    this.grade,
    this.teacherName,
    this.examName,
  });

  factory ExamMarkModel.fromJson(Map<String, dynamic> json) => ExamMarkModel(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    subject: json['subject']?.toString() ?? json['subjectName']?.toString() ?? '',
    marks: double.tryParse(json['marks']?.toString() ?? json['score']?.toString() ?? '0') ?? 0,
    maxMarks: double.tryParse(json['maxMarks']?.toString() ?? json['max_marks']?.toString() ?? '100') ?? 100,
    grade: json['grade']?.toString() ?? json['letterGrade']?.toString(),
    teacherName: json['teacherName']?.toString() ?? json['teacher']?.toString(),
    examName: json['examName']?.toString() ?? json['exam']?.toString(),
  );

  double get percentage => maxMarks > 0 ? (marks / maxMarks) * 100 : 0;
  String get letterGrade {
    if (grade != null && grade!.isNotEmpty) return grade!;
    final p = percentage;
    if (p >= 90) return 'A+';
    if (p >= 85) return 'A';
    if (p >= 80) return 'A–';
    if (p >= 75) return 'B+';
    if (p >= 70) return 'B';
    if (p >= 65) return 'C+';
    if (p >= 60) return 'C';
    return 'D';
  }
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

class MessageModel {
  final String id;
  final String fromName;
  final String fromEmail;
  final String subject;
  final String body;
  final DateTime? timestamp;
  final bool read;

  const MessageModel({
    required this.id,
    required this.fromName,
    required this.fromEmail,
    required this.subject,
    required this.body,
    this.timestamp,
    required this.read,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id']?.toString() ?? '',
    fromName: json['fromName']?.toString() ?? json['senderName']?.toString() ?? json['from']?.toString() ?? 'Unknown',
    fromEmail: json['fromEmail']?.toString() ?? json['senderEmail']?.toString() ?? '',
    subject: json['subject']?.toString() ?? json['title']?.toString() ?? 'Message',
    body: json['body']?.toString() ?? json['content']?.toString() ?? json['message']?.toString() ?? '',
    timestamp: _parseDate(json['timestamp'] ?? json['createdAt'] ?? json['date']),
    read: json['read'] == true || json['isRead'] == true,
  );

  String get initials {
    final parts = fromName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
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

class TransportRoute {
  final String id;
  final String name;
  final String? routeNumber;

  const TransportRoute({required this.id, required this.name, this.routeNumber});

  factory TransportRoute.fromJson(Map<String, dynamic> json) => TransportRoute(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? json['routeName']?.toString() ?? '',
    routeNumber: json['routeNumber']?.toString() ?? json['route_number']?.toString(),
  );
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
  });

  factory ReportCard.fromJson(Map<String, dynamic> json) => ReportCard(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    term: json['term']?.toString() ?? json['semester']?.toString() ?? 'Term',
    year: json['year']?.toString() ?? json['academicYear']?.toString() ?? '',
    percentage: double.tryParse(json['percentage']?.toString() ?? json['overallPercentage']?.toString() ?? ''),
    overallGrade: json['overallGrade']?.toString() ?? json['grade']?.toString(),
    rank: int.tryParse(json['rank']?.toString() ?? ''),
    totalStudents: int.tryParse(json['totalStudents']?.toString() ?? json['classSize']?.toString() ?? ''),
    teacherComments: json['teacherComments']?.toString() ?? json['remarks']?.toString() ?? json['comments']?.toString(),
    publishedAt: _parseDate(json['publishedAt'] ?? json['date']),
  );
}

class ExamModel {
  final String id;
  final String name;
  final String? subject;
  final String? grade;
  final String? classId;
  final DateTime? date;
  final String? time;
  final String? venue;
  final String? seatNumber;

  const ExamModel({
    required this.id,
    required this.name,
    this.subject,
    this.grade,
    this.classId,
    this.date,
    this.time,
    this.venue,
    this.seatNumber,
  });

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
