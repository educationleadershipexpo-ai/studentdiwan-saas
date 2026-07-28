import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({super.key});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  int _selectedFilter = 0; // 0 = All, 1 = Active, 2 = Completed

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(assignmentsListProvider);

    return Scaffold(
      body: Column(
        children: [
          // ── Gradient Header ──────────────────────────────────────────
          AppHeader(
            title: 'Homework List',
            subtitle: 'Monitor and review homework assignments',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
              onPressed: () => context.push('/create-homework'),
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
                  _buildTab('All', 0),
                  _buildTab('Active', 1),
                  _buildTab('Completed', 2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Homework Cards ────────────────────────────────────────────────
          Expanded(
            child: listAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: SkeletonLoader(width: double.infinity, height: 110),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error loading homeworks: $err')),
              data: (items) {
                // Filter items: isHomework = true
                final homeworks = items.where((a) => a.isHomework).toList();

                final filtered = homeworks.where((a) {
                  if (_selectedFilter == 1) {
                    return a.dueDate != null && a.dueDate!.isAfter(DateTime.now());
                  } else if (_selectedFilter == 2) {
                    return a.dueDate != null && a.dueDate!.isBefore(DateTime.now());
                  }
                  return true;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final progress = item.totalCount > 0 ? (item.submittedCount / item.totalCount) : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primaryExtraLight, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.title, style: context.heading3),
                              const Icon(Icons.more_horiz_rounded, color: AppColors.text3),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(item.subject, style: context.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(color: AppColors.text3, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text('Grade 8 - A', style: context.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Due: ${item.dueDate != null ? DateFormat('dd MMM yyyy').format(item.dueDate!) : 'N/A'}',
                                style: context.bodySmall.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${item.submittedCount}/${item.totalCount} Submitted',
                                style: context.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Custom Linear Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.primaryExtraLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 6,
                            ),
                          ),
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

  Widget _buildTab(String title, int index) {
    final active = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = index),
        child: Container(
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: active ? Colors.white : AppColors.text2,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Create Homework Screen ───────────────────────────────────────────────────
class CreateHomeworkScreen extends ConsumerStatefulWidget {
  const CreateHomeworkScreen({super.key});

  @override
  ConsumerState<CreateHomeworkScreen> createState() => _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends ConsumerState<CreateHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  String _selectedClass = 'Grade 8 - A';
  String _selectedSubject = 'Mathematics';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  
  // Attachments simulator
  final List<String> _attachments = [];
  bool _uploading = false;
  double _uploadProgress = 0.0;
  bool _saving = false;
  bool _success = false;

  Future<void> _pickFile() async {
    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    // Simulate progress counting
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) {
        setState(() {
          _uploadProgress = i / 10;
        });
      }
    }

    if (mounted) {
      setState(() {
        _uploading = false;
        _attachments.add('Algebra_worksheet.pdf (1.2 MB)');
      });
    }
  }

  Future<void> _publishHomework() async {
    if (!_formKey.currentState!.validate()) return;

    final teacherUser = ref.read(authProvider).user;
    final parts = _selectedClass.split(' - ');
    final grade = parts.first;
    final section = parts.length > 1 ? parts.last : '';
    final hwId = 'HW-${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _saving = true);

    try {
      final payload = {
        'id': hwId,
        'title': _titleController.text.trim(),
        'subject': _selectedSubject,
        'description': _descController.text.trim(),
        'dueDate': DateFormat('yyyy-MM-dd').format(_dueDate),
        'attachment': _attachments.isNotEmpty ? _attachments.first : '',
        'attachmentUrl': '',
        'grade': grade,
        'section': section,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'uid': teacherUser?.uid ?? 'teacher-uid-mock',
      };

      await ApiClient.instance.createRecord('homework', payload);

      setState(() {
        _saving = false;
        _success = true;
      });
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish homework: $e'), backgroundColor: AppColors.red),
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
                title: 'Create Homework',
                subtitle: 'Assign new coursework tasks to students',
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
                        // Class selector
                        DropdownButtonFormField<String>(
                          value: _selectedClass,
                          decoration: const InputDecoration(labelText: 'Class'),
                          items: ['Grade 8 - A', 'Grade 8 - B', 'Grade 9 - A', 'Grade 7 - B', 'Grade 6 - A']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedClass = val!),
                        ),
                        const SizedBox(height: 20),

                        // Subject selector
                        DropdownButtonFormField<String>(
                          value: _selectedSubject,
                          decoration: const InputDecoration(labelText: 'Subject'),
                          items: ['Mathematics', 'Science', 'English', 'Arabic', 'History']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedSubject = val!),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'e.g. Maths Worksheet',
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 20),

                        // Description
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Please solve all the questions given in the worksheet.',
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter instructions' : null,
                        ),
                        const SizedBox(height: 20),

                        // Due Date Picker
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

                        // Attachment listing
                        const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text2)),
                        const SizedBox(height: 8),
                        if (_uploading) ...[
                          Row(
                            children: [
                              const CircularProgressIndicator(strokeWidth: 2),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Uploading file...', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(value: _uploadProgress),
                                  ],
                                ),
                              )
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
                              leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.red),
                              title: Text(_attachments[idx], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppColors.text3),
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
                          icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                          label: const Text('Upload Document', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 36),

                        // Publish button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _publishHomework,
                            child: _saving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Assign Homework'),
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
                title: 'Homework Assigned!',
                onComplete: () {
                  setState(() => _success = false);
                  // Refresh listings
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
