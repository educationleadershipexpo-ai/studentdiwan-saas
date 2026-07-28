import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/format.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// Screens mapped to Navigation Tabs
import 'timetable_screen.dart';
import 'materials_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';

// ── MAIN NAVIGATION SHELL ──────────────────────────────────────────────────
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const MaterialsScreen(),
    const CalendarScreen(),
    ProfileScreen(onBack: () => setState(() => _currentIndex = 0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.text3,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: context.tr.home),
            BottomNavigationBarItem(icon: const Icon(Icons.menu_book_rounded), label: context.tr.learn),
            BottomNavigationBarItem(icon: const Icon(Icons.calendar_month_rounded), label: context.tr.calendar),
            BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: context.tr.profile),
          ],
        ),
      ),
    );
  }
}

// ── DASHBOARD SCREEN ───────────────────────────────────────────────────────
// Every section reads live :3001 data (profile, timetable, assignments/homework,
// TeacherAttendance). Empty results render an empty/placeholder state — never
// fabricated rows.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(studentProfileProvider);
    final String greeting = _getGreetingMessage();

    return Scaffold(
      backgroundColor: context.bgColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentProfileProvider);
          ref.invalidate(studentTimetableProvider);
          ref.invalidate(studentAssignmentsProvider);
          ref.invalidate(studentHomeworkProvider);
          ref.invalidate(studentAttendanceProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Purple/pink hero header
              _buildHeaderBanner(profileAsync.value, greeting),
              const SizedBox(height: 20),

              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeController.value,
                    child: Transform.translate(
                      offset: Offset(0.0, _slideAnimation.value),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Today's Schedule Card
                      Text(context.tr.todaySchedule, style: context.heading2),
                      const SizedBox(height: 12),
                      _buildTodayScheduleCard(),
                      const SizedBox(height: 20),

                      // Quick Access Section
                      Text(context.tr.quickActions, style: context.heading2),
                      const SizedBox(height: 12),
                      _buildQuickAccessGrid(),
                      const SizedBox(height: 24),

                      // Upcoming Activities
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr.pendingTasks, style: context.heading2),
                          TextButton(
                            onPressed: () => context.push('/assignments'),
                            child: Text(context.tr.viewAll, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildUpcomingActivitiesList(),
                      const SizedBox(height: 24),

                      // Attendance Ring Summary
                      Text(context.tr.attendanceRate, style: context.heading2),
                      const SizedBox(height: 12),
                      _buildAttendanceOverviewCard(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  Widget _buildHeaderBanner(StudentProfile? profile, String greeting) {
    final name = (profile?.displayName.trim().isNotEmpty ?? false)
        ? profile!.displayName.split(' ').first
        : 'Student';
    final fullName = profile?.displayName ?? '';
    final initials = profile?.initials ?? '';
    final classLine = _classLine(profile);

    return Container(
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
        bottom: 24,
        left: 20,
        right: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $name 👋',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                    onPressed: () => context.push('/notifications'),
                  ),
                  // Unread badge — driven by real notifications; hidden when none.
                  Consumer(
                    builder: (context, ref, _) {
                      final notifs = ref.watch(studentNotificationsProvider);
                      final unread = notifs.maybeWhen(
                        data: (rows) => rows.where((r) => r['read'] != true).length,
                        orElse: () => 0,
                      );
                      if (unread == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            shape: unread > 9 ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: unread > 9 ? BorderRadius.circular(9) : null,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Student profile summary block (real data)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryExtraLight,
                  child: Text(
                    initials.isEmpty ? '–' : initials,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? 'Loading…' : fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (classLine.isNotEmpty)
                      Text(
                        classLine,
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12.5),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds "Grade 3 - B  •  Roll No. 18" from the live student record.
  String _classLine(StudentProfile? profile) {
    if (profile == null) return '';
    final label = gradeLabel(profile.grade, profile.section);
    final roll = profile.rollNumber.trim();
    if (label.isEmpty) return roll;
    if (roll.isEmpty) return label;
    return '$label  •  $roll';
  }

  // ── Today's schedule (live timetable) ─────────────────────────────────────
  Widget _buildTodayScheduleCard() {
    final ttAsync = ref.watch(studentTimetableProvider);

    return ttAsync.when(
      loading: () => const SkeletonLoader(width: double.infinity, height: 96),
      error: (_, __) => _scheduleEmpty('Timetable unavailable right now.'),
      data: (slots) {
        final today = DateTime.now().weekday; // 1=Mon..7=Sun
        final todays = slots.where((s) => s.day == today).toList()
          ..sort((a, b) => _minutesOfDay(a.startTime).compareTo(_minutesOfDay(b.startTime)));

        if (todays.isEmpty) {
          return _scheduleEmpty(today >= 6
              ? 'No classes scheduled for the weekend.'
              : 'No classes scheduled for today.');
        }

        final now = DateTime.now();
        final nowMin = now.hour * 60 + now.minute;
        // Pick the currently-live period, else the next upcoming, else the last.
        TimetablePeriod current = todays.first;
        for (final p in todays) {
          final start = _minutesOfDay(p.startTime);
          final end = _minutesOfDay(p.endTime);
          if (nowMin >= start && nowMin < end) {
            current = p;
            break;
          }
          if (start >= nowMin) {
            current = p;
            break;
          }
          current = p; // fall through → keep last as default
        }

        final periodIndex = todays.indexOf(current) + 1;
        final isLive = nowMin >= _minutesOfDay(current.startTime) &&
            nowMin < _minutesOfDay(current.endTime);

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isLive ? 'Now' : 'Up Next', style: context.heading3),
                  GestureDetector(
                    onTap: () => context.push('/timetable'),
                    child: const Text(
                      'View All',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryExtraLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Period $periodIndex',
                            style: const TextStyle(color: AppColors.text3, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(current.subject, style: context.heading3.copyWith(fontSize: 15)),
                        if (current.teacherName.isNotEmpty)
                          Text(current.teacherName, style: const TextStyle(color: AppColors.text2, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (current.room.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFF1F3F9), borderRadius: BorderRadius.circular(10)),
                      child: Text(current.room,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.text2)),
                    ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.text3),
                  const SizedBox(width: 6),
                  Text('${current.startTime} - ${current.endTime}',
                      style: const TextStyle(fontSize: 12, color: AppColors.text3, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scheduleEmpty(String message) => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.event_available_rounded, color: AppColors.text3),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: AppColors.text2, fontSize: 13)),
            ),
          ],
        ),
      );

  int _minutesOfDay(String hhmm) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})\s*([AP]M)?', caseSensitive: false).firstMatch(hhmm.trim());
    if (m == null) return 0;
    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final ampm = m.group(3)?.toUpperCase();
    if (ampm == 'PM' && hour != 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  Widget _buildQuickAccessGrid() {
    final List<Map<String, dynamic>> items = [
      {'name': 'Attendance', 'icon': Icons.checklist_rtl_rounded, 'color': AppColors.green, 'route': '/attendance'},
      {'name': 'Timetable', 'icon': Icons.calendar_today_rounded, 'color': AppColors.purple, 'route': '/timetable'},
      {'name': 'Homework', 'icon': Icons.edit_note_rounded, 'color': AppColors.amber, 'route': '/homework'},
      {'name': 'Assignments', 'icon': Icons.assignment_outlined, 'color': Colors.red, 'route': '/assignments'},
      {'name': 'Exams', 'icon': Icons.quiz_rounded, 'color': Colors.indigo, 'route': '/exams'},
      {'name': 'Results', 'icon': Icons.analytics_outlined, 'color': Colors.teal, 'route': '/exams'},
      {'name': 'Gradebook', 'icon': Icons.grading_rounded, 'color': Colors.deepPurple, 'route': '/gradebook'},
      {'name': 'Materials', 'icon': Icons.folder_open_rounded, 'color': Colors.blue, 'route': '/materials'},
      {'name': 'Fees', 'icon': Icons.payment_rounded, 'color': Colors.orange, 'route': '/fees'},
      {'name': 'Cafeteria', 'icon': Icons.fastfood_rounded, 'color': Colors.pink, 'route': '/cafeteria'},
      {'name': 'Health', 'icon': Icons.medical_services_rounded, 'color': Colors.redAccent, 'route': '/health'},
      {'name': 'Honors', 'icon': Icons.workspace_premium_rounded, 'color': Colors.amber.shade700, 'route': '/certificates'},
      {'name': 'Badges', 'icon': Icons.military_tech_rounded, 'color': Colors.purpleAccent, 'route': '/achievements'},
      {'name': 'Flashcards', 'icon': Icons.style_rounded, 'color': Colors.cyan, 'route': '/flashcards'},
    ];


    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final Color col = item['color'];

        return InkWell(
          onTap: () => context.push(item['route'].toString()),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: col.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'], color: col, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                item['name'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.text1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        );
      },
    );
  }

  // ── Upcoming tasks (live assignments + homework, soonest 3) ───────────────
  Widget _buildUpcomingActivitiesList() {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);
    final homeworkAsync = ref.watch(studentHomeworkProvider);

    if (assignmentsAsync.isLoading || homeworkAsync.isLoading) {
      return Column(
        children: List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: SkeletonLoader(width: double.infinity, height: 64),
          ),
        ),
      );
    }

    final tasks = <_UpcomingTask>[];
    for (final a in assignmentsAsync.value ?? const <AssignmentModel>[]) {
      if (a.status.toLowerCase() == 'graded' || a.status.toLowerCase() == 'submitted') continue;
      tasks.add(_UpcomingTask(a.title, a.dueDate, 'Assignment', AppColors.amber, '/assignments'));
    }
    for (final h in homeworkAsync.value ?? const <HomeworkModel>[]) {
      if (h.isCompleted) continue;
      tasks.add(_UpcomingTask(h.title, h.dueDate, 'Homework', AppColors.purple, '/homework'));
    }

    // Sort by parseable due date; undated tasks sink to the bottom.
    tasks.sort((a, b) {
      final da = DateTime.tryParse(a.dueDate);
      final db = DateTime.tryParse(b.dueDate);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    final top = tasks.take(3).toList();

    if (top.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryExtraLight),
        ),
        child: const Row(
          children: [
            Icon(Icons.task_alt_rounded, color: AppColors.green),
            SizedBox(width: 12),
            Expanded(child: Text('No pending tasks. You are all caught up!',
                style: TextStyle(color: AppColors.text2, fontSize: 13))),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: top.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final task = top[index];
        return InkWell(
          onTap: () => context.push(task.route),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryExtraLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title.isEmpty ? task.badge : task.title,
                          style: context.heading3.copyWith(fontSize: 13.5),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(task.dueDate.isEmpty ? 'No due date' : 'Due ${_fmtDate(task.dueDate)}',
                          style: context.bodySmall),
                    ],
                  ),
                ),
                StatusChip(
                  label: task.badge,
                  textColor: task.color,
                  bgColor: task.color.withOpacity(0.08),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtDate(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return raw.length >= 10 ? raw.substring(0, 10) : raw;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Attendance overview (live TeacherAttendance) ──────────────────────────
  Widget _buildAttendanceOverviewCard() {
    final attendanceAsync = ref.watch(studentAttendanceProvider);

    return attendanceAsync.when(
      loading: () => const SkeletonLoader(width: double.infinity, height: 140),
      error: (_, __) => _attendanceEmpty('Attendance unavailable right now.'),
      data: (rows) {
        if (rows.isEmpty) {
          return _attendanceEmpty('No attendance has been recorded yet.');
        }

        int present = 0, absent = 0, late = 0, half = 0;
        for (final r in rows) {
          switch ((r['code'] as String?)?.toUpperCase()) {
            case 'P': present++; break;
            case 'A': absent++; break;
            case 'L': late++; break;
            case 'H': half++; break;
            default: present++; // any unknown recorded status counts as attended
          }
        }
        final total = rows.length;
        // Desktop formula: (P + L*0.5 + H*0.5) / total.
        final pct = total == 0 ? 0.0 : ((present + late * 0.5 + half * 0.5) / total) * 100;

        return GlassCard(
          child: Row(
            children: [
              CircularProgressRing(
                percentage: pct,
                size: 110,
                strokeWidth: 10,
                activeColor: pct >= 75 ? AppColors.green : (pct >= 50 ? AppColors.amber : AppColors.red),
                inactiveColor: AppColors.primaryExtraLight,
                centerWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.round()}%',
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text1),
                    ),
                    const Text('Present', style: TextStyle(fontSize: 10, color: AppColors.text3, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendRow('Present', _dayLabel(present), AppColors.green),
                    const SizedBox(height: 10),
                    _buildLegendRow('Absent', _dayLabel(absent), AppColors.red),
                    const SizedBox(height: 10),
                    _buildLegendRow('Late', _dayLabel(late), AppColors.amber),
                    if (half > 0) ...[
                      const SizedBox(height: 10),
                      _buildLegendRow('Half day', _dayLabel(half), AppColors.purple),
                    ],
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  String _dayLabel(int n) => n == 1 ? '1 Day' : '$n Days';

  Widget _attendanceEmpty(String message) => GlassCard(
        child: Row(
          children: [
            const Icon(Icons.event_busy_rounded, color: AppColors.text3),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: AppColors.text2, fontSize: 13))),
          ],
        ),
      );

  Widget _buildLegendRow(String title, String count, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text2, fontSize: 13)),
        const Spacer(),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text1, fontSize: 13)),
      ],
    );
  }
}

// Lightweight holder for a merged assignment/homework upcoming item.
class _UpcomingTask {
  final String title;
  final String dueDate;
  final String badge;
  final Color color;
  final String route;
  const _UpcomingTask(this.title, this.dueDate, this.badge, this.color, this.route);
}
