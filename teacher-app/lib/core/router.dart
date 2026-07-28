import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/classes_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/homework_screen.dart';
import '../screens/assignments_screen.dart';
import '../screens/materials_screen.dart';
import '../screens/assessments_screen.dart';
import '../screens/gradebook_screen.dart';
import '../screens/results_screen.dart';
import '../screens/timetable_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/ai_assistant_screen.dart';
import '../screens/students_screen.dart';
import '../screens/exams_screen.dart';
import '../screens/ptm_screen.dart';
import '../screens/lms_screen.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefreshNotifier();

  ref.listen<AuthState>(authProvider, (prev, next) {
    if (prev?.isAuthenticated != next.isAuthenticated) {
      authRefresh.refresh();
    }
  });

  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final isAuth = ref.read(authProvider).isAuthenticated;
      final onSplash = state.matchedLocation == '/splash';
      final onLogin  = state.matchedLocation == '/login';

      if (!isAuth && !onLogin && !onSplash) return '/login';
      if (isAuth && (onLogin || onSplash)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash',          builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/dashboard',       builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/classes',         builder: (_, __) => const MyClassesScreen()),
      GoRoute(path: '/attendance',      builder: (_, __) => const AttendanceScreen()),
      GoRoute(path: '/homework',        builder: (_, __) => const HomeworkScreen()),
      GoRoute(path: '/create-homework',  builder: (_, __) => const CreateHomeworkScreen()),
      GoRoute(path: '/assignments',     builder: (_, __) => const AssignmentsScreen()),
      GoRoute(path: '/create-assignment', builder: (_, __) => const CreateAssignmentScreen()),
      GoRoute(path: '/study-materials', builder: (_, __) => const StudyMaterialsScreen()),
      GoRoute(path: '/upload-material',  builder: (_, __) => const UploadMaterialScreen()),
      GoRoute(path: '/assessments',     builder: (_, __) => const AssessmentsScreen()),
      GoRoute(path: '/create-assessment', builder: (_, __) => const CreateAssessmentScreen()),
      GoRoute(path: '/gradebook',       builder: (_, __) => const GradebookScreen()),
      GoRoute(path: '/results',         builder: (_, __) => const ResultsScreen()),
      GoRoute(path: '/timetable',       builder: (_, __) => const TimetableScreen()),
      GoRoute(path: '/messages',        builder: (_, __) => const MessagesScreen()),
      GoRoute(path: '/calendar',        builder: (_, __) => const CalendarScreen()),
      GoRoute(path: '/reports',         builder: (_, __) => const ReportsScreen()),
      GoRoute(path: '/profile',         builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/ai-assistant',    builder: (_, __) => const AIAssistantScreen()),
      GoRoute(path: '/students',        builder: (_, __) => const StudentsScreen()),
      GoRoute(path: '/exams',           builder: (_, __) => const TeacherExamsScreen()),
      GoRoute(path: '/ptm',             builder: (_, __) => const PtmScreen()),
      GoRoute(path: '/lms',             builder: (_, __) => const LmsScreen()),
    ],
  );
});
