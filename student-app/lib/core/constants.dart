import 'environment.dart';

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userRole = 'user_role';
  static const String savedEmail = 'saved_email';
  static const String userJson = 'user_json';
  static const String biometricEnabled = 'biometric_enabled';
}

class CacheBoxes {
  static const String offlineCache = 'student_offline_cache';
}

class CacheKeys {
  static const String studentProfile = 'student_profile';
  static const String studentTimetable = 'student_timetable';
  static const String studentHomework = 'student_homework';
  static const String studentAssignments = 'student_assignments';
  static const String studentMaterials = 'student_materials';
  static const String studentAssessments = 'student_assessments';
  static const String studentResults = 'student_results';
  static const String studentFees = 'student_fees';
  static const String studentMessages = 'student_messages';
  static const String studentCalendar = 'student_calendar';
  static const String studentLibrary = 'student_library';
  static const String studentTransport = 'student_transport';
}

class AppConstants {
  // Base host WITHOUT the /api suffix (endpoints below add /api explicitly).
  // Routes through Environment so --dart-define=API_URL works in prod (Vercel).
  static String get baseUrl {
    final base = Environment.baseApiUrl; // e.g. https://host/api
    return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
  }
  static const String loginEndpoint = '/api/session/login';
  static const String forgotPasswordEndpoint = '/api/session/forgot-password';
  static const String dataEndpoint = '/api/data';

  // ── Storage Keys ──
  static const String tokenKey = 'pm_token';
  static const String userKey = 'pm_user';
  static const String selectedChildKey = 'pm_child';

  // ── API Entity Table Names ──
  static const String students = 'students';
  static const String invoices = 'invoices';
  static const String attendance = 'attendance';
  static const String assignments = 'assignments';
  static const String homework = 'assignments';
  static const String examMarks = 'exam_marks';
  static const String examResults = 'exam_marks';
  static const String reportCards = 'report_cards';
  static const String behaviorIncidents = 'behavior_incidents';
  static const String achievements = 'achievements';
  static const String healthRecords = 'health_records';
  static const String transportEnrollments = 'transport_enrollments';
  static const String transportRoutes = 'transport_routes';
  static const String transportVehicles = 'transport_vehicles';
  static const String libraryLoans = 'library_loans';
  static const String studyMaterials = 'study_materials';
  static const String studentDocuments = 'student_documents';
  static const String notifications = 'notifications';
  static const String exams = 'exams';
  static const String examSeating = 'exam_seating';
  static const String timetableSlots = 'timetable_slots';
  static const String notices = 'notices';
  static const String messages = 'messages';
  static const String calendarEvents = 'calendar_events';
  static const String subjects = 'subjects';

  // ── Currency ──
  static const String currency = 'BHD';
  static const int currencyDecimals = 3;
}
