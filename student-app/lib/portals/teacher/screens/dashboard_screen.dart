import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/rbac.dart';
import '../../../core/strings.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

String _timeGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _headerFade;
  late Animation<double> _cardsSlide;
  late Animation<double> _quickActionsScale;
  late AnimationController _badgeController;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _cardsSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );

    _quickActionsScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack)),
    );

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  // ── Live "My Classes" card — the real distinct grade/section classes this
  //    teacher is assigned to (union of subject_assignments collapsed to one
  //    card per class, subjects joined). Mirrors the web dashboard "My Classes"
  //    which counts DISTINCT grade-section pairs, not raw subject rows. ──
  Widget _buildMyScheduleCard(BuildContext context) {
    final async = ref.watch(myClassesProvider);
    return async.when(
      loading: () => const GlassCard(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (_, __) => _scheduleEmpty(context, 'Could not load your classes'),
      data: (classes) {
        if (classes.isEmpty) {
          return _scheduleEmpty(context, 'No classes assigned to you yet');
        }
        final show = classes.take(3).toList();
        return Column(
          children: [
            for (final s in show) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_gradeLabel(s['grade'])} - ${s['section'] ?? ''}', style: context.heading3),
                          const SizedBox(height: 2),
                          Text(
                            () {
                              final subs = (s['subjects'] as List?)?.cast<String>() ?? const [];
                              return subs.isEmpty ? 'General' : subs.join(', ');
                            }(),
                            style: context.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFF1F3F9), borderRadius: BorderRadius.circular(10)),
                      child: Text('Section ${s['section'] ?? ''}', style: context.label.copyWith(color: AppColors.text2)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (classes.length > 3)
              Text('+ ${classes.length - 3} more classes', style: context.bodySmall.copyWith(color: AppColors.text3)),
          ],
        );
      },
    );
  }

  // Render grade label as a single "Grade 3" prefix (strips any existing one).
  String _gradeLabel(dynamic g) {
    final raw = (g ?? '').toString().trim();
    if (raw.isEmpty) return 'Grade';
    final stripped = raw.replaceFirst(RegExp(r'^grade\s*', caseSensitive: false), '');
    return 'Grade $stripped';
  }

  Widget _scheduleEmpty(BuildContext context, String msg) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.event_busy_rounded, color: AppColors.text3, size: 28),
          const SizedBox(width: 14),
          Expanded(child: Text(msg, style: context.body.copyWith(color: AppColors.text2))),
        ],
      ),
    );
  }

  // ── Live pending-task tiles built from real homework / assignment / behavior
  //    records, all scoped to this teacher's homeroom (same scope the web
  //    dashboard uses) so counts match the desktop portal exactly. ──
  Widget _buildPendingTasks(BuildContext context) {
    final hwAsync = ref.watch(teacherHomeworkProvider);
    final assignAsync = ref.watch(teacherAssignmentsListProvider);
    final behaviorAsync = ref.watch(teacherBehaviorScopedProvider);

    final hwCount = hwAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    final assignCount = assignAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    final behaviorOpen = behaviorAsync.maybeWhen(
      data: (list) => list.where((i) => (i['status'] ?? '').toString().toLowerCase() != 'resolved').length,
      orElse: () => 0,
    );

    final tiles = <Widget>[];
    if (hwCount > 0) {
      tiles.add(_PendingTaskTile(
        icon: Icons.assignment_turned_in_rounded,
        title: 'Homework to Review',
        subtitle: '$hwCount active homework item${hwCount == 1 ? '' : 's'}',
        count: hwCount,
        color: const Color(0xFF8B5CF6),
        path: '/teacher/homework',
      ));
    }
    if (assignCount > 0) {
      tiles.add(_PendingTaskTile(
        icon: Icons.grading_rounded,
        title: 'Assignments to Grade',
        subtitle: '$assignCount active assignment${assignCount == 1 ? '' : 's'}',
        count: assignCount,
        color: const Color(0xFFEC4899),
        path: '/teacher/assignments',
      ));
    }
    if (behaviorOpen > 0) {
      tiles.add(_PendingTaskTile(
        icon: Icons.report_gmailerrorred_rounded,
        title: 'Behavior Incidents',
        subtitle: '$behaviorOpen open incident${behaviorOpen == 1 ? '' : 's'}',
        count: behaviorOpen,
        color: const Color(0xFFF59E0B),
        path: '/teacher/behavior',
      ));
    }

    if (hwAsync.isLoading || assignAsync.isLoading || behaviorAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (tiles.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.green, size: 28),
            const SizedBox(width: 14),
            Expanded(child: Text('All caught up — no pending tasks', style: context.body.copyWith(color: AppColors.text2))),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          tiles[i],
        ],
      ],
    );
  }

  void _openQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const QuickActionsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = (user?.displayName.trim().isNotEmpty ?? false) ? user!.displayName : 'Teacher';
    // Real role string from the DB — drives which nav entries are shown (RBAC).
    final role = user?.role ?? '';
    // Real unread count — the bell badge only shows when there are genuinely
    // unread notifications, never as permanent decoration.
    final unreadCount = ref.watch(teacherNotificationsProvider).maybeWhen(
          data: (list) => list.where((n) => !n.read).length,
          orElse: () => 0,
        );

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenuDrawer(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Premium Header ──────────────────────────────────────────────
            AnimatedBuilder(
              animation: _headerFade,
              builder: (context, child) {
                return Opacity(
                  opacity: _headerFade.value,
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        Row(
                          children: [
                            // Notification bell with bounce badge
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                                  onPressed: () => context.push('/teacher/notifications'),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                                        CurvedAnimation(parent: _badgeController, curve: Curves.easeInOut),
                                      ),
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: const BoxDecoration(
                                          color: AppColors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // Profile Circle → tap opens Settings.
                            GestureDetector(
                              onTap: () => context.push('/teacher/settings'),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: context.cardColor,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primaryExtraLight,
                                  backgroundImage: (user?.profilePhoto != null &&
                                          user!.profilePhoto!.isNotEmpty)
                                      ? NetworkImage(user.profilePhoto!)
                                      : null,
                                  child: (user?.profilePhoto == null ||
                                          (user?.profilePhoto?.isEmpty ?? true))
                                      ? Text(
                                          user?.initials ?? 'T',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          '${_timeGreeting()}, ',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          '👋',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        color: context.cardColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── My Classes Card ─────────────────────────────────────────────
            AnimatedBuilder(
              animation: _cardsSlide,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _cardsSlide.value),
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // This card lists the teacher's assigned classes, not a
                        // day-filtered schedule — label it honestly.
                        Text("My Classes", style: context.heading2),
                        TextButton(
                          onPressed: () => context.push('/teacher/timetable'),
                          child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    _buildMyScheduleCard(context),
                  ],
                ),
              ),
            ),

            // ── Quick Access Grid (12 items) ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Access', style: context.heading2),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _quickActionsScale,
                    builder: (context, child) {
                      return ScaleTransition(
                        scale: _quickActionsScale,
                        child: child,
                      );
                    },
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                      children: [
                        if (canAccess(role, Capability.attendance))
                          _QuickAccessItem(icon: Icons.check_circle_outline_rounded, label: 'Attendance', color: const Color(0xFF6366F1), path: '/teacher/attendance'),
                        if (canAccess(role, Capability.homework))
                          _QuickAccessItem(icon: Icons.assignment_rounded, label: 'Homework', color: const Color(0xFFF59E0B), path: '/teacher/homework'),
                        if (canAccess(role, Capability.assignments))
                          _QuickAccessItem(icon: Icons.assessment_rounded, label: 'Assignments', color: const Color(0xFF10B981), path: '/teacher/assignments'),
                        if (canAccess(role, Capability.exams))
                          _QuickAccessItem(icon: Icons.border_color_rounded, label: 'Exams', color: const Color(0xFFEF4444), path: '/teacher/exams'),
                        if (canAccess(role, Capability.timetable))
                          _QuickAccessItem(icon: Icons.table_chart_rounded, label: 'Timetable', color: const Color(0xFF3B82F6), path: '/teacher/timetable'),
                        if (canAccess(role, Capability.students))
                          _QuickAccessItem(icon: Icons.people_rounded, label: 'Students', color: const Color(0xFFEC4899), path: '/teacher/classes'),
                        if (canAccess(role, Capability.results))
                          _QuickAccessItem(icon: Icons.bar_chart_rounded, label: 'Results', color: const Color(0xFF06B6D4), path: '/teacher/results'),
                        if (canAccess(role, Capability.materials))
                          _QuickAccessItem(icon: Icons.menu_book_rounded, label: 'Study Material', color: const Color(0xFF14B8A6), path: '/teacher/study-materials'),
                        _QuickAccessItem(icon: Icons.help_outline_rounded, label: 'Help', color: const Color(0xFF8B5CF6), path: '/teacher/help'),
                        _QuickAccessItem(icon: Icons.more_horiz_rounded, label: 'More', color: const Color(0xFF6B7280), onTap: () => _scaffoldKey.currentState?.openDrawer()),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Pending Tasks (live counts) ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pending Tasks', style: context.heading2),
                      TextButton(
                        onPressed: () => context.push('/teacher/homework'),
                        child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPendingTasks(context),
                ],
              ),
            ),
            const SizedBox(height: 80), // Offset for floating bottom bar
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: 0,
        onTap: (index) {
          if (index == 1) context.push('/teacher/classes');
          if (index == 3) context.push('/teacher/calendar');
          if (index == 4) context.push('/teacher/profile');
        },
        onFabPressed: () => _openQuickActions(context),
      ),
    );
  }
}

// ── Quick Access Tile Widget ─────────────────────────────────────────────────
class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? path;
  final String? badge;
  final VoidCallback? onTap;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.color,
    this.path,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (path != null) {
          context.push(path!);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              if (badge != null)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }
}

// ── Pending Task Tile Widget ─────────────────────────────────────────────────
class _PendingTaskTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Color color;
  final String path;

  const _PendingTaskTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(path),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.heading3),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
          ],
        ),
      ),
    );
  }
}

// ── Custom Floating Bottom Navigation Bar ────────────────────────────────────
class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabPressed;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.home_rounded,
            label: context.tr.home,
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _BottomNavItem(
            icon: Icons.people_outline_rounded,
            label: context.tr.classes,
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          // Floating Quick Action Button "+" in the center
          GestureDetector(
            onTap: onFabPressed,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.primaryGradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
          _BottomNavItem(
            icon: Icons.calendar_today_rounded,
            label: context.tr.calendar,
            isSelected: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
          _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: context.tr.profile,
            isSelected: selectedIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.text3,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.primary : AppColors.text3,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ── Floating Quick Actions Bottom Sheet ──────────────────────────────────────
class QuickActionsBottomSheet extends StatelessWidget {
  const QuickActionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Quick Actions', style: context.heading2),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.9,
            children: [
              _QuickActionItem(icon: Icons.check_box_outlined, label: 'Take Attendance', color: const Color(0xFF6366F1), path: '/teacher/attendance'),
              _QuickActionItem(icon: Icons.note_add_rounded, label: 'Create Homework', color: const Color(0xFFF59E0B), path: '/teacher/create-homework'),
              _QuickActionItem(icon: Icons.add_task_rounded, label: 'Create Assignment', color: const Color(0xFF10B981), path: '/teacher/create-assignment'),
              _QuickActionItem(icon: Icons.assignment_turned_in_outlined, label: 'Create Assessment', color: const Color(0xFFEF4444), path: '/teacher/create-assessment'),
              _QuickActionItem(icon: Icons.upload_file_rounded, label: 'Upload Material', color: const Color(0xFF14B8A6), path: '/teacher/upload-material'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String path;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close sheet
        context.push(path);
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          )
        ],
      ),
    );
  }
}

// ── Drawer (Side Menu) ───────────────────────────────────────────────────────
class SideMenuDrawer extends ConsumerWidget {
  const SideMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final name = (user?.displayName.trim().isNotEmpty ?? false) ? user!.displayName : 'Teacher';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.initials ?? 'T',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 24),
              ),
            ),
            accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(user?.email ?? ''),
          ),
          // Drawer body scrollable list — filtered to the role's capabilities.
          Expanded(
            child: Builder(builder: (context) {
              final role = user?.role ?? '';
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerTile(icon: Icons.dashboard_rounded, label: 'Dashboard', path: '/teacher/dashboard'),
                  if (canAccess(role, Capability.classes))
                    _DrawerTile(icon: Icons.people_rounded, label: 'My Classes', path: '/teacher/classes'),
                  if (canAccess(role, Capability.students))
                    _DrawerTile(icon: Icons.groups_rounded, label: 'Students', path: '/teacher/students'),
                  if (canAccess(role, Capability.attendance))
                    _DrawerTile(icon: Icons.check_circle_rounded, label: 'Attendance', path: '/teacher/attendance'),
                  if (canAccess(role, Capability.timetable))
                    _DrawerTile(icon: Icons.schedule_rounded, label: 'Timetable', path: '/teacher/timetable'),
                  if (canAccess(role, Capability.homework))
                    _DrawerTile(icon: Icons.assignment_rounded, label: 'Homework', path: '/teacher/homework'),
                  if (canAccess(role, Capability.assignments))
                    _DrawerTile(icon: Icons.assessment_rounded, label: 'Assignments', path: '/teacher/assignments'),
                  if (canAccess(role, Capability.materials))
                    _DrawerTile(icon: Icons.upload_file_rounded, label: 'Study Materials', path: '/teacher/study-materials'),
                  if (canAccess(role, Capability.assessments))
                    _DrawerTile(icon: Icons.border_color_rounded, label: 'Assessments', path: '/teacher/assessments'),
                  if (canAccess(role, Capability.exams))
                    _DrawerTile(icon: Icons.quiz_rounded, label: 'Exams', path: '/teacher/exams'),
                  if (canAccess(role, Capability.gradebook))
                    _DrawerTile(icon: Icons.table_view_rounded, label: 'Gradebook', path: '/teacher/gradebook'),
                  if (canAccess(role, Capability.results))
                    _DrawerTile(icon: Icons.insights_rounded, label: 'Results', path: '/teacher/results'),
                  if (canAccess(role, Capability.flashcards))
                    _DrawerTile(icon: Icons.style_rounded, label: 'Flashcards', path: '/teacher/flashcards'),
                  if (canAccess(role, Capability.behavior))
                    _DrawerTile(icon: Icons.psychology_rounded, label: 'Behavior', path: '/teacher/behavior'),
                  if (canAccess(role, Capability.ptm))
                    _DrawerTile(icon: Icons.groups_2_rounded, label: 'Parent Meetings (PTM)', path: '/teacher/ptm'),
                  if (canAccess(role, Capability.leave))
                    _DrawerTile(icon: Icons.beach_access_rounded, label: 'Leave', path: '/teacher/leave'),
                  if (canAccess(role, Capability.calendar))
                    _DrawerTile(icon: Icons.calendar_today_rounded, label: 'Calendar', path: '/teacher/calendar'),
                  if (canAccess(role, Capability.reports))
                    _DrawerTile(icon: Icons.analytics_rounded, label: 'Reports', path: '/teacher/reports'),
                  if (canAccess(role, Capability.notifications))
                    _DrawerTile(icon: Icons.notifications_rounded, label: 'Notifications', path: '/teacher/notifications'),
                  if (canAccess(role, Capability.messages))
                    _DrawerTile(icon: Icons.forum_rounded, label: 'Messages', path: '/teacher/messages'),
                  _DrawerTile(icon: Icons.help_center_rounded, label: 'Help Center', path: '/teacher/help'),
                  _DrawerTile(icon: Icons.settings_rounded, label: 'Settings', path: '/teacher/settings'),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.red),
                    title: const Text('Logout', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text2),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text1)),
      onTap: () {
        Navigator.pop(context); // Close drawer
        context.push(path);
      },
    );
  }
}
