import 'environment.dart';

class AppConstants {
  // ── API Configuration ─────────────────────────────────────────────────────
  static String get baseUrl => Env.apiUrl;

  static const String loginEndpoint = '/api/session/login';
  static const String forgotPasswordEndpoint = '/api/session/forgot-password';
  static const String dataEndpoint = '/api/data';

  // ── Storage Keys ──────────────────────────────────────────────────────────
  // Use SAME token key as web app (sd_token) for cross-platform session sync
  static const String tokenKey = 'sd_token';
  static const String userKey = 'sd_user';
  static const String biometricEnabledKey = 'sd_biometric_enabled';

  // ── API Entity Table Names (PascalCase to match web app's entityMapping) ─────
  // These map to snake_case tables on server via server.ts entityMapping
  static const String students = 'Student';
  static const String attendance = 'AttendanceRecord';
  static const String homework = 'Assignment';
  static const String assignments = 'Assignment';
  static const String examMarks = 'ExamMark';
  static const String studyMaterials = 'StudyMaterial';
  static const String notifications = 'Notification';
  static const String exams = 'Exam';
  static const String timetableSlots = 'TimetableSlot';
  static const String messages = 'ChatMessage';
  static const String calendarEvents = 'CalendarEvent';
  static const String classes = 'Class';
  static const String subjects = 'Subject';
  static const String chatThreads = 'ChatThread';
  static const String chatThreadState = 'ChatThreadState';
  static const String staff = 'Staff';
  static const String leads = 'Lead';
  static const String behaviorIncidents = 'BehaviorIncident';
  static const String library = 'LibraryItem';

  // ── Currency ──────────────────────────────────────────────────────────────
  static const String currency = 'BHD';
  static const int currencyDecimals = 3;
}
