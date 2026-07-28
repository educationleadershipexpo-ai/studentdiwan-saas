import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class AssessmentsScreen extends ConsumerWidget {
  const AssessmentsScreen({super.key});

  int _questionCount(Map<String, dynamic> item) {
    final q = item['questions'];
    if (q is List) return q.length;
    if (q is num) return q.toInt();
    return int.tryParse('${q ?? ''}') ?? 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherAssessmentsProvider);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Assessments',
            subtitle: 'Quizzes and tests from the Question Bank',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
              onPressed: () => context.push('/teacher/create-assessment'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => _errorState(e.toString(), () => ref.invalidate(teacherAssessmentsProvider)),
              data: (assessments) {
                if (assessments.isEmpty) return _emptyState();
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(teacherAssessmentsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: assessments.length,
                    itemBuilder: (context, index) {
                      final item = assessments[index];
                      final status = (item['status'] ?? 'Draft').toString();
                      final isDraft = status.toLowerCase() == 'draft';
                      final isActive = status.toLowerCase() == 'active' || status.toLowerCase() == 'published';
                      final title = (item['title'] ?? 'Untitled').toString();
                      final subject = (item['subject'] ?? '').toString();
                      final grade = (item['grade'] ?? '').toString();
                      final section = (item['section'] ?? '').toString();
                      final gradeSec = [grade, if (section.isNotEmpty) section].where((s) => s.isNotEmpty).join(' - ');
                      final qCount = _questionCount(item);
                      final duration = item['duration'];
                      final durText = duration == null ? '' : '$duration mins';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primaryExtraLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDraft ? Colors.grey[100] : AppColors.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.quiz_rounded,
                                color: isDraft ? Colors.grey : AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: context.heading3),
                                  const SizedBox(height: 2),
                                  Text(
                                    [subject, gradeSec].where((s) => s.isNotEmpty).join(' · '),
                                    style: context.bodySmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [if (qCount > 0) '$qCount Questions', if (durText.isNotEmpty) durText].join(' · '),
                                    style: context.bodySmall.copyWith(color: AppColors.text3),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              label: status,
                              textColor: isActive ? AppColors.green : (isDraft ? Colors.grey[700]! : AppColors.orange),
                              bgColor: isActive ? AppColors.greenLight : (isDraft ? Colors.grey[200]! : AppColors.orange.withOpacity(0.12)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.quiz_outlined, size: 56, color: AppColors.text3),
            const SizedBox(height: 12),
            Text('No assessments yet', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
            const SizedBox(height: 6),
            Text('Create an assessment to get started.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.red),
            const SizedBox(height: 12),
            Text('Could not load assessments', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
            const SizedBox(height: 6),
            Text(msg, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Create Assessment Screen ─────────────────────────────────────────────────
class CreateAssessmentScreen extends ConsumerStatefulWidget {
  const CreateAssessmentScreen({super.key});

  @override
  ConsumerState<CreateAssessmentScreen> createState() => _CreateAssessmentScreenState();
}

class _CreateAssessmentScreenState extends ConsumerState<CreateAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalMarksController = TextEditingController(text: '20');

  String? _selectedClass; // "Grade 3 - B"
  String? _selectedSubject;
  String _type = 'Quiz';
  int _duration = 30; // mins

  bool _saving = false;
  bool _success = false;

  Future<void> _publishQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class and subject'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Split "Grade 3 - B" back into grade + section for backend scoping.
    final parts = _selectedClass!.split(' - ');
    final grade = parts.isNotEmpty ? parts[0].trim() : '';
    final section = parts.length > 1 ? parts[1].trim() : '';

    setState(() => _saving = true);
    try {
      await ApiClient.instance.createRecord('assessments', {
        'title': _titleController.text.trim(),
        'type': _type,
        'grade': grade,
        'section': section,
        'subject': _selectedSubject,
        'duration': _duration,
        'totalMarks': int.tryParse(_totalMarksController.text.trim()) ?? 0,
        'questions': <dynamic>[],
        'submissions': 0,
        'totalStudents': 0,
        'status': 'Draft',
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      setState(() {
        _saving = false;
        _success = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalMarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const AppHeader(
                title: 'New Assessment',
                subtitle: 'Create a quiz or test for one of your classes',
                showBackButton: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Real class + subject list (teacher's own grade-section pairs).
                        Consumer(
                          builder: (context, ref, _) {
                            final classesAsync = ref.watch(myClassesProvider);
                            return classesAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Could not load your classes: $e',
                                  style: const TextStyle(color: AppColors.red, fontSize: 12)),
                              data: (classes) {
                                final classLabels = classes
                                    .map((c) => '${c['grade']} - ${c['section']}')
                                    .toList();
                                final subjects = <String>{};
                                for (final c in classes) {
                                  for (final s in (c['subjects'] as List<String>? ?? const [])) {
                                    subjects.add(s);
                                  }
                                }
                                final subjectList = subjects.toList();
                                if (classLabels.isNotEmpty && _selectedClass == null) {
                                  _selectedClass = classLabels.first;
                                }
                                if (subjectList.isNotEmpty && _selectedSubject == null) {
                                  _selectedSubject = subjectList.first;
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: classLabels.contains(_selectedClass) ? _selectedClass : null,
                                      decoration: const InputDecoration(labelText: 'Class'),
                                      items: classLabels
                                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                          .toList(),
                                      onChanged: (val) => setState(() => _selectedClass = val),
                                    ),
                                    const SizedBox(height: 20),
                                    DropdownButtonFormField<String>(
                                      value: subjectList.contains(_selectedSubject) ? _selectedSubject : null,
                                      decoration: const InputDecoration(labelText: 'Subject'),
                                      items: subjectList
                                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                          .toList(),
                                      onChanged: (val) => setState(() => _selectedSubject = val),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<String>(
                          value: _type,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: ['Quiz', 'Test', 'Formative', 'Summative']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) => setState(() => _type = val!),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Assessment Title',
                            hintText: 'e.g. Algebra Formative Quiz',
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _totalMarksController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Marks',
                            hintText: 'e.g. 20',
                          ),
                          validator: (val) =>
                              (int.tryParse(val?.trim() ?? '') ?? 0) <= 0 ? 'Enter total marks' : null,
                        ),
                        const SizedBox(height: 20),

                        // Duration timer
                        const Text('Duration (Minutes)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text2)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: AppColors.primary),
                            Expanded(
                              child: Slider(
                                value: _duration.toDouble(),
                                min: 10,
                                max: 120,
                                divisions: 11,
                                label: '$_duration min',
                                onChanged: (val) => setState(() => _duration = val.toInt()),
                              ),
                            ),
                            Text('$_duration mins', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Saved as a draft. Add questions from the desktop portal before publishing to students.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3),
                        ),
                        const SizedBox(height: 36),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _publishQuiz,
                            child: _saving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Save Assessment'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
          if (_success)
            Container(
              color: context.cardColor,
              child: SuccessCheckmark(
                title: 'Assessment Saved!',
                onComplete: () {
                  setState(() => _success = false);
                  ref.invalidate(teacherAssessmentsProvider);
                  context.pop();
                },
              ),
            ),
        ],
      ),
    );
  }
}
