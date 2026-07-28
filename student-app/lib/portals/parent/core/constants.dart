import 'environment.dart';

class AppConstants {
  // ── API Configuration ─────────────────────────────────────────────────────
  // Resolved from --dart-define=API_URL at build time (see environment.dart).
  static String get baseUrl => Env.apiUrl;

  static const String loginEndpoint = '/api/session/login';
  static const String forgotPasswordEndpoint = '/api/session/forgot-password';
  static const String changePasswordEndpoint = '/api/session/change-password';
  static const String dataEndpoint = '/api/data';

  // Real PayTabs payment gateway (same endpoints the desktop portal uses).
  // `paymentStatusEndpoint` reports whether the gateway is configured; if it
  // isn't, the app shows an honest "not available" message instead of a fake
  // success. `paymentSessionEndpoint` returns a hosted-checkout redirect URL.
  static const String paymentStatusEndpoint = '/api/payments/status';
  static const String paymentSessionEndpoint = '/api/payments/create-session';

  // ── Storage Keys ──────────────────────────────────────────────────────────
  // Unified with the host app: the single login writes the session under these
  // keys (see student-app core/constants.dart StorageKeys), so the parent module
  // hydrates from the same token instead of a portal-private one.
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_json';
  static const String selectedChildKey = 'pm_child';

  // ── API Entity Table Names ────────────────────────────────────────────────
  static const String students = 'students';
  static const String invoices = 'invoices';
  static const String attendance = 'attendance';
  // Per-session marks-map documents (same source the desktop portals read).
  static const String teacherAttendance = 'TeacherAttendance';
  // Desktop ParentAssignments/ParentDashboard read BOTH the raw
  // "TeacherAssignment" entity (Create Assignment) and the `homework` table
  // (desktop "Homework") — they are two separate tables.
  static const String assignments = 'TeacherAssignment';
  static const String homework = 'homework';
  static const String examMarks = 'exam_marks';
  // Assessments (quizzes/tests/exams) published via the teacher/admin Assessments
  // module, and the canonical per-student attempts table (score + isMarked).
  static const String assessments = 'assessments';
  static const String assessmentAttempts = 'assessment_attempts';
  static const String assessmentSubmissions = 'assessment_submissions'; // legacy
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
  static const String calendarEvents = 'calendar_events';
  static const String subjects = 'subjects';
  // Real support tickets raised from the parent Help & FAQ screen.
  static const String supportTickets = 'support_tickets';

  // ── Currency ──────────────────────────────────────────────────────────────
  static const String currency = 'BHD';
  static const int currencyDecimals = 3;
}
