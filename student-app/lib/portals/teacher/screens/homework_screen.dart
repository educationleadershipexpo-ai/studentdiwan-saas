import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_client.dart';
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
    final listAsync = ref.watch(teacherHomeworkProvider);

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
              onPressed: () => context.push('/teacher/create-homework'),
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
                DateTime? due(Map<String, dynamic> a) =>
                    a['dueDate'] != null ? DateTime.tryParse(a['dueDate'].toString()) : null;

                final filtered = items.where((a) {
                  final d = due(a);
                  if (_selectedFilter == 1) {
                    return d != null && d.isAfter(DateTime.now());
                  } else if (_selectedFilter == 2) {
                    return d != null && d.isBefore(DateTime.now());
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assignment_outlined, size: 48, color: AppColors.text3),
                        const SizedBox(height: 12),
                        Text('No homework yet', style: context.heading3),
                        const SizedBox(height: 4),
                        Text('No homework has been assigned to your class.',
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
                    final title = item['title']?.toString() ?? 'Untitled';
                    final subject = item['subject']?.toString() ?? '';
                    final gradeRaw = item['grade']?.toString() ?? '';
                    final section = item['section']?.toString() ?? '';
                    final gradeLabel = gradeRaw.toLowerCase().startsWith('grade')
                        ? gradeRaw
                        : 'Grade $gradeRaw';
                    final classLabel = section.isEmpty ? gradeLabel : '$gradeLabel - $section';
                    final dueDate = due(item);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.cardColor,
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
                              Expanded(child: Text(title, style: context.heading3)),
                              const Icon(Icons.more_horiz_rounded, color: AppColors.text3),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (subject.isNotEmpty) ...[
                                Text(subject,
                                    style: context.bodySmall
                                        .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(color: AppColors.text3, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(classLabel, style: context.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Due: ${dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate) : 'N/A'}',
                            style: context.bodySmall.copyWith(fontWeight: FontWeight.w600),
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
  
  String? _selectedClass; // "Grade 3 - B"
  String? _selectedSubject;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));

  bool _saving = false;
  bool _success = false;

  Future<void> _publishHomework() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class and subject'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final parts = _selectedClass!.split(' - ');
    final grade = parts.isNotEmpty ? parts[0].trim() : '';
    final section = parts.length > 1 ? parts[1].trim() : '';

    setState(() => _saving = true);
    try {
      await ApiClient.instance.createRecord('homework', {
        'title': _titleController.text.trim(),
        'type': 'homework',
        'grade': grade,
        'section': section,
        'subject': _selectedSubject,
        'description': _descController.text.trim(),
        'dueDate': DateFormat('yyyy-MM-dd').format(_dueDate),
        'status': 'Active',
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
        SnackBar(content: Text('Failed to assign: $e'), behavior: SnackBarBehavior.floating),
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
              color: context.cardColor,
              child: SuccessCheckmark(
                title: 'Homework Assigned!',
                onComplete: () {
                  setState(() => _success = false);
                  // Refresh listings
                  ref.invalidate(teacherHomeworkProvider);
                  context.pop();
                },
              ),
            ),
        ],
      ),
    );
  }
}
