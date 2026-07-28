import 'environment.dart';

class AppConstants {
  // ── API Configuration ─────────────────────────────────────────────────────
  // Resolved from --dart-define=API_URL at build time (see environment.dart).
  static String get baseUrl => Env.apiUrl;

  static const String loginEndpoint = '/api/session/login';
  static const String forgotPasswordEndpoint = '/api/session/forgot-password';
  static const String dataEndpoint = '/api/data';

  // ── Storage Keys ──────────────────────────────────────────────────────────
  static const String tokenKey = 'pm_token';
  static const String userKey = 'pm_user';
  static const String selectedChildKey = 'pm_child';

  // ── API Entity Table Names ────────────────────────────────────────────────
  static const String students = 'students';
  static const String invoices = 'invoices';
  static const String attendance = 'attendance';
  static const String assignments = 'assignments';
  static const String homework = 'assignments'; // no separate homework table; uses assignments
  static const String examMarks = 'exam_marks';
  static const String examResults = 'exam_marks'; // alias — same table as examMarks
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

  // ── Currency ──────────────────────────────────────────────────────────────
  static const String currency = 'BHD';
  static const int currencyDecimals = 3;
}
