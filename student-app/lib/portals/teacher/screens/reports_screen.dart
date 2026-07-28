import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// Class performance summary computed entirely from live backend data — no
// fabricated percentages and no simulated PDF export. Each figure is derived
// from the same providers the individual screens use, so it always agrees with
// what the teacher sees elsewhere.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attAsync = ref.watch(attendanceRecordProvider('all'));
    final hwAsync = ref.watch(teacherHomeworkProvider);
    final asgnAsync = ref.watch(teacherAssignmentsListProvider);
    final assessAsync = ref.watch(teacherAssessmentsProvider);

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Class Performance Reports',
            subtitle: 'Live analytics from your class records',
            showBackButton: true,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(attendanceRecordProvider('all'));
                ref.invalidate(teacherHomeworkProvider);
                ref.invalidate(teacherAssignmentsListProvider);
                ref.invalidate(teacherAssessmentsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Attendance rate (present / total marks this month) ──────
                  attAsync.when(
                    loading: () => const _LoadingCard(),
                    error: (e, _) => _ErrorCard(message: 'Attendance unavailable'),
                    data: (records) {
                      final now = DateTime.now();
                      final month = records
                          .where((r) => r.date.year == now.year && r.date.month == now.month)
                          .toList();
                      final present =
                          month.where((r) => r.status == 'Present' || r.status == 'Late').length;
                      final pct = month.isEmpty ? null : (present / month.length * 100).round();
                      return _MetricCard(
                        icon: Icons.checklist_rtl_rounded,
                        title: 'Attendance Rate',
                        subtitle: month.isEmpty
                            ? 'No attendance recorded this month'
                            : '$present of ${month.length} marks present · this month',
                        value: pct == null ? '—' : '$pct%',
                        color: AppColors.green,
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── Homework assigned ───────────────────────────────────────
                  hwAsync.when(
                    loading: () => const _LoadingCard(),
                    error: (e, _) => _ErrorCard(message: 'Homework unavailable'),
                    data: (list) => _MetricCard(
                      icon: Icons.assignment_rounded,
                      title: 'Homework Assigned',
                      subtitle: list.isEmpty
                          ? 'No homework in your classes yet'
                          : '${list.length} homework record(s) for your class',
                      value: '${list.length}',
                      color: AppColors.amber,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Assignments assigned ────────────────────────────────────
                  asgnAsync.when(
                    loading: () => const _LoadingCard(),
                    error: (e, _) => _ErrorCard(message: 'Assignments unavailable'),
                    data: (list) => _MetricCard(
                      icon: Icons.assessment_rounded,
                      title: 'Assignments',
                      subtitle: list.isEmpty
                          ? 'No assignments in your classes yet'
                          : '${list.length} assignment record(s) for your class',
                      value: '${list.length}',
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Assessments created ─────────────────────────────────────
                  assessAsync.when(
                    loading: () => const _LoadingCard(),
                    error: (e, _) => _ErrorCard(message: 'Assessments unavailable'),
                    data: (list) => _MetricCard(
                      icon: Icons.quiz_rounded,
                      title: 'Assessments',
                      subtitle: list.isEmpty
                          ? 'You have not created any assessments'
                          : '${list.length} assessment(s) you created',
                      value: '${list.length}',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryExtraLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text1)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.text3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: SkeletonLoader(width: double.infinity, height: 84),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.redLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.red),
            const SizedBox(width: 12),
            Text(message,
                style: GoogleFonts.inter(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.red)),
          ],
        ),
      );
}
