import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart' show CustomBottomBar, QuickActionsBottomSheet;

String _canonGrade(String? g) =>
    (g ?? '').trim().toLowerCase().replaceFirst(RegExp(r'^grade\s*'), '').replaceAll(RegExp(r'\s+'), '');
String _canonSection(String? s) =>
    (s ?? '').trim().toUpperCase().replaceFirst(RegExp(r'^SECTION\s*'), '').trim();

String _gradeLabel(dynamic g) {
  final raw = (g ?? '').toString().trim();
  if (raw.isEmpty) return 'Grade';
  final stripped = raw.replaceFirst(RegExp(r'^grade\s*', caseSensitive: false), '');
  return 'Grade $stripped';
}

class MyClassesScreen extends ConsumerStatefulWidget {
  const MyClassesScreen({super.key});

  @override
  ConsumerState<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends ConsumerState<MyClassesScreen> {
  String? _expandedClassId;

  final List<Color> _avatarColors = [
    const Color(0xFF6366F1),
    const Color(0xFF10B981),
    const Color(0xFFEC4899),
    const Color(0xFFF59E0B),
    const Color(0xFF3B82F6),
  ];

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(myClassesProvider);
    final studentsAsync = ref.watch(allStudentsProvider);

    return Scaffold(
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: 1,
        onTap: (i) {
          if (i == 0) context.go('/teacher/dashboard');
          if (i == 3) context.go('/teacher/calendar');
          if (i == 4) context.go('/teacher/profile');
        },
        onFabPressed: () => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const QuickActionsBottomSheet(),
        ),
      ),
      body: Column(
        children: [
          const AppHeader(
            title: 'My Classes',
            subtitle: 'Manage your classes, students, and curriculum',
            showBackButton: true,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: classesAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 4,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: SkeletonLoader(width: double.infinity, height: 95),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error loading classes: $err')),
              data: (classes) {
                if (classes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group_outlined, size: 48, color: AppColors.text3),
                        const SizedBox(height: 12),
                        Text('No classes assigned', style: context.heading3),
                        const SizedBox(height: 4),
                        Text('You have no classes assigned to you yet.',
                            style: context.bodySmall.copyWith(color: AppColors.text3)),
                      ],
                    ),
                  );
                }
                final allStudents = studentsAsync.asData?.value ?? const <Map<String, dynamic>>[];
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    final grade = cls['grade']?.toString() ?? '';
                    final section = cls['section']?.toString() ?? '';
                    final subjects = (cls['subjects'] as List?)?.cast<String>() ?? const [];
                    final classId = '${_canonGrade(grade)}-${_canonSection(section)}';
                    final name = '${_gradeLabel(grade)} - ${_canonSection(section)}';
                    final subjectLabel = subjects.isEmpty ? 'General' : subjects.join(', ');

                    final roster = allStudents
                        .where((s) =>
                            _canonGrade(s['grade']?.toString()) == _canonGrade(grade) &&
                            _canonSection(s['section']?.toString()) == _canonSection(section))
                        .toList();

                    final isExpanded = _expandedClassId == classId;
                    final iconColor = _avatarColors[index % _avatarColors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _expandedClassId = isExpanded ? null : classId),
                            borderRadius: BorderRadius.circular(16),
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: iconColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.group_outlined, color: iconColor, size: 26),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: context.heading3),
                                        const SizedBox(height: 4),
                                        Text(subjectLabel, style: context.bodySmall),
                                        const SizedBox(height: 2),
                                        Text('${roster.length} Students',
                                            style: context.bodySmall.copyWith(color: AppColors.text3)),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                    color: AppColors.text3,
                                    size: 26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryExtraLight, width: 1.5),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _ClassActionButton(
                                        icon: Icons.check_circle_outline_rounded,
                                        label: 'Attendance',
                                        color: const Color(0xFF6366F1),
                                        onTap: () => context.push('/teacher/attendance'),
                                      ),
                                      _ClassActionButton(
                                        icon: Icons.assignment_rounded,
                                        label: 'Homework',
                                        color: const Color(0xFFF59E0B),
                                        onTap: () => context.push('/teacher/homework'),
                                      ),
                                      _ClassActionButton(
                                        icon: Icons.assessment_rounded,
                                        label: 'Assignments',
                                        color: const Color(0xFF10B981),
                                        onTap: () => context.push('/teacher/assignments'),
                                      ),
                                      _ClassActionButton(
                                        icon: Icons.menu_book_rounded,
                                        label: 'Materials',
                                        color: const Color(0xFF3B82F6),
                                        onTap: () => context.push('/teacher/study-materials'),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Text('Students Roster', style: context.heading3.copyWith(fontSize: 14)),
                                  const SizedBox(height: 8),
                                  if (roster.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text('No students in this class yet.',
                                          style: context.bodySmall.copyWith(color: AppColors.text3)),
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: roster.length > 8 ? 8 : roster.length,
                                      itemBuilder: (context, idx) {
                                        final s = roster[idx];
                                        final fullName = s['name']?.toString() ?? 'Unknown';
                                        final initials = fullName.isNotEmpty ? fullName[0] : '?';
                                        final roll =
                                            s['rollNumber']?.toString() ?? s['studentId']?.toString() ?? '';
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: AppColors.primaryExtraLight,
                                                child: Text(initials,
                                                    style: const TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.primary)),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(fullName,
                                                    style: context.body.copyWith(fontWeight: FontWeight.w600)),
                                              ),
                                              if (roll.isNotEmpty)
                                                Text('Roll #$roll', style: context.bodySmall),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  if (roster.length > 8)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text('+ ${roster.length - 8} more',
                                          style: context.bodySmall.copyWith(color: AppColors.text3)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ClassActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.text2),
          ),
        ],
      ),
    );
  }
}
