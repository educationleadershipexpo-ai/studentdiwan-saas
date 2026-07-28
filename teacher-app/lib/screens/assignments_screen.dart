import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../core/api_client.dart';
import '../widgets/common_widgets.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  int _selectedFilter = 0; // 0 = Active, 1 = Submissions Review

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(assignmentsListProvider);

    return Scaffold(
      body: Column(
        children: [
          // ── App Header ────────────────────────────────────────────────
          AppHeader(
            title: 'Assignments',
            subtitle: 'Review student submissions and assign grades',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
              onPressed: () => context.push('/create-assignment'),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tabs ─────────────────────────────────────────────────────────
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
                      onTap: () => setState(() => _selectedFilter = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedFilter == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Active Assignments',
                          style: TextStyle(
                            color: _selectedFilter == 0 ? Colors.white : AppColors.text2,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedFilter == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Submissions Review',
                          style: TextStyle(
                            color: _selectedFilter == 1 ? Colors.white : AppColors.text2,
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

          // ── List Section ──────────────────────────────────────────────────
          Expanded(
            child: _selectedFilter == 0
                ? _buildActiveAssignments(listAsync)
                : _buildSubmissionsReview(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAssignments(AsyncValue<List<AssignmentModel>> asyncVal) {
    return asyncVal.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: SkeletonLoader(width: double.infinity, height: 110),
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (items) {
        final assignments = items.where((a) => !a.isHomework).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final item = assignments[index];
            final ratio = item.submittedCount / item.totalCount;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryExtraLight, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.title, style: context.heading3),
                      StatusChip(
                        label: 'Active',
                        textColor: AppColors.primary,
                        bgColor: AppColors.primaryExtraLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.subject, style: context.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Due: ${item.dueDate != null ? DateFormat('dd MMM yyyy').format(item.dueDate!) : 'N/A'}', style: context.bodySmall),
                      Text('${item.submittedCount}/${item.totalCount} Submitted', style: context.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: AppColors.primaryExtraLight,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubmissionsReview() {
    // Roster of mock submitted students for Grade 8 - A Math Assignment
    final List<Map<String, dynamic>> submissions = [
      {'id': 'sub1', 'name': 'Ahmed Khan', 'roll': '1', 'time': '10 mins ago', 'status': 'Pending', 'file': 'Calculus_sol.pdf'},
      {'id': 'sub2', 'name': 'Ayesha Malik', 'roll': '2', 'time': '2 hours ago', 'status': 'Graded', 'grade': 'A+', 'score': '95'},
      {'id': 'sub3', 'name': 'Bilal Ahmed', 'roll': '3', 'time': 'Yesterday', 'status': 'Pending', 'file': 'Homework1.pdf'},
      {'id': 'sub4', 'name': 'Fatima Noor', 'roll': '4', 'time': '2 days ago', 'status': 'Graded', 'grade': 'A', 'score': '88'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final sub = submissions[index];
        final isGraded = sub['status'] == 'Graded';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryExtraLight,
                child: Text(
                  sub['name'].toString().split(' ')[0][0] + sub['name'].toString().split(' ')[1][0],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub['name'], style: context.heading3),
                    const SizedBox(height: 2),
                    Text('Roll #${sub['roll']} · Submitted ${sub['time']}', style: context.bodySmall),
                  ],
                ),
              ),
              if (isGraded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${sub['score']}% (${sub['grade']})',
                    style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _openGradeSheet(context, sub),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    backgroundColor: AppColors.primary,
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Grade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openGradeSheet(BuildContext context, Map<String, dynamic> submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GradeSubmissionSheet(submission: submission),
    );
  }
}

// ── Grade Submission Sheet Widget ───────────────────────────────────────────
class GradeSubmissionSheet extends StatefulWidget {
  final Map<String, dynamic> submission;
  const GradeSubmissionSheet({super.key, required this.submission});

  @override
  State<GradeSubmissionSheet> createState() => _GradeSubmissionSheetState();
}

class _GradeSubmissionSheetState extends State<GradeSubmissionSheet> with SingleTickerProviderStateMixin {
  final _scoreController = TextEditingController();
  final _feedbackController = TextEditingController();
  
  bool _submitting = false;
  bool _showReveal = false;
  late AnimationController _revealController;
  late Animation<double> _revealScale;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _revealScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _submitGrade() async {
    final scoreText = _scoreController.text.trim();
    if (scoreText.isEmpty) return;

    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _submitting = false;
      _showReveal = true;
    });
    _revealController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.submission['name'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: _showReveal
            ? SizedBox(
                height: 250,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _revealScale,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_scoreController.text}%',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Grade Published!', style: context.heading2),
                      const SizedBox(height: 6),
                      Text('Syllabus marks updated for $name', style: context.bodySmall),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Done'),
                      )
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Grade Submission', style: context.heading2),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Reviewing $name\'s PDF solution', style: context.bodySmall),
                  const SizedBox(height: 20),

                  // Submitted Document Tile
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryExtraLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, color: AppColors.red, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.submission['file'] ?? 'Calculus_sol.pdf',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input marks
                  TextFormField(
                    controller: _scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Award Marks (%)',
                      hintText: 'Enter percentage score (0-100)',
                      prefixIcon: Icon(Icons.percent_rounded, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input feedback comments
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Teacher Comments',
                      hintText: 'Write feedback about details, methodology etc.',
                      prefixIcon: Icon(Icons.comment_outlined, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitGrade,
                      child: _submitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save & Publish Grade'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Create Assignment Screen ─────────────────────────────────────────────────
class CreateAssignmentScreen extends ConsumerStatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  ConsumerState<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends ConsumerState<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _rubricController = TextEditingController();

  String _selectedClass = 'Grade 8 - A';
  String _selectedSubject = 'Mathematics';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  
  bool _uploading = false;
  double _uploadProgress = 0.0;
  final List<String> _attachments = [];
  bool _saving = false;
  bool _success = false;

  Future<void> _pickFile() async {
    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _uploadProgress = i / 10;
        });
      }
    }

    if (mounted) {
      setState(() {
        _uploading = false;
        _attachments.add('Calculus_Assignment_Project.pdf (2.4 MB)');
      });
    }
  }

  Future<void> _publishAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    final teacherUser = ref.read(authProvider).user;
    final asnId = 'ASN-${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _saving = true);

    try {
      final payload = {
        'id': asnId,
        'title': _titleController.text.trim(),
        'description': _instructionsController.text.trim(),
        'dueDate': DateFormat('yyyy-MM-dd').format(_dueDate),
        'classId': _selectedClass,
        'subject': _selectedSubject,
        'status': 'Active',
        'submissionsCount': 0,
        'uid': teacherUser?.uid ?? 'teacher-uid-mock',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };

      await ApiClient.instance.createRecord('assignments', payload);

      setState(() {
        _saving = false;
        _success = true;
      });
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish assignment: $e'), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const AppHeader(
                title: 'Create Assignment',
                subtitle: 'Publish formal term projects or lab tasks',
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
                        DropdownButtonFormField<String>(
                          value: _selectedClass,
                          decoration: const InputDecoration(labelText: 'Class'),
                          items: ['Grade 8 - A', 'Grade 8 - B', 'Grade 9 - A', 'Grade 7 - B', 'Grade 6 - A']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedClass = val!),
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<String>(
                          value: _selectedSubject,
                          decoration: const InputDecoration(labelText: 'Subject'),
                          items: ['Mathematics', 'Science', 'English', 'Arabic', 'History']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedSubject = val!),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Assignment Title',
                            hintText: 'e.g. Calculus Project 1',
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _instructionsController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Instructions & Rubrics Description',
                            hintText: 'Describe rules, scores allocation rules...',
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter instructions' : null,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _rubricController,
                          decoration: const InputDecoration(
                            labelText: 'Grading Rubric Tag (Optional)',
                            hintText: 'e.g. 80% solve accuracy + 20% format layout',
                          ),
                        ),
                        const SizedBox(height: 20),

                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2DCF7), width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Due Date', style: TextStyle(color: AppColors.text2, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('dd MMMM yyyy').format(_dueDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text2)),
                        const SizedBox(height: 8),
                        if (_uploading) ...[
                          Row(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(width: 12),
                              Expanded(child: LinearProgressIndicator(value: _uploadProgress)),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        ...List.generate(
                          _attachments.length,
                          (idx) => Card(
                            color: AppColors.primarySurface,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.file_present_rounded, color: AppColors.primary),
                              title: Text(_attachments[idx], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => setState(() => _attachments.removeAt(idx)),
                              ),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickFile,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                          label: const Text('Add Material Reference', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 36),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _publishAssignment,
                            child: const Text('Publish Assignment'),
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
              color: Colors.white,
              child: SuccessCheckmark(
                title: 'Assignment Published!',
                onComplete: () {
                  setState(() => _success = false);
                  ref.invalidate(assignmentsListProvider);
                  context.pop();
                },
              ),
            ),
        ],
      ),
    );
  }
}
