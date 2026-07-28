import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));

    final attAsync = ref.watch(attendanceProvider(kid.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBackHeader(title: 'Attendance · ${kid.firstName}'),
      body: attAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(message: 'Failed to load attendance', onRetry: () => ref.invalidate(attendanceProvider(kid.id))),
        data: (records) {
          final monthRecords = records.where((r) => r.date.year == _month.year && r.date.month == _month.month).toList();
          final present = monthRecords.where((r) => r.status == 'Present').length;
          final absent = monthRecords.where((r) => r.status == 'Absent').length;
          final late = monthRecords.where((r) => r.status == 'Late').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Summary
              Row(children: [
                _AttStat('$present', 'Present', AppColors.green),
                const SizedBox(width: 8),
                _AttStat('$absent', 'Absent', AppColors.red),
                const SizedBox(width: 8),
                _AttStat('$late', 'Late', AppColors.amber),
              ]),
              const SizedBox(height: 16),

              // Month nav
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 10)]),
                child: Row(children: [
                  _MonthBtn(icon: Icons.chevron_left_rounded, onTap: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
                  Expanded(child: Text(DateFormat('MMMM yyyy').format(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text1))),
                  _MonthBtn(icon: Icons.chevron_right_rounded, onTap: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
                ]),
              ),
              const SizedBox(height: 12),

              // Calendar
              _AttendanceCalendar(month: _month, records: monthRecords),
              const SizedBox(height: 12),

              // Legend
              Wrap(spacing: 14, runSpacing: 6, children: const [
                _Legend(color: AppColors.green, label: 'Present'),
                _Legend(color: AppColors.red, label: 'Absent'),
                _Legend(color: AppColors.amber, label: 'Late'),
                _Legend(color: AppColors.primaryExtraLight, label: 'Holiday'),
              ]),
            ]),
          );
        },
      ),
    );
  }
}

class _AttStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _AttStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 10)]),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.text3, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _MonthBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MonthBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: AppColors.primary, size: 20),
    ),
  );
}

class _AttendanceCalendar extends StatelessWidget {
  final DateTime month;
  final List<AttendanceRecord> records;
  const _AttendanceCalendar({required this.month, required this.records});

  @override
  Widget build(BuildContext context) {
    final Map<int, String> statusMap = {for (final r in records) r.date.day: r.status};
    final firstDay = DateTime(month.year, month.month, 1);
    final startOffset = firstDay.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 10)]),
      child: Column(children: [
        Row(children: ['Su','Mo','Tu','We','Th','Fr','Sa'].map((d) =>
          Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text3))))).toList()),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startOffset) return const SizedBox.shrink();
            final day = i - startOffset + 1;
            final status = statusMap[day];
            final isToday = today.year == month.year && today.month == month.month && today.day == day;

            Color bg = Colors.transparent;
            Color fg = AppColors.text2;
            if (status == 'Present') { bg = AppColors.greenLight; fg = AppColors.green; }
            else if (status == 'Absent') { bg = AppColors.redLight; fg = AppColors.red; }
            else if (status == 'Late') { bg = AppColors.amberLight; fg = AppColors.amber; }
            else if (status == 'Holiday') { bg = AppColors.primaryExtraLight; fg = AppColors.primary; }

            return Container(
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
              ),
              child: Center(child: Text('$day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isToday ? AppColors.primary : fg))),
            );
          },
        ),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2)),
  ]);
}
