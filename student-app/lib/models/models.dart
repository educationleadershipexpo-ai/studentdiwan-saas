class StudentProfile {
  final String id;
  final String displayName;
  final String email;
  final String gradeName;
  final String rollNumber;
  final String avatarUrl;
  final Map<String, dynamic>? studentData; // Full raw DB record

  StudentProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.gradeName,
    required this.rollNumber,
    required this.avatarUrl,
    this.studentData,
  });

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return displayName.substring(0, 2).toUpperCase();
  }

  String get grade => studentData?['grade'] as String? ?? '';
  String get section => studentData?['section'] as String? ?? '';
  String get gender => studentData?['gender'] as String? ?? '';
  String get dateOfBirth => studentData?['dateOfBirth'] as String? ?? '';
  String get nationality => studentData?['nationality'] as String? ?? '';
  String get bloodGroup => studentData?['bloodGroup'] as String? ?? '';
  String get address => studentData?['address'] as String? ?? '';
  String get phone => studentData?['phone'] as String? ?? '';
  String get fatherName => studentData?['fatherName'] as String? ?? '';
  String get motherName => studentData?['motherName'] as String? ?? '';

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      gradeName: json['gradeName'] ?? '',
      rollNumber: json['rollNumber'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'gradeName': gradeName,
        'rollNumber': rollNumber,
        'avatarUrl': avatarUrl,
      };
}


class TimetablePeriod {
  final String id;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacherName;
  final String room;
  final int day; // 1 = Mon, 2 = Tue, ..., 6 = Sat

  TimetablePeriod({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacherName,
    required this.room,
    required this.day,
  });

  factory TimetablePeriod.fromJson(Map<String, dynamic> json) {
    return TimetablePeriod(
      id: json['id'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      subject: json['subject'] ?? '',
      teacherName: json['teacherName'] ?? '',
      room: json['room'] ?? '',
      day: json['day'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'teacherName': teacherName,
        'room': room,
        'day': day,
      };
}

class HomeworkModel {
  final String id;
  final String title;
  final String subject;
  final String dueDate;
  final String priority; // High, Medium, Low
  final bool isCompleted;
  final String instructions;

  HomeworkModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
    required this.instructions,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      dueDate: json['dueDate'] ?? '',
      priority: json['priority'] ?? 'Medium',
      isCompleted: json['isCompleted'] ?? false,
      instructions: json['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'dueDate': dueDate,
        'priority': priority,
        'isCompleted': isCompleted,
        'instructions': instructions,
      };
}

class AssignmentModel {
  final String id;
  final String title;
  final String subject;
  final String dueDate;
  final int points;
  final int? score; // null if un-graded
  final String status; // Pending, Submitted, Graded
  final String? feedback;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.points,
    this.score,
    required this.status,
    this.feedback,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      dueDate: json['dueDate'] ?? '',
      points: json['points'] ?? 100,
      score: json['score'],
      status: json['status'] ?? 'Pending',
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'dueDate': dueDate,
        'points': points,
        'score': score,
        'status': status,
        'feedback': feedback,
      };
}

class StudyMaterialModel {
  final String id;
  final String title;
  final String subject;
  final String type; // Notes, Videos, Papers
  final String size;
  final String downloadUrl;

  StudyMaterialModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.size,
    required this.downloadUrl,
  });

  factory StudyMaterialModel.fromJson(Map<String, dynamic> json) {
    return StudyMaterialModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      type: json['type'] ?? 'Notes',
      size: json['size'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'type': type,
        'size': size,
        'downloadUrl': downloadUrl,
      };
}

class AssessmentModel {
  final String id;
  final String title;
  final String subject;
  final int durationMinutes;
  final int questionsCount;
  final int? scoreObtained;

  AssessmentModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.durationMinutes,
    required this.questionsCount,
    this.scoreObtained,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      questionsCount: json['questionsCount'] ?? 0,
      scoreObtained: json['scoreObtained'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'durationMinutes': durationMinutes,
        'questionsCount': questionsCount,
        'scoreObtained': scoreObtained,
      };
}

class ExamModel {
  final String id;
  final String title;
  final String dateRange;
  final String subject;
  final String room;

  ExamModel({
    required this.id,
    required this.title,
    required this.dateRange,
    required this.subject,
    required this.room,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      dateRange: json['dateRange'] ?? '',
      subject: json['subject'] ?? '',
      room: json['room'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateRange': dateRange,
        'subject': subject,
        'room': room,
      };
}

class ResultGrade {
  final String subject;
  final int score;
  final int total;
  final String grade;

  ResultGrade({
    required this.subject,
    required this.score,
    required this.total,
    required this.grade,
  });

  factory ResultGrade.fromJson(Map<String, dynamic> json) {
    return ResultGrade(
      subject: json['subject'] ?? '',
      score: json['score'] ?? 0,
      total: json['total'] ?? 100,
      grade: json['grade'] ?? 'A',
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'score': score,
        'total': total,
        'grade': grade,
      };
}

class FeeInvoice {
  final String invoiceNumber;
  final String dateDue;
  final double amount;
  final bool isPaid;

  FeeInvoice({
    required this.invoiceNumber,
    required this.dateDue,
    required this.amount,
    required this.isPaid,
  });

  factory FeeInvoice.fromJson(Map<String, dynamic> json) {
    return FeeInvoice(
      invoiceNumber: json['invoiceNumber'] ?? '',
      dateDue: json['dateDue'] ?? '',
      amount: (json['amount'] ?? 0.0) as double,
      isPaid: json['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'invoiceNumber': invoiceNumber,
        'dateDue': dateDue,
        'amount': amount,
        'isPaid': isPaid,
      };
}

class MessageModel {
  final String id;
  final String senderName;
  final String senderRole;
  final String content;
  final int unreadCount;
  final DateTime? timestamp;

  MessageModel({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.unreadCount,
    this.timestamp,
  });

  String get initials {
    final parts = senderName.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return senderName.substring(0, 2).toUpperCase();
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      senderName: json['senderName'] ?? '',
      senderRole: json['senderRole'] ?? '',
      content: json['content'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderName': senderName,
        'senderRole': senderRole,
        'content': content,
        'unreadCount': unreadCount,
        'timestamp': timestamp?.toIso8601String(),
      };
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
    uploadedAt: _parseDateHelper(json['uploadedAt'] ?? json['createdAt'] ?? json['date']),
    fileUrl: json['fileUrl']?.toString() ?? json['url']?.toString(),
  );
}

DateTime? _parseDateHelper(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}
