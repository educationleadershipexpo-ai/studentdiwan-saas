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

class StudyMaterialsScreen extends ConsumerWidget {
  const StudyMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(teacherMaterialsProvider);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Study Materials',
            subtitle: 'Share lectures and documents with your classes',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 28),
              onPressed: () => context.push('/upload-material'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: materialsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 3,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonLoader(width: double.infinity, height: 80),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (list) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isPdf = item.type == 'PDF';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryExtraLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isPdf ? AppColors.redLight : AppColors.amberLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPdf ? Icons.picture_as_pdf_rounded : Icons.slideshow_rounded,
                              color: isPdf ? AppColors.red : AppColors.amber,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: context.heading3),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.subject} · ${item.grade} · ${item.type}',
                                  style: context.bodySmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Shared: ${item.uploadedAt != null ? DateFormat('dd MMM yyyy').format(item.uploadedAt!) : 'Today'}',
                                  style: context.bodySmall.copyWith(color: AppColors.text3),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Material archived successfully.')),
                              );
                            },
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
}

// ── Upload Material Screen ───────────────────────────────────────────────────
class UploadMaterialScreen extends ConsumerStatefulWidget {
  const UploadMaterialScreen({super.key});

  @override
  ConsumerState<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends ConsumerState<UploadMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _chapterController = TextEditingController();

  String _selectedGrade = 'Grade 8';
  String _selectedSubject = 'Mathematics';
  String _materialType = 'PDF';

  bool _pickingFile = false;
  double _uploadProgress = 0.0;
  String? _fileName;
  bool _submitting = false;

  Future<void> _pickMaterialFile() async {
    setState(() {
      _pickingFile = true;
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
        _pickingFile = false;
        _fileName = 'Trigonometry_Ch5_Formulas.pdf (3.1 MB)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File attached successfully!'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uploadMaterial() async {
    if (!_formKey.currentState!.validate() || _fileName == null) {
      if (_fileName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a file first.'), backgroundColor: AppColors.red),
        );
      }
      return;
    }

    final teacherUser = ref.read(authProvider).user;
    final matId = 'MAT-${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _submitting = true);

    try {
      final payload = {
        'id': matId,
        'title': _titleController.text.trim(),
        'subject': _selectedSubject,
        'type': _materialType,
        'link': '/uploads/mock_file.pdf',
        'grade': _selectedGrade,
        'section': 'A',
        'chapter': _chapterController.text.trim(),
        'lesson': '',
        'teacher': teacherUser?.displayName ?? 'Teacher',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'uid': teacherUser?.uid ?? 'teacher-uid-mock',
      };

      await ApiClient.instance.createRecord('studymaterial', payload);

      setState(() => _submitting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Study Material published to Student Portal!'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      ref.invalidate(teacherMaterialsProvider);
      context.pop();
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish material: $e'), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Upload Study Material',
            subtitle: 'Upload files directly to the student portal',
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
                      value: _selectedGrade,
                      decoration: const InputDecoration(labelText: 'Grade Level'),
                      items: ['Grade 6', 'Grade 7', 'Grade 8', 'Grade 9']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedGrade = val!),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: ['Mathematics', 'Science', 'English', 'Arabic']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedSubject = val!),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _chapterController,
                      decoration: const InputDecoration(
                        labelText: 'Chapter Name',
                        hintText: 'e.g. Chapter 5: Trigonometry',
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter chapter name' : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Title',
                        hintText: 'e.g. Formula Cheat Sheet',
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter title' : null,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _materialType,
                      decoration: const InputDecoration(labelText: 'Material Type'),
                      items: ['PDF', 'PPTX', 'DOCX', 'MP4', 'Link']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setState(() => _materialType = val!),
                    ),
                    const SizedBox(height: 24),

                    // Folder open / picking state
                    const Text('File Upload', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text2)),
                    const SizedBox(height: 8),
                    if (_pickingFile) ...[
                      Row(
                        children: [
                          const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Reading files...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(value: _uploadProgress, minHeight: 6),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_fileName != null) ...[
                      Card(
                        color: AppColors.primarySurface,
                        child: ListTile(
                          leading: const Icon(Icons.check_circle_rounded, color: AppColors.green),
                          title: Text(_fileName!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                            onPressed: () => setState(() => _fileName = null),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_fileName == null && !_pickingFile)
                      OutlinedButton.icon(
                        onPressed: _pickMaterialFile,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.folder_open_rounded, color: AppColors.primary),
                        label: const Text('Open Files Folder', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(height: 36),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _uploadMaterial,
                        child: _submitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Publish Study Material'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
