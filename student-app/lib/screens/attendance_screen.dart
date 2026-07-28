import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _focusedMonth = DateTime.now();

  Color _dotColor(String s) {
    if (s == 'Absent') return AppColors.red;
    if (s == 'Late') return AppColors.amber;
    return AppColors.green;
  }

  String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(studentAttendanceProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: attendanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildBody(context, []),
        data: (records) => _buildBody(context, records),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Map<String, dynamic>> records) {
    // Build a map from date → status from real DB records
    final Map<String, String> attendance = {};
    for (final r in records) {
      final date = r['date'] as String? ?? '';
      final status = r['status'] as String? ?? 'Present';
      if (date.isNotEmpty) {
        // Normalize date to YYYY-MM-DD
        final normalized = date.length >= 10 ? date.substring(0, 10) : date;
        attendance[normalized] = status;
      }
    }

    final present = attendance.values.where((v) => v == 'Present').length;
    final absent = attendance.values.where((v) => v == 'Absent').length;
    final late = attendance.values.where((v) => v == 'Late').length;
    final total = attendance.length;
    final percent = total == 0 ? 0.0 : (present / total) * 100;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 190,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Attendance', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatChip(label: 'Present', value: '$present', color: Colors.white),
                          const SizedBox(width: 16),
                          _StatChip(label: 'Absent', value: '$absent', color: Colors.red.shade200),
                          const SizedBox(width: 16),
                          _StatChip(label: 'Late', value: '$late', color: Colors.amber.shade200),
                          const Spacer(),
                          if (total > 0) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: Text('${percent.toStringAsFixed(1)}%', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                    ),
                    Text(_monthName(_focusedMonth.month) + ' ' + _focusedMonth.year.toString(),
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: context.t1)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((d) =>
                    Expanded(child: Center(child: Text(d, style: GoogleFonts.inter(fontSize: 11, color: context.t3, fontWeight: FontWeight.w600))))
                  ).toList(),
                ),
                const SizedBox(height: 8),
                _buildCalendar(attendance),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _Legend(color: AppColors.green, label: 'Present'),
                  const SizedBox(width: 20),
                  _Legend(color: AppColors.red, label: 'Absent'),
                  const SizedBox(width: 20),
                  _Legend(color: AppColors.amber, label: 'Late'),
                ]),
                const SizedBox(height: 20),

                if (total == 0) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                    child: Column(children: [
                      Icon(Icons.event_available_rounded, size: 48, color: AppColors.text3),
                      const SizedBox(height: 12),
                      Text('Attendance records will appear here once they are marked by your teacher.',
                        textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.text2, fontSize: 14)),
                    ]),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Attendance Rate', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.t1)),
                          Text('${percent.toStringAsFixed(1)}%', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14,
                              color: percent >= 75 ? AppColors.green : AppColors.red)),
                        ]),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 10,
                            backgroundColor: context.bgColor,
                            valueColor: AlwaysStoppedAnimation(percent >= 75 ? AppColors.green : AppColors.red),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(percent >= 75 ? '✅ Good attendance — keep it up!' : '⚠️ Attendance below 75%. Please improve.',
                            style: GoogleFonts.inter(fontSize: 12, color: context.t2)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(Map<String, String> attendance) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday;
    final cells = <Widget>[];
    for (int i = 1; i < startWeekday; i++) cells.add(const SizedBox());
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      final key = _key(date);
      final status = attendance[key];
      final isWeekend = date.weekday == 6 || date.weekday == 7;
      final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
      cells.add(Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? AppColors.primary : status != null ? _dotColor(status).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: AppColors.primary) : null,
        ),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$d', style: GoogleFonts.inter(fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? Colors.white : isWeekend ? context.t3 : context.t1)),
          if (status != null && !isToday)
            Container(width: 5, height: 5, decoration: BoxDecoration(color: _dotColor(status), shape: BoxShape.circle)),
        ])),
      ));
    }
    return GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1, children: cells);
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _StatChip extends StatelessWidget {
  final String label, value; final Color color;
  const _StatChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
  ]);
}

class _Legend extends StatelessWidget {
  final Color color; final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: GoogleFonts.inter(fontSize: 12, color: context.t2)),
  ]);
}
