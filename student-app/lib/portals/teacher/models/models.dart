// ── Data Models for Student Diwan Teacher App ─────────────────────────────

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? teacherId;
  final String? profilePhoto;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.teacherId,
    this.profilePhoto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid']?.toString() ?? json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    displayName: json['displayName']?.toString() ?? json['name']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
    teacherId: json['teacherId']?.toString() ?? json['teacher_id']?.toString() ?? 'TCH1025',
    profilePhoto: json['profilePhoto']?.toString() ?? json['photoURL']?.toString() ?? json['avatar']?.toString() ?? json['photo']?.toString(),
  );

  UserModel copyWith({String? profilePhoto}) => UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        role: role,
        teacherId: teacherId,
        profilePhoto: profilePhoto ?? this.profilePhoto,
      );

  String get initials {
    final parts = displayName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class ClassModel {
  final String id;
  final String name;
  final String grade;
  final String section;
  final int studentCount;
  final String subject;

  const ClassModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.section,
    required this.studentCount,
    required this.subject,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? json['className']?.toString() ?? '',
    grade: json['grade']?.toString() ?? '',
    section: json['section']?.toString() ?? json['classSection']?.toString() ?? '',
    studentCount: int.tryParse(json['studentCount']?.toString() ?? json['student_count']?.toString() ?? '25') ?? 25,
    subject: json['subject']?.toString() ?? json['subjectName']?.toString() ?? 'General',
  );

  String get label => '$grade - $section';
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
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
    id: json['id']?.toString() ?? json['studentId']?.toString() ?? '',
    firstName: json['firstName']?.toString() ?? json['first_name']?.toString() ?? json['name']?.toString() ?? '',
    lastName: json['lastName']?.toString() ?? json['last_name']?.toString() ?? '',
    grade: json['grade']?.toString() ?? '',
    classSection: json['classSection']?.toString() ?? json['section']?.toString() ?? '',
    classId: json['classId']?.toString() ?? json['class_id']?.toString() ?? '',
    rollNumber: json['rollNumber']?.toString() ?? json['roll_number']?.toString() ?? '',
    photo: json['photo']?.toString() ?? json['profilePhoto']?.toString() ?? json['avatar']?.toString(),
    fatherEmail: (json['fatherEmail'] ?? json['father_email'] ?? '').toString().toLowerCase().trim(),
    motherEmail: (json['motherEmail'] ?? json['mother_email'] ?? '').toString().toLowerCase().trim(),
  );

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final DateTime date;
  final String status; // Present, Absent, Late, Leave

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    studentName: json['studentName']?.toString() ?? json['student_name']?.toString() ?? 'Student',
    date: _parseDate(json['date']) ?? DateTime.now(),
    status: json['status']?.toString() ?? 'Present',
  );
}

class AssignmentModel {
  final String id;
  final String title;
  final String subject;
  final String description;
  final DateTime? dueDate;
  final int submittedCount;
  final int totalCount;
  final String classId;
  final bool isHomework;

  const AssignmentModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    this.dueDate,
    required this.submittedCount,
    required this.totalCount,
    required this.classId,
    required this.isHomework,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) => AssignmentModel(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? json['name']?.toString() ?? 'Task',
    subject: json['subject']?.toString() ?? json['subjectName']?.toString() ?? 'General',
    description: json['description']?.toString() ?? json['instructions']?.toString() ?? '',
    dueDate: _parseDate(json['dueDate'] ?? json['due_date']),
    submittedCount: int.tryParse(json['submittedCount']?.toString() ?? json['submitted_count']?.toString() ?? '0') ?? 0,
    totalCount: int.tryParse(json['totalCount']?.toString() ?? json['total_count']?.toString() ?? '25') ?? 25,
    classId: json['classId']?.toString() ?? json['class_id']?.toString() ?? '',
    isHomework: json['isHomework'] == true || json['is_homework'] == 1 || json['type']?.toString().toLowerCase() == 'homework',
  );
}

class ExamMarkModel {
  final String id;
  final String studentId;
  final String studentName;
  final String subject;
  final double marks;
  final double maxMarks;
  final String? grade;
  final String? examName;

  const ExamMarkModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.marks,
    required this.maxMarks,
    this.grade,
    this.examName,
  });

  factory ExamMarkModel.fromJson(Map<String, dynamic> json) => ExamMarkModel(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
    studentName: json['studentName']?.toString() ?? json['student_name']?.toString() ?? 'Student',
    subject: json['subject']?.toString() ?? '',
    marks: double.tryParse(json['marks']?.toString() ?? json['score']?.toString() ?? '0') ?? 0,
    maxMarks: double.tryParse(json['maxMarks']?.toString() ?? json['max_marks']?.toString() ?? '100') ?? 100,
    grade: json['grade']?.toString() ?? json['letterGrade']?.toString(),
    examName: json['examName']?.toString() ?? json['exam']?.toString(),
  );

  double get percentage => maxMarks > 0 ? (marks / maxMarks) * 100 : 0;
}

class TimetableSlot {
  final String id;
  final String classId;
  final String className;
  final int day; // 1=Mon, 2=Tue, ..., 6=Sat
  final String startTime;
  final String endTime;
  final String subject;
  final String room;

  const TimetableSlot({
    required this.id,
    required this.classId,
    required this.className,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.room,
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json) => TimetableSlot(
    id: json['id']?.toString() ?? '',
    classId: json['classId']?.toString() ?? json['class_id']?.toString() ?? '',
    className: json['className']?.toString() ?? json['class_name']?.toString() ?? json['grade']?.toString() ?? '',
    day: int.tryParse(json['day']?.toString() ?? json['dayOfWeek']?.toString() ?? '1') ?? 1,
    startTime: json['startTime']?.toString() ?? json['start_time']?.toString() ?? '',
    endTime: json['endTime']?.toString() ?? json['end_time']?.toString() ?? '',
    subject: json['subject']?.toString() ?? json['subjectName']?.toString() ?? '',
    room: json['room']?.toString() ?? json['venue']?.toString() ?? 'Room 204',
  );
}

class MessageModel {
  final String id;
  final String senderName;
  final String senderRole;
  final String content;
  final DateTime? timestamp;
  final bool read;
  final int unreadCount;

  const MessageModel({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.content,
    this.timestamp,
    required this.read,
    this.unreadCount = 0,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id']?.toString() ?? '',
    senderName: json['senderName']?.toString() ?? json['name']?.toString() ?? 'Unknown',
    senderRole: json['senderRole']?.toString() ?? json['role']?.toString() ?? 'Parent',
    content: json['content']?.toString() ?? json['body']?.toString() ?? '',
    timestamp: _parseDate(json['timestamp'] ?? json['date']),
    read: json['read'] == true || json['isRead'] == true,
    unreadCount: int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
  );

  String get initials {
    final parts = senderName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class StudyMaterial {
  final String id;
  final String title;
  final String subject;
  final String grade;
  final String type;
  final DateTime? uploadedAt;
  final String? fileUrl;

  const StudyMaterial({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    required this.type,
    this.uploadedAt,
    this.fileUrl,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> json) => StudyMaterial(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    subject: json['subject']?.toString() ?? '',
    grade: json['grade']?.toString() ?? '',
    type: json['type']?.toString() ?? 'PDF',
    uploadedAt: _parseDate(json['uploadedAt'] ?? json['createdAt'] ?? json['date']),
    fileUrl: json['fileUrl']?.toString() ?? json['url']?.toString(),
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
    title: json['title']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    type: json['type']?.toString() ?? 'General',
    createdAt: _parseDate(json['createdAt'] ?? json['date']),
    read: json['read'] == true,
  );
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}
