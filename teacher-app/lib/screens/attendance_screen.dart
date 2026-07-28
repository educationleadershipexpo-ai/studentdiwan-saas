import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  int _filterTab = 0; // 0 = By Class, 1 = By Date
  String _searchQuery = '';
  final Map<String, String> _attendanceMap = {}; // studentId -> status (Present, Absent, Late, Leave)
  bool _saving = false;
  bool _showSuccess = false;

  @override
  Widget build(BuildContext context) {
    final selectedClass = ref.watch(selectedClassProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    if (selectedClass == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.class_outlined, size: 64, color: AppColors.text3),
              const SizedBox(height: 16),
              Text('No class selected', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
              const SizedBox(height: 8),
              const Text('Please select a class from the Classes screen first.', style: TextStyle(color: AppColors.text3), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    final studentsAsync = ref.watch(studentsProvider(selectedClass.id));

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // ── Gradient Header ──────────────────────────────────────────
              AppHeader(
                title: 'Attendance Tracker',
                subtitle: '${selectedClass.name} · ${selectedClass.subject}',
                showBackButton: true,
              ),
              const SizedBox(height: 16),

              // ── Tab Filters ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _filterTab = 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _filterTab == 0 ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'By Class',
                              style: TextStyle(
                                color: _filterTab == 0 ? Colors.white : AppColors.text2,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _filterTab = 1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _filterTab == 1 ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'By Date',
                              style: TextStyle(
                                color: _filterTab == 1 ? Colors.white : AppColors.text2,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Container(),
                data: (students) {
                  // Default all students to Present (no pre-seeded overrides)
                  for (var s in students) {
                    _attendanceMap.putIfAbsent(s.id, () => 'Present');
                  }

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
                        .where((s) => s.fullName.toLowerCase().contains(_searchQuery))
                        .toList();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final status = _attendanceMap[item.id] ?? 'Present';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                              Text(
                                '${index + 1}',
                                style: context.bodySmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryExtraLight,
                                child: Text(item.initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(item.fullName, style: context.body.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              // Custom mini selector chips
                              Row(
                                children: [
                                  _AttendanceSelectChip(
                                    label: 'P',
                                    active: status == 'Present',
                                    color: AppColors.green,
                                    onTap: () => setState(() => _attendanceMap[item.id] = 'Present'),
                                  ),
                                  const SizedBox(width: 4),
                                  _AttendanceSelectChip(
                                    label: 'A',
                                    active: status == 'Absent',
                                    color: AppColors.red,
                                    onTap: () => setState(() => _attendanceMap[item.id] = 'Absent'),
                                  ),
                                  const SizedBox(width: 4),
                                  _AttendanceSelectChip(
                                    label: 'L',
                                    active: status == 'Late',
                                    color: AppColors.orange,
                                    onTap: () => setState(() => _attendanceMap[item.id] = 'Late'),
                                  ),
                                  const SizedBox(width: 4),
                                  _AttendanceSelectChip(
                                    label: 'LV',
                                    active: status == 'Leave',
                                    color: AppColors.blue,
                                    onTap: () => setState(() => _attendanceMap[item.id] = 'Leave'),
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
                    onPressed: _saving ? null : _saveAttendance,
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
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_showSuccess)
            Container(
              color: Colors.white,
              child: SuccessCheckmark(
                title: 'Attendance Saved!',
                onComplete: () {
                  setState(() => _showSuccess = false);
                  context.pop(); // return to previous screen
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveAttendance() async {
    final selectedClass = ref.read(selectedClassProvider);
    if (selectedClass == null) return;
    final selectedDate = ref.read(selectedDateProvider);
    final teacherUser = ref.read(authProvider).user;

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final nowStr = DateFormat('hh:mm a').format(DateTime.now());
    final createdAt = DateTime.now().toUtc().toIso8601String();

    setState(() => _saving = true);

    try {
      final studentsAsync = ref.read(studentsProvider(selectedClass.id));
      final List<StudentModel> studentList = studentsAsync.value ?? [];
      
      final List<StudentModel> students = studentList.isNotEmpty 
          ? studentList 
          : await ref.read(studentsProvider(selectedClass.id).future);

      // Build marks map for composite TeacherAttendance record
      final Map<String, String> marksMap = {};
      for (final student in students) {
        final status = _attendanceMap[student.id] ?? 'Present';
        marksMap[student.id] = status == 'Present' ? 'P' : status == 'Absent' ? 'A' : status == 'Late' ? 'L' : 'LV';
      }

      // Write composite TeacherAttendance record (matches web app format)
      final compositeId = 'attendance_${selectedClass.grade.replaceAll(' ', '').toLowerCase()}_${selectedClass.section.toLowerCase()}_$dateStr';
      await ApiClient.instance.createRecord('TeacherAttendance', {
        'id': compositeId,
        'grade': selectedClass.grade,
        'section': selectedClass.section,
        'date': dateStr,
        'marks': marksMap,
        'period': null,
        'savedAt': createdAt,
        'uid': teacherUser?.uid ?? '',
      });

      // Mirror each student into the flat attendance table (read by student portal)
      for (final student in students) {
        final status = _attendanceMap[student.id] ?? 'Present';
        final recordId = 'ATT-STU-${student.id}-$dateStr';
        await ApiClient.instance.createRecord('AttendanceRecord', {
          'id': recordId,
          'entityId': student.id,
          'entityType': 'student',
          'name': student.fullName,
          'class': selectedClass.name,
          'status': status,
          'date': dateStr,
          'time': nowStr,
          'uid': teacherUser?.uid ?? '',
          'createdAt': createdAt,
        });
      }

      setState(() {
        _saving = false;
        _showSuccess = true;
      });
      
      ref.invalidate(attendanceRecordProvider(selectedClass.id));
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save attendance: $e'), backgroundColor: AppColors.red),
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
