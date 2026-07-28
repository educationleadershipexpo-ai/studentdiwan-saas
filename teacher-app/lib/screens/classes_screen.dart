import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class MyClassesScreen extends ConsumerStatefulWidget {
  const MyClassesScreen({super.key});

  @override
  ConsumerState<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends ConsumerState<MyClassesScreen> {
  int _selectedTab = 0; // 0 = All Classes, 1 = My Subjects
  String? _expandedClassId;

  // Curated list of color indices for class items
  final List<Color> _avatarColors = [
    const Color(0xFF6366F1), // Blue-violet
    const Color(0xFF10B981), // Emerald
    const Color(0xFFEC4899), // Pink
    const Color(0xFFF59E0B), // Orange/Amber
    const Color(0xFF3B82F6), // Blue
  ];

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return Scaffold(
      body: Column(
        children: [
          // ── Gradient App Header ──────────────────────────────────────────
          const AppHeader(
            title: 'My Classes',
            subtitle: 'Manage your classes, students, and curriculum',
            showBackButton: true,
          ),
          const SizedBox(height: 16),

          // ── Tabs ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'All Classes',
                          style: TextStyle(
                            color: _selectedTab == 0 ? Colors.white : AppColors.text2,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'My Subjects',
                          style: TextStyle(
                            color: _selectedTab == 1 ? Colors.white : AppColors.text2,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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

          // ── Classes List ──────────────────────────────────────────────────
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
                final filtered = _selectedTab == 0
                    ? classes
                    : classes.where((c) => c.subject == 'Mathematics').toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isExpanded = _expandedClassId == item.id;
                    final iconColor = _avatarColors[index % _avatarColors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        children: [
                          // Base Class Card
                          InkWell(
                            onTap: () {
                              setState(() {
                                _expandedClassId = isExpanded ? null : item.id;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Subject Class Icon
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: iconColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.group_outlined,
                                      color: iconColor,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: context.heading3),
                                        const SizedBox(height: 4),
                                        Text(item.subject, style: context.bodySmall),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.studentCount} Students',
                                          style: context.bodySmall.copyWith(color: AppColors.text3),
                                        ),
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
                          // Expanded Actions / Students panel
                          if (isExpanded) ...[
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                                        onTap: () {
                                          ref.read(selectedClassProvider.notifier).state = item;
                                          context.push('/attendance');
                                        },
                                      ),
                                      _ClassActionButton(
                                        icon: Icons.assignment_rounded,
                                        label: 'Homework',
                                        color: const Color(0xFFF59E0B),
                                        onTap: () => context.push('/homework'),
                                      ),
                                      _ClassActionButton(
                                        icon: Icons.assessment_rounded,
                                        label: 'Assignments',
                                        color: const Color(0xFF10B981),
                                        onTap: () => context.push('/assignments'),
                                      ),
                                      _ClassActionButton(
                                        icon: Icons.menu_book_rounded,
                                        label: 'Materials',
                                        color: const Color(0xFF3B82F6),
                                        onTap: () => context.push('/study-materials'),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Text(
                                    'Students Roster',
                                    style: context.heading3.copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  // Fetch roster list
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final studentsAsync = ref.watch(studentsProvider(item.id));
                                      return studentsAsync.when(
                                        loading: () => const Center(child: CircularProgressIndicator()),
                                        error: (err, stack) => Text('Error: $err'),
                                        data: (students) {
                                          return ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: students.length > 5 ? 5 : students.length,
                                            itemBuilder: (context, idx) {
                                              final s = students[idx];
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 12,
                                                      backgroundColor: AppColors.primaryExtraLight,
                                                      child: Text(
                                                        s.initials,
                                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(s.fullName, style: context.body.copyWith(fontWeight: FontWeight.w600)),
                                                    const Spacer(),
                                                    Text('Roll #${s.rollNumber}', style: context.bodySmall),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
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
