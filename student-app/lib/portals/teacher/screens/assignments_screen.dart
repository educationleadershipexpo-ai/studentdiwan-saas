import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_client.dart';
import '../providers/data_provider.dart';
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
    final listAsync = ref.watch(teacherAssignmentsListProvider);

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
              onPressed: () => context.push('/teacher/create-assignment'),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tabs ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: context.cardColor,
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
                : _buildSubmissionsReview(ref.watch(teacherSubmissionsReviewProvider)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.text3),
          const SizedBox(height: 12),
          Text(title, style: context.heading3),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: context.bodySmall.copyWith(color: AppColors.text3)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAssignments(AsyncValue<List<Map<String, dynamic>>> asyncVal) {
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
        final assignments = items
            .where((a) => (a['type']?.toString().toLowerCase() ?? '') != 'homework')
            .toList();

        if (assignments.isEmpty) {
          return _emptyState(
            Icons.assignment_outlined,
            'No assignments yet',
            'Assignments you create for your class will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final item = assignments[index];
            final title = item['title']?.toString() ?? 'Untitled';
            final subject = item['subject']?.toString() ?? '';
            final dueRaw = item['dueDate']?.toString() ?? item['due']?.toString();
            DateTime? due;
            if (dueRaw != null && dueRaw.isNotEmpty) {
              due = DateTime.tryParse(dueRaw);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryExtraLight, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(title, style: context.heading3)),
                      StatusChip(
                        label: 'Active',
                        textColor: AppColors.primary,
                        bgColor: AppColors.primaryExtraLight,
                      ),
                    ],
                  ),
                  if (subject.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subject,
                        style: context.bodySmall
                            .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 12),
                  Text('Due: ${due != null ? DateFormat('dd MMM yyyy').format(due) : 'N/A'}',
                      style: context.bodySmall),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubmissionsReview(AsyncValue<List<Map<String, dynamic>>> asyncVal) {
    return asyncVal.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: SkeletonLoader(width: double.infinity, height: 80),
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (submissions) {
        // Rows are the real join of the teacher's assignments against the
        // `assignment_submissions` table (see teacherSubmissionsReviewProvider),
        // matching desktop. With no submissions yet, show a real empty state.
        if (submissions.isEmpty) {
          return _emptyState(
            Icons.rate_review_outlined,
            'No submissions to review',
            'Student submissions for your assignments will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final sub = submissions[index];
            final name = sub['studentName']?.toString() ?? sub['name']?.toString() ?? 'Student';
            final isGraded = sub['status']?.toString().toLowerCase() == 'graded' ||
                sub['score'] != null;
            final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
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
                    child: Text(initials,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: context.heading3),
                        if (sub['submittedAt'] != null) ...[
                          const SizedBox(height: 2),
                          Text('Submitted ${sub['submittedAt']}', style: context.bodySmall),
                        ],
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
                      child: Text('${sub['score']}',
                          style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
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
                      child: const Text('Grade',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            );
          },
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
class GradeSubmissionSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> submission;
  const GradeSubmissionSheet({super.key, required this.submission});

  @override
  ConsumerState<GradeSubmissionSheet> createState() => _GradeSubmissionSheetState();
}

class _GradeSubmissionSheetState extends ConsumerState<GradeSubmissionSheet> with SingleTickerProviderStateMixin {
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

    final submissionId = widget.submission['id']?.toString();
    if (submissionId == null || submissionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot locate this submission to grade'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // Persist the grade directly onto the real submission record in the
      // `assignment_submissions` table — the same table desktop grades against.
      await ApiClient.instance.updateRecord('assignment_submissions', submissionId, {
        'marks': int.tryParse(scoreText) ?? scoreText,
        'feedback': _feedbackController.text.trim(),
        'status': 'graded',
        'gradedAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ref.invalidate(teacherSubmissionsReviewProvider);
      setState(() {
        _submitting = false;
        _showReveal = true;
      });
      _revealController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save grade: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.submission['name'];

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
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
                              color: context.cardColor,
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
                  Text('Reviewing $name\'s submission', style: context.bodySmall),
                  const SizedBox(height: 20),

                  // Submitted Document Tile — shows the real uploaded file, or
                  // an honest "no file" state. Never a fabricated filename.
                  Builder(builder: (context) {
                    final file = (widget.submission['file'] ?? '').toString().trim();
                    final hasFile = file.isNotEmpty;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryExtraLight),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasFile ? Icons.picture_as_pdf_rounded : Icons.description_outlined,
                            color: hasFile ? AppColors.red : AppColors.text3,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hasFile ? file.split('/').last : 'No file attached',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: hasFile ? AppColors.text1 : AppColors.text3,
                              ),
                            ),
                          ),
                          if (hasFile)
                            const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 20),
                        ],
                      ),
                    );
                  }),
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
  final _totalMarksController = TextEditingController(text: '100');
  final _passingController = TextEditingController(text: '40');
  final _linkController = TextEditingController();

  // Desktop /teacher/assignments/new parity.
  static const _assignmentTypes = ['Homework', 'Project', 'Lab Work', 'Essay', 'Presentation', 'Quiz', 'Worksheet'];
  static const _submissionTypes = ['File Upload', 'Text Entry', 'Offline / In-class'];

  String? _selectedClass; // "Grade 3 - B"
  String? _selectedSubject;
  String _assignmentType = 'Homework';
  String _submissionType = 'File Upload';
  DateTime _assignDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _scheduleEnabled = false;

  // Real attachments picked from the device (uploaded on publish).
  final List<PlatformFile> _attachments = [];

  bool _saving = false;
  bool _success = false;
  String _saveLabel = '';

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _rubricController.dispose();
    _totalMarksController.dispose();
    _passingController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'ppt', 'pptx', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.bytes != null) _attachments.add(f);
      }
    });
  }

  String _mimeForExtension(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'csv':
        return 'text/csv';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _publish({required bool asDraft}) async {
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

    setState(() {
      _saving = true;
      _saveLabel = asDraft ? 'Saving draft…' : 'Publishing…';
    });
    try {
      // Upload any attachments and collect their stored URLs.
      final uploaded = <Map<String, dynamic>>[];
      for (final f in _attachments) {
        setState(() => _saveLabel = 'Uploading ${f.name}…');
        final dataUrl = 'data:${_mimeForExtension(f.extension)};base64,${base64Encode(f.bytes!)}';
        final url = await ApiClient.instance.uploadFile(f.name, dataUrl);
        uploaded.add({'name': f.name, 'url': url});
      }
      if (_linkController.text.trim().isNotEmpty) {
        uploaded.add({'name': 'Resource Link', 'url': _linkController.text.trim()});
      }

      // Status mirrors desktop: Draft, or Upcoming when scheduled ahead, else Active.
      String status = asDraft
          ? 'Draft'
          : (_scheduleEnabled && _assignDate.isAfter(DateTime.now())) ? 'Upcoming' : 'Active';

      await ApiClient.instance.createRecord('TeacherAssignment', {
        'title': _titleController.text.trim(),
        'type': 'assignment',
        'assignmentType': _assignmentType,
        'grade': grade,
        'section': section,
        'subject': _selectedSubject,
        'instructions': _instructionsController.text.trim(),
        'rubric': _rubricController.text.trim(),
        'totalMarks': int.tryParse(_totalMarksController.text.trim()) ?? 100,
        'passingScore': int.tryParse(_passingController.text.trim()) ?? 40,
        'submissionType': _submissionType,
        'attachments': uploaded,
        'assignDate': DateFormat('yyyy-MM-dd').format(_scheduleEnabled ? _assignDate : DateTime.now()),
        'dueDate': DateFormat('yyyy-MM-dd').format(_dueDate),
        'status': status,
        'submissions': <dynamic>[],
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      if (asDraft) {
        setState(() => _saving = false);
        ref.invalidate(teacherAssignmentsListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved as draft'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.green),
        );
        context.pop();
      } else {
        setState(() {
          _saving = false;
          _success = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $e'), behavior: SnackBarBehavior.floating),
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
                        // Real class list (teacher's own grade-section pairs).
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
                                      isExpanded: true,
                                      decoration: const InputDecoration(labelText: 'Class'),
                                      items: classLabels
                                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                          .toList(),
                                      onChanged: (val) => setState(() => _selectedClass = val),
                                    ),
                                    const SizedBox(height: 20),
                                    DropdownButtonFormField<String>(
                                      value: subjectList.contains(_selectedSubject) ? _selectedSubject : null,
                                      isExpanded: true,
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

                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Assignment Title',
                            hintText: 'e.g. Calculus Project 1',
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 20),

                        // Assignment type + submission type
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _assignmentType,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Type'),
                                items: _assignmentTypes
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                    .toList(),
                                onChanged: (v) => setState(() => _assignmentType = v!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _submissionType,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Submission'),
                                items: _submissionTypes
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                    .toList(),
                                onChanged: (v) => setState(() => _submissionType = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Total marks + passing score
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _totalMarksController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Total Marks'),
                                validator: (v) => (int.tryParse(v?.trim() ?? '') == null) ? 'Number' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _passingController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Passing Score'),
                                validator: (v) => (int.tryParse(v?.trim() ?? '') == null) ? 'Number' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _instructionsController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Instructions',
                            hintText: 'Describe the task, rules and score allocation…',
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter instructions' : null,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _rubricController,
                          decoration: const InputDecoration(
                            labelText: 'Grading Rubric (Optional)',
                            hintText: 'e.g. 80% solve accuracy + 20% format layout',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Attachments ───────────────────────────────────────
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Attachments', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text2)),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickAttachments,
                          icon: const Icon(Icons.attach_file_rounded),
                          label: const Text('Add PDF / PPT / DOC files'),
                        ),
                        if (_attachments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ..._attachments.asMap().entries.map((e) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primaryExtraLight),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.insert_drive_file_rounded, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(e.value.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                                    InkWell(
                                      onTap: _saving ? null : () => setState(() => _attachments.removeAt(e.key)),
                                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.red),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _linkController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Resource Link (Optional)',
                            hintText: 'https://…',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Schedule toggle + assign date ─────────────────────
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _scheduleEnabled,
                          activeColor: AppColors.primary,
                          title: const Text('Schedule for later', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Publish on a future assign date', style: TextStyle(fontSize: 12)),
                          onChanged: (v) => setState(() => _scheduleEnabled = v),
                        ),
                        if (_scheduleEnabled) ...[
                          const SizedBox(height: 8),
                          _dateTile(
                            label: 'Assign Date',
                            date: _assignDate,
                            onPick: (d) => setState(() => _assignDate = d),
                            first: DateTime.now(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        _dateTile(
                          label: 'Due Date',
                          date: _dueDate,
                          onPick: (d) => setState(() => _dueDate = d),
                          first: DateTime.now(),
                        ),
                        const SizedBox(height: 32),

                        // ── Actions: Save Draft + Publish ─────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _saving ? null : () => _publish(asDraft: true),
                                  child: const Text('Save Draft'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : () => _publish(asDraft: false),
                                  child: _saving
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                            const SizedBox(width: 10),
                                            Flexible(child: Text(_saveLabel, overflow: TextOverflow.ellipsis)),
                                          ],
                                        )
                                      : const Text('Publish Assignment'),
                                ),
                              ),
                            ),
                          ],
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
                title: 'Assignment Published!',
                onComplete: () {
                  setState(() => _success = false);
                  ref.invalidate(teacherAssignmentsListProvider);
                  context.pop();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onPick,
    required DateTime first,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: first,
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPick(picked);
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
                Text(label, style: const TextStyle(color: AppColors.text2, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateFormat('dd MMMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
