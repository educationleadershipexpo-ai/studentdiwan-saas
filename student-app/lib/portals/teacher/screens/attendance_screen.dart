import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/api_client.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _searchQuery = '';
  final Map<String, String> _attendanceMap = {}; // studentId -> Present/Absent/Late/Leave
  String _loadedForDate = ''; // guards re-seeding when marks already loaded
  bool _saving = false;
  bool _showSuccess = false;

  String _fmtApiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final homeAsync = ref.watch(teacherHomeroomProvider);
    final studentsAsync = ref.watch(myStudentsProvider);
    // Real saved attendance for prefilling the selected day.
    final recordsAsync = ref.watch(attendanceRecordProvider('all'));

    final className = homeAsync.asData != null
        ? '${homeAsync.asData!.value.grade} - ${homeAsync.asData!.value.section}'
        : 'My Class';

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // ── Gradient Header ──────────────────────────────────────────
              AppHeader(
                title: 'Attendance Tracker',
                subtitle: className,
                showBackButton: true,
              ),
              const SizedBox(height: 16),

              // ── Date Switcher ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primary),
                      onPressed: () {
                        _loadedForDate = '';
                        _attendanceMap.clear();
                        ref.read(selectedDateProvider.notifier).state =
                            selectedDate.subtract(const Duration(days: 1));
                      },
                    ),
                    Text(
                      DateFormat('EEEE, dd MMM yyyy').format(selectedDate),
                      style: context.heading3.copyWith(color: AppColors.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary),
                      onPressed: () {
                        _loadedForDate = '';
                        _attendanceMap.clear();
                        ref.read(selectedDateProvider.notifier).state =
                            selectedDate.add(const Duration(days: 1));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Stats Row ────────────────────────────────────────────────
              studentsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
                data: (students) {
                  _seedMarks(students, recordsAsync, selectedDate);

                  final present = _attendanceMap.values.where((v) => v == 'Present').length;
                  final absent = _attendanceMap.values.where((v) => v == 'Absent').length;
                  final late = _attendanceMap.values.where((v) => v == 'Late').length;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCountCard(
                            label: 'Present',
                            count: present,
                            color: AppColors.green,
                            bgColor: AppColors.greenLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCountCard(
                            label: 'Absent',
                            count: absent,
                            color: AppColors.red,
                            bgColor: AppColors.redLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCountCard(
                            label: 'Late',
                            count: late,
                            color: AppColors.orange,
                            bgColor: AppColors.orangeLight,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Search Student Bar ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                          decoration: const InputDecoration(
                            hintText: 'Search student...',
                            hintStyle: TextStyle(color: AppColors.text3),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Students List ────────────────────────────────────────────
              Expanded(
                child: studentsAsync.when(
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 5,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SkeletonLoader(width: double.infinity, height: 70),
                    ),
                  ),
                  error: (err, stack) => Center(child: Text('Error loading students: $err')),
                  data: (students) {
                    final filtered = students
                        .where((s) =>
                            (s['name'] ?? '').toString().toLowerCase().contains(_searchQuery))
                        .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 48, color: AppColors.text3),
                            const SizedBox(height: 12),
                            Text('No students in your class',
                                style: context.bodySmall.copyWith(color: AppColors.text3)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final id = item['id']?.toString() ?? '';
                        final fullName = item['name']?.toString() ?? 'Unknown';
                        final initials = fullName.trim().isNotEmpty
                            ? fullName.trim()[0].toUpperCase()
                            : '?';
                        final status = _attendanceMap[id] ?? 'Present';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
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
                              Text('${index + 1}',
                                  style: context.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryExtraLight,
                                child: Text(initials,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(fullName,
                                    style: context.body.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              Row(
                                children: [
                                  _AttendanceSelectChip(
                                    label: 'P',
                                    active: status == 'Present',
                                    color: AppColors.green,
                                    onTap: () => setState(() => _attendanceMap[id] = 'Present'),
                                  ),
                                  const SizedBox(width: 4),
                                  _AttendanceSelectChip(
                                    label: 'A',
                                    active: status == 'Absent',
                                    color: AppColors.red,
                                    onTap: () => setState(() => _attendanceMap[id] = 'Absent'),
                                  ),
                                  const SizedBox(width: 4),
                                  _AttendanceSelectChip(
                                    label: 'L',
                                    active: status == 'Late',
                                    color: AppColors.orange,
                                    onTap: () => setState(() => _attendanceMap[id] = 'Late'),
                                  ),
                                  const SizedBox(width: 4),
                                  _AttendanceSelectChip(
                                    label: 'LV',
                                    active: status == 'Leave',
                                    color: AppColors.blue,
                                    onTap: () => setState(() => _attendanceMap[id] = 'Leave'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Save Button ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _saveAttendance(studentsAsync, className),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.security_rounded, size: 20, color: Colors.white),
                    label: const Text('Save Attendance'),
                  ),
                ),
              )
            ],
          ),
          if (_saving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (_showSuccess)
            Container(
              color: context.cardColor,
              child: SuccessCheckmark(
                title: 'Attendance Saved!',
                onComplete: () {
                  setState(() => _showSuccess = false);
                  context.pop();
                },
              ),
            ),
        ],
      ),
    );
  }

  // Prefill marks from real saved records for the selected date; anyone with no
  // record defaults to Present (mirrors web). Runs once per date.
  void _seedMarks(
    List<Map<String, dynamic>> students,
    AsyncValue<List<dynamic>> recordsAsync,
    DateTime date,
  ) {
    final key = _fmtApiDate(date);
    if (_loadedForDate == key) return;
    // Wait until records are loaded before seeding, so a saved day isn't
    // briefly shown as all-Present then flipped.
    if (recordsAsync is! AsyncData) return;

    final records = recordsAsync.asData!.value;
    final byId = <String, String>{};
    for (final r in records) {
      // AttendanceRecord: studentId, date (DateTime), status
      final rDate = r.date;
      final sameDay = rDate is DateTime && _fmtApiDate(rDate) == key;
      if (sameDay) {
        final sid = r.studentId?.toString() ?? '';
        if (sid.isNotEmpty) byId[sid] = r.status?.toString() ?? 'Present';
      }
    }

    _attendanceMap.clear();
    for (final s in students) {
      final id = s['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      _attendanceMap[id] = byId[id] ?? 'Present';
    }
    _loadedForDate = key;
  }

  Future<void> _saveAttendance(
    AsyncValue<List<Map<String, dynamic>>> studentsAsync,
    String className,
  ) async {
    final students = studentsAsync.asData?.value ?? const <Map<String, dynamic>>[];
    if (students.isEmpty) return;

    final home = ref.read(teacherHomeroomProvider).asData?.value;
    if (home == null) return;
    // Desktop TeacherAttendance keys the doc by the DISPLAY grade label
    // ("Grade 3", not "3") and raw section, so we reuse those verbatim — writing
    // the canonical form would create a duplicate that never upserts.
    final grade = home.grade.trim();
    final section = home.section.trim();

    setState(() => _saving = true);
    final date = _fmtApiDate(ref.read(selectedDateProvider));
    final nowIso = DateTime.now().toIso8601String();

    // Screen status words → the single-letter mark codes the shared readers use.
    // Desktop maps an "excused"/leave day to L, so Leave → L here too.
    const codeOf = {'Present': 'P', 'Absent': 'A', 'Late': 'L', 'Leave': 'L'};

    try {
      // 1) The source-of-truth per-session document all three roles read.
      //    id: attendance_{grade}_{section}_{date}, marks:{studentId:"P"|"A"|"L"}.
      final marks = <String, String>{};
      for (final s in students) {
        final id = s['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        marks[id] = codeOf[_attendanceMap[id] ?? 'Present'] ?? 'P';
      }
      final taDoc = {
        'id': 'attendance_${grade}_${section}_$date',
        'grade': grade,
        'section': section,
        'date': date,
        'marks': marks,
        'remarks': <String, String>{},
        'period': null,
        'savedAt': nowIso,
      };
      await ApiClient.instance
          .createRecord('TeacherAttendance', taDoc)
          .catchError((_) => <String, dynamic>{});

      // 2) Mirror each student into the flat `attendance` table (backward compat,
      //    exactly as desktop handleSave does). id ATT-STU-{studentId}-{date}.
      for (final s in students) {
        final id = s['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final status = _attendanceMap[id] ?? 'Present';
        final rec = {
          'id': 'ATT-STU-$id-$date',
          'entityId': id,
          'studentId': id,
          'entityType': 'student',
          'name': s['name']?.toString() ?? '',
          'studentName': s['name']?.toString() ?? '',
          'class': className,
          'status': status,
          'date': date,
          'time': '',
          'createdAt': nowIso,
        };
        await ApiClient.instance.createRecord('attendance', rec).catchError((_) => <String, dynamic>{});
      }

      ref.invalidate(attendanceRecordProvider('all'));
      if (!mounted) return;
      setState(() {
        _saving = false;
        _showSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

// ── Attendance Select Circle ─────────────────────────────────────────────────
class _AttendanceSelectChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _AttendanceSelectChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ── Mini Statistic Card Widget ───────────────────────────────────────────────
class _StatCountCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  const _StatCountCard({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
