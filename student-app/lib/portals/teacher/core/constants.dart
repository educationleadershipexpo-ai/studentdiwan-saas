import 'environment.dart';

class AppConstants {
  // ── API Configuration ─────────────────────────────────────────────────────
  static String get baseUrl => Env.apiUrl;

  static const String loginEndpoint = '/api/session/login';
  static const String forgotPasswordEndpoint = '/api/session/forgot-password';
  static const String dataEndpoint = '/api/data';

  // ── Storage Keys ──────────────────────────────────────────────────────────
  // Unified with the host app: the single login writes the session under these
  // keys (see student-app core/constants.dart StorageKeys), so the teacher module
  // hydrates from the same token instead of a portal-private one.
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_json';
  static const String biometricEnabledKey = 'sd_teacher_biometric_enabled';

  // ── API Entity Table Names ────────────────────────────────────────────────
  static const String students = 'students';
  static const String attendance = 'attendance';
  // Per-session marks-map documents — the single source of truth the desktop
  // and the student/parent portals read for attendance.
  static const String teacherAttendance = 'TeacherAttendance';
  static const String homework = 'assignments'; // uses assignments table with is_homework=1
  static const String assignments = 'assignments';
  static const String examMarks = 'exam_marks';
  static const String studyMaterials = 'study_materials';
  static const String notifications = 'notifications';
  static const String exams = 'exams';
  static const String timetableSlots = 'timetable_slots';
  static const String messages = 'messages';
  static const String calendarEvents = 'calendar_events';
  static const String classes = 'classes';
  static const String subjects = 'subjects';

  // ── Currency ──────────────────────────────────────────────────────────────
  static const String currency = 'BHD';
  static const int currencyDecimals = 3;
}
