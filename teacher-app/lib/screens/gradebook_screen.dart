import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class GradebookScreen extends ConsumerStatefulWidget {
  const GradebookScreen({super.key});

  @override
  ConsumerState<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends ConsumerState<GradebookScreen> {
  bool _submitting = false;
  bool _submitted = false;

  String _letterGrade(double pct) {
    if (pct >= 95) return 'A+';
    if (pct >= 90) return 'A';
    if (pct >= 85) return 'B+';
    if (pct >= 80) return 'B';
    if (pct >= 75) return 'C+';
    if (pct >= 70) return 'C';
    if (pct >= 65) return 'D+';
    if (pct >= 60) return 'D';
    return 'F';
  }

  Future<void> _submitGradebook(String grade, String section, String subject) async {
    setState(() => _submitting = true);
    try {
      final auth = ref.read(authProvider);
      final teacherName = auth.user?.displayName ?? '';
      final now = DateTime.now().toUtc().toIso8601String();
      final id = 'gbsub_${grade.replaceAll(' ', '')}_${section}_FinalTerm';
      await ApiClient.instance.createRecord('GradebookSubmission', {
        'id': id,
        'grade': grade,
        'section': section,
        'subject': subject,
        'term': 'Final Term',
        'status': 'Submitted to Class Teacher',
        'subjectTeacherName': teacherName,
        'history': [{'at': now, 'by': teacherName, 'action': 'Submitted to Class Teacher'}],
        'uid': auth.user?.uid ?? '',
        'createdAt': now,
        'updatedAt': now,
      });
      setState(() { _submitting = false; _submitted = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grades submitted to Class Teacher for approval.'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedClass = ref.watch(selectedClassProvider);

    if (selectedClass == null) {
      return Scaffold(
        body: Column(
          children: [
            const AppHeader(title: 'Gradebook Overview', subtitle: 'Auto-calculate marks & submit overall grades', showBackButton: true),
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.class_outlined, size: 64, color: AppColors.text3),
                      SizedBox(height: 16),
                      Text('No class selected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
                      SizedBox(height: 8),
                      Text('Select a class from the Classes screen to view gradebook.', style: TextStyle(color: AppColors.text3), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final marksAsync = ref.watch(examMarksListProvider(selectedClass.id));

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Gradebook Overview',
            subtitle: '${selectedClass.name} · ${selectedClass.subject}',
            showBackButton: true,
            trailing: _submitted
                ? const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 28)
                : null,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: marksAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonLoader(width: double.infinity, height: 70),
                ),
              ),
              error: (err, _) => Center(child: Text('Error loading marks: $err')),
              data: (marks) {
                if (marks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grade_outlined, size: 64, color: AppColors.text3),
                          SizedBox(height: 16),
                          Text('No exam marks recorded', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
                          SizedBox(height: 8),
                          Text('Enter marks through the Exams section or admin panel to see the gradebook.', style: TextStyle(color: AppColors.text3), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                // Group by student
                final Map<String, List<ExamMarkModel>> byStudent = {};
                for (final m in marks) {
                  final key = m.studentId.isNotEmpty ? m.studentId : m.studentName;
                  byStudent.putIfAbsent(key, () => []).add(m);
                }

                // Compute per-student averages
                final studentRows = byStudent.entries.map((e) {
                  final name = e.value.first.studentName;
                  final scores = e.value.map((m) => m.maxMarks > 0 ? (m.marks / m.maxMarks) * 100 : 0.0).toList();
                  final avg = scores.reduce((a, b) => a + b) / scores.length;
                  return {'name': name, 'avg': avg, 'letter': _letterGrade(avg), 'count': e.value.length};
                }).toList()
                  ..sort((a, b) => (b['avg'] as double).compareTo(a['avg'] as double));

                final avgAll = studentRows.map((r) => r['avg'] as double).reduce((a, b) => a + b) / studentRows.length;
                final highest = (studentRows.first['avg'] as double);
                final passCount = studentRows.where((r) => (r['avg'] as double) >= 60).length;

                return Column(
                  children: [
                    // Stats ring row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(child: _ProgressRingCard(title: 'Class Avg', percentage: avgAll / 100, color: AppColors.primary)),
                          const SizedBox(width: 12),
                          Expanded(child: _ProgressRingCard(title: 'Highest', percentage: highest / 100, color: AppColors.green)),
                          const SizedBox(width: 12),
                          Expanded(child: _ProgressRingCard(
                            title: 'Pass Rate',
                            percentage: studentRows.isEmpty ? 0 : passCount / studentRows.length,
                            color: AppColors.orange,
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toolbar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Student Grades (${marks.length})', style: context.heading2),
                          if (!_submitted)
                            ElevatedButton.icon(
                              onPressed: _submitting ? null : () => _submitGradebook(
                                selectedClass.grade,
                                selectedClass.section,
                                selectedClass.subject,
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                backgroundColor: AppColors.primary,
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: _submitting
                                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                                  : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                              label: Text(
                                _submitting ? 'Submitting...' : 'Submit',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
                                SizedBox(width: 6),
                                Text('Submitted', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Student list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => ref.invalidate(examMarksListProvider(selectedClass.id)),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: studentRows.length,
                          itemBuilder: (context, index) {
                            final student = studentRows[index];
                            final avg = student['avg'] as double;
                            final letter = student['letter'] as String;
                            final isPass = avg >= 60;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryExtraLight),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(student['name'] as String, style: context.heading3),
                                      const SizedBox(height: 4),
                                      Text('${student['count']} exam${(student['count'] as int) == 1 ? '' : 's'}', style: context.bodySmall),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${avg.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isPass ? AppColors.green : AppColors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    width: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isPass ? AppColors.primaryExtraLight : AppColors.redLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      letter,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isPass ? AppColors.primary : AppColors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingCard extends StatelessWidget {
  final String title;
  final double percentage;
  final Color color;

  const _ProgressRingCard({required this.title, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      child: Column(
        children: [
          Text(title, style: context.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: CircularProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  strokeWidth: 5,
                  backgroundColor: color.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
