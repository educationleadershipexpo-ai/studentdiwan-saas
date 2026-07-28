import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/children_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/fees_screen.dart';
import '../screens/timetable_screen.dart';
import '../screens/results_screen.dart';
import '../screens/gradebook_screen.dart';
import '../screens/assignments_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/transport_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/exams_screen.dart';
import '../screens/report_cards_screen.dart';
import '../screens/behaviour_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/health_screen.dart';
import '../screens/library_screen.dart';
import '../screens/ptm_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/study_materials_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/announcements_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/more_screen.dart';

// Tells GoRouter to re-run redirect when auth state changes,
// without recreating the GoRouter instance itself.
class _AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefreshNotifier();

  // Fire whenever authenticated status flips — GoRouter re-runs redirect.
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

      // Not authenticated and not on splash/login → send to login
      if (!isAuth && !onLogin && !onSplash) return '/login';
      // Already authenticated and on login or splash → send to home
      if (isAuth && (onLogin || onSplash)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash',          builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home',            builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/children',        builder: (_, __) => const ChildrenScreen()),
      GoRoute(path: '/attendance',      builder: (_, __) => const AttendanceScreen()),
      GoRoute(path: '/fees',            builder: (_, __) => const FeesScreen()),
      GoRoute(path: '/timetable',       builder: (_, __) => const TimetableScreen()),
      GoRoute(path: '/results',         builder: (_, __) => const ResultsScreen()),
      GoRoute(path: '/gradebook',       builder: (_, __) => const GradebookScreen()),
      GoRoute(path: '/assignments',     builder: (_, __) => const AssignmentsScreen()),
      GoRoute(path: '/messages',        builder: (_, __) => const MessagesScreen()),
      GoRoute(path: '/transport',       builder: (_, __) => const TransportScreen()),
      GoRoute(path: '/calendar',        builder: (_, __) => const CalendarScreen()),
      GoRoute(path: '/exams',           builder: (_, __) => const ExamsScreen()),
      GoRoute(path: '/report-cards',    builder: (_, __) => const ReportCardsScreen()),
      GoRoute(path: '/behaviour',       builder: (_, __) => const BehaviourScreen()),
      GoRoute(path: '/achievements',    builder: (_, __) => const AchievementsScreen()),
      GoRoute(path: '/health',          builder: (_, __) => const HealthScreen()),
      GoRoute(path: '/library',         builder: (_, __) => const LibraryScreen()),
      GoRoute(path: '/ptm',             builder: (_, __) => const PtmScreen()),
      GoRoute(path: '/notifications',   builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/study-materials', builder: (_, __) => const StudyMaterialsScreen()),
      GoRoute(path: '/documents',       builder: (_, __) => const DocumentsScreen()),
      GoRoute(path: '/announcements',   builder: (_, __) => const AnnouncementsScreen()),
      GoRoute(path: '/settings',        builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/more',            builder: (_, __) => const MoreScreen()),
    ],
  );
});
