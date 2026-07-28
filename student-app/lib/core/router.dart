import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

// ── Shared screens
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';

// ── Student portal screens
import '../screens/dashboard_screen.dart';
import '../screens/timetable_screen.dart';
import '../screens/homework_screen.dart';
import '../screens/materials_screen.dart';
import '../screens/assessments_screen.dart';
import '../screens/assignments_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/exams_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/report_cards_screen.dart';
import '../screens/fees_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/library_screen.dart';
import '../screens/transport_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/gradebook_screen.dart';
import '../screens/cafeteria_screen.dart';
import '../screens/health_screen.dart';
import '../screens/certificates_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/flashcards_screen.dart';


// ── Parent portal (real module — ported wholesale from parent-app) ────────────
import '../portals/parent/screens/home_screen.dart'            as p_home;
import '../portals/parent/screens/children_screen.dart'        as p_children;
import '../portals/parent/screens/attendance_screen.dart'      as p_attendance;
import '../portals/parent/screens/fees_screen.dart'            as p_fees;
import '../portals/parent/screens/timetable_screen.dart'       as p_timetable;
import '../portals/parent/screens/gradebook_screen.dart'       as p_gradebook;
import '../portals/parent/screens/assignments_screen.dart'     as p_assignments;
import '../portals/parent/screens/assessments_screen.dart'     as p_assessments;
import '../portals/parent/screens/messages_screen.dart'        as p_messages;
import '../portals/parent/screens/transport_screen.dart'       as p_transport;
import '../portals/parent/screens/calendar_screen.dart'        as p_calendar;
import '../portals/parent/screens/exams_screen.dart'           as p_exams;
import '../portals/parent/screens/report_cards_screen.dart'    as p_reportcards;
import '../portals/parent/screens/behaviour_screen.dart'       as p_behaviour;
import '../portals/parent/screens/achievements_screen.dart'    as p_achievements;
import '../portals/parent/screens/health_screen.dart'          as p_health;
import '../portals/parent/screens/library_screen.dart'         as p_library;
import '../portals/parent/screens/ptm_screen.dart'             as p_ptm;
import '../portals/parent/screens/notifications_screen.dart'   as p_notifications;
import '../portals/parent/screens/study_materials_screen.dart' as p_materials;
import '../portals/parent/screens/documents_screen.dart'       as p_documents;
import '../portals/parent/screens/announcements_screen.dart'   as p_announcements;
import '../portals/parent/screens/settings_screen.dart'        as p_settings;
import '../portals/parent/screens/more_screen.dart'            as p_more;

// ── Teacher portal (real module — ported wholesale from teacher-app) ──────────
import '../portals/teacher/screens/dashboard_screen.dart'    as t_dashboard;
import '../portals/teacher/screens/classes_screen.dart'      as t_classes;
import '../portals/teacher/screens/attendance_screen.dart'   as t_attendance;
import '../portals/teacher/screens/homework_screen.dart'     as t_homework;
import '../portals/teacher/screens/assignments_screen.dart'  as t_assignments;
import '../portals/teacher/screens/materials_screen.dart'    as t_materials;
import '../portals/teacher/screens/assessments_screen.dart'  as t_assessments;
import '../portals/teacher/screens/gradebook_screen.dart'    as t_gradebook;
import '../portals/teacher/screens/results_screen.dart'      as t_results;
import '../portals/teacher/screens/timetable_screen.dart'    as t_timetable;
import '../portals/teacher/screens/messages_screen.dart'     as t_messages;
import '../portals/teacher/screens/calendar_screen.dart'     as t_calendar;
import '../portals/teacher/screens/reports_screen.dart'      as t_reports;
import '../portals/teacher/screens/profile_screen.dart'      as t_profile;
import '../portals/teacher/screens/students_screen.dart'     as t_students;
import '../portals/teacher/screens/exams_screen.dart'        as t_exams;
import '../portals/teacher/screens/ptm_screen.dart'          as t_ptm;
import '../portals/teacher/screens/notifications_screen.dart' as t_notifications;
import '../portals/teacher/screens/behavior_screen.dart'     as t_behavior;
import '../portals/teacher/screens/leave_screen.dart'        as t_leave;
import '../portals/teacher/screens/help_center_screen.dart'  as t_help;
import '../portals/teacher/screens/flashcards_screen.dart'   as t_flashcards;

class _AuthChangeNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  // Use a ChangeNotifier as refreshListenable so the router is created once
  // and its redirect is re-evaluated on auth changes (no router recreation).
  final notifier = _AuthChangeNotifier();
  ref.listen<AuthState>(authProvider, (_, __) {
    // Defer to next microtask to avoid setState-during-build errors
    Future.microtask(notifier.ping);
  });
  ref.onDispose(notifier.dispose);

  String defaultForRole() {
    final role = ref.read(authProvider).role;
    switch (role) {
      case AppRole.teacher: return '/teacher/dashboard';
      case AppRole.parent:  return '/parent/home';
      default:              return '/dashboard';
    }
  }

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: [
      // ── Shared ────────────────────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),

      // ── Student Portal (unchanged) ─────────────────────────────────────────
      GoRoute(path: '/dashboard',     builder: (_, __) => const MainNavigationShell()),
      GoRoute(path: '/timetable',     builder: (_, __) => const TimetableScreen()),
      GoRoute(path: '/homework',      builder: (_, __) => const HomeworkScreen()),
      GoRoute(path: '/materials',     builder: (_, __) => const MaterialsScreen()),
      GoRoute(path: '/assessments',   builder: (_, __) => const AssessmentsScreen()),
      GoRoute(path: '/exams',         builder: (_, __) => const ExamsScreen()),
      GoRoute(path: '/assignments',   builder: (_, __) => const AssignmentsScreen()),
      GoRoute(path: '/attendance',    builder: (_, __) => const AttendanceScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/report-cards',  builder: (_, __) => const ReportCardsScreen()),
      // '/results' is consolidated into the Exams hub (Results tab), matching the
      // desktop, which aliases /student/results to the Exams page.
      GoRoute(path: '/results',       builder: (_, __) => const ExamsScreen()),
      GoRoute(path: '/fees',          builder: (_, __) => const FeesScreen()),
      GoRoute(path: '/calendar',      builder: (_, __) => const CalendarScreen()),
      GoRoute(path: '/messages',      builder: (_, __) => const MessagesScreen()),
      GoRoute(path: '/profile',       builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/library',       builder: (_, __) => const LibraryScreen()),
      GoRoute(path: '/transport',     builder: (_, __) => const TransportScreen()),
      GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/gradebook',     builder: (_, __) => const GradebookScreen()),
      GoRoute(path: '/cafeteria',    builder: (_, __) => const CafeteriaScreen()),
      GoRoute(path: '/health',       builder: (_, __) => const HealthScreen()),
      GoRoute(path: '/certificates', builder: (_, __) => const CertificatesScreen()),
      GoRoute(path: '/achievements', builder: (_, __) => const AchievementsScreen()),
      GoRoute(path: '/flashcards',   builder: (_, __) => const FlashcardsScreen()),


      // ── Parent Portal (flat routes — module screens carry their own nav) ────
      GoRoute(path: '/parent/home',            builder: (_, __) => const p_home.HomeScreen()),
      GoRoute(path: '/parent/children',        builder: (_, __) => const p_children.ChildrenScreen()),
      GoRoute(path: '/parent/attendance',      builder: (_, __) => const p_attendance.AttendanceScreen()),
      GoRoute(path: '/parent/fees',            builder: (_, __) => const p_fees.FeesScreen()),
      GoRoute(path: '/parent/timetable',       builder: (_, __) => const p_timetable.TimetableScreen()),
      GoRoute(path: '/parent/gradebook',       builder: (_, __) => const p_gradebook.GradebookScreen()),
      GoRoute(path: '/parent/assignments',     builder: (_, __) => const p_assignments.AssignmentsScreen()),
      GoRoute(path: '/parent/assessments',     builder: (_, __) => const p_assessments.AssessmentsScreen()),
      GoRoute(path: '/parent/messages',        builder: (_, __) => const p_messages.MessagesScreen()),
      GoRoute(path: '/parent/transport',       builder: (_, __) => const p_transport.TransportScreen()),
      GoRoute(path: '/parent/calendar',        builder: (_, __) => const p_calendar.CalendarScreen()),
      GoRoute(path: '/parent/exams',           builder: (_, __) => const p_exams.ExamsScreen()),
      GoRoute(path: '/parent/report-cards',    builder: (_, __) => const p_reportcards.ReportCardsScreen()),
      GoRoute(path: '/parent/behaviour',       builder: (_, __) => const p_behaviour.BehaviourScreen()),
      GoRoute(path: '/parent/achievements',    builder: (_, __) => const p_achievements.AchievementsScreen()),
      GoRoute(path: '/parent/health',          builder: (_, __) => const p_health.HealthScreen()),
      GoRoute(path: '/parent/library',         builder: (_, __) => const p_library.LibraryScreen()),
      GoRoute(path: '/parent/ptm',             builder: (_, __) => const p_ptm.PtmScreen()),
      GoRoute(path: '/parent/notifications',   builder: (_, __) => const p_notifications.NotificationsScreen()),
      GoRoute(path: '/parent/study-materials', builder: (_, __) => const p_materials.StudyMaterialsScreen()),
      GoRoute(path: '/parent/documents',       builder: (_, __) => const p_documents.DocumentsScreen()),
      GoRoute(path: '/parent/announcements',   builder: (_, __) => const p_announcements.AnnouncementsScreen()),
      GoRoute(path: '/parent/settings',        builder: (_, __) => const p_settings.SettingsScreen()),
      GoRoute(path: '/parent/more',            builder: (_, __) => const p_more.MoreScreen()),

      // ── Teacher Portal (flat routes — module screens carry their own nav) ───
      GoRoute(path: '/teacher/dashboard',         builder: (_, __) => const t_dashboard.DashboardScreen()),
      GoRoute(path: '/teacher/classes',           builder: (_, __) => const t_classes.MyClassesScreen()),
      GoRoute(path: '/teacher/attendance',        builder: (_, __) => const t_attendance.AttendanceScreen()),
      GoRoute(path: '/teacher/homework',          builder: (_, __) => const t_homework.HomeworkScreen()),
      GoRoute(path: '/teacher/create-homework',   builder: (_, __) => const t_homework.CreateHomeworkScreen()),
      GoRoute(path: '/teacher/assignments',       builder: (_, __) => const t_assignments.AssignmentsScreen()),
      GoRoute(path: '/teacher/create-assignment', builder: (_, __) => const t_assignments.CreateAssignmentScreen()),
      GoRoute(path: '/teacher/study-materials',   builder: (_, __) => const t_materials.StudyMaterialsScreen()),
      GoRoute(path: '/teacher/upload-material',   builder: (_, __) => const t_materials.UploadMaterialScreen()),
      GoRoute(path: '/teacher/assessments',       builder: (_, __) => const t_assessments.AssessmentsScreen()),
      GoRoute(path: '/teacher/create-assessment', builder: (_, __) => const t_assessments.CreateAssessmentScreen()),
      GoRoute(path: '/teacher/gradebook',         builder: (_, __) => const t_gradebook.GradebookScreen()),
      GoRoute(path: '/teacher/results',           builder: (_, __) => const t_results.ResultsScreen()),
      GoRoute(path: '/teacher/timetable',         builder: (_, __) => const t_timetable.TimetableScreen()),
      GoRoute(path: '/teacher/messages',          builder: (_, __) => const t_messages.MessagesScreen()),
      GoRoute(path: '/teacher/calendar',          builder: (_, __) => const t_calendar.CalendarScreen()),
      GoRoute(path: '/teacher/reports',           builder: (_, __) => const t_reports.ReportsScreen()),
      GoRoute(path: '/teacher/profile',           builder: (_, __) => const t_profile.ProfileScreen()),
      GoRoute(path: '/teacher/students',          builder: (_, __) => const t_students.StudentsScreen()),
      GoRoute(path: '/teacher/exams',             builder: (_, __) => const t_exams.TeacherExamsScreen()),
      GoRoute(path: '/teacher/ptm',               builder: (_, __) => const t_ptm.PtmScreen()),
      GoRoute(path: '/teacher/help',              builder: (_, __) => const t_help.HelpCenterScreen()),
      GoRoute(path: '/teacher/settings',          builder: (_, __) => const t_profile.ProfileScreen()),
      GoRoute(path: '/teacher/notifications',     builder: (_, __) => const t_notifications.NotificationsScreen()),
      GoRoute(path: '/teacher/behavior',          builder: (_, __) => const t_behavior.BehaviorScreen()),
      GoRoute(path: '/teacher/leave',             builder: (_, __) => const t_leave.LeaveScreen()),
      GoRoute(path: '/teacher/flashcards',        builder: (_, __) => const t_flashcards.FlashcardsScreen()),
    ],
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final isPublic = loc == '/login' || loc == '/splash';

      // Hold at splash until session restore completes
      if (auth.isInitializing) return loc == '/splash' ? null : '/splash';

      if (!auth.isAuthenticated) {
        return isPublic ? null : '/login';
      }

      // Authenticated — redirect from public pages to correct portal
      if (isPublic) return defaultForRole();

      // Prevent role mismatch (each role is confined to its own namespace)
      if (auth.isTeacher && !loc.startsWith('/teacher')) return '/teacher/dashboard';
      if (auth.isParent  && !loc.startsWith('/parent'))  return '/parent/home';
      if (auth.isStudent && (loc.startsWith('/teacher') || loc.startsWith('/parent'))) return '/dashboard';

      return null;
    },
  );
});
