import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
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
              onPressed: () => context.push('/teacher/upload-material'),
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
                        color: context.cardColor,
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
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete material?'),
                                  content: Text('Remove "${item.title}" from the student portal?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: AppColors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              try {
                                await ApiClient.instance.deleteRecord('study_materials', item.id);
                                if (!context.mounted) return;
                                ref.invalidate(teacherMaterialsProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Material deleted.')),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete: $e')),
                                );
                              }
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
  final _linkController = TextEditingController();

  String? _selectedClass; // "Grade 3 - B"
  String? _selectedSubject;
  String _materialType = 'PDF';

  // Real picked file (mutually exclusive alternative to a plain URL link).
  PlatformFile? _pickedFile;
  bool _uploadingFile = false;

  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _chapterController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'ppt', 'pptx', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected file.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() {
      _pickedFile = file;
      // Auto-detect material type from extension.
      final ext = (file.extension ?? '').toLowerCase();
      if (ext == 'pdf') {
        _materialType = 'PDF';
      } else if (ext == 'ppt' || ext == 'pptx') {
        _materialType = 'PPTX';
      } else if (ext == 'doc' || ext == 'docx') {
        _materialType = 'DOCX';
      }
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = file.name;
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

  Future<void> _uploadMaterial() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class and subject'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final hasFile = _pickedFile != null && _pickedFile!.bytes != null;
    final hasLink = _linkController.text.trim().isNotEmpty;
    if (!hasFile && !hasLink) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach a PDF/PPT file or provide a resource link'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Split "Grade 3 - B" back into grade + section for backend scoping.
    final parts = _selectedClass!.split(' - ');
    final grade = parts.isNotEmpty ? parts[0].trim() : '';
    final section = parts.length > 1 ? parts[1].trim() : '';

    setState(() => _submitting = true);
    try {
      // Upload the picked file (if any) to the server and use its stored URL.
      String url = _linkController.text.trim();
      if (hasFile) {
        setState(() => _uploadingFile = true);
        final file = _pickedFile!;
        final mime = _mimeForExtension(file.extension);
        final dataUrl = 'data:$mime;base64,${base64Encode(file.bytes!)}';
        url = await ApiClient.instance.uploadFile(file.name, dataUrl);
        if (mounted) setState(() => _uploadingFile = false);
      }

      await ApiClient.instance.createRecord('study_materials', {
        'title': _titleController.text.trim(),
        'chapter': _chapterController.text.trim(),
        'grade': grade,
        'section': section,
        'subject': _selectedSubject,
        'type': _materialType,
        'url': url,
        'fileUrl': url,
        'fileName': hasFile ? _pickedFile!.name : '',
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Study material published to the student portal.'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.invalidate(teacherMaterialsProvider);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _uploadingFile = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $e'), behavior: SnackBarBehavior.floating),
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
            subtitle: 'Upload a PDF/PPT file or share a link with one of your classes',
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
                      items: ['PDF', 'PPTX', 'DOCX', 'XLSX', 'MP4', 'Link']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setState(() => _materialType = val!),
                    ),
                    const SizedBox(height: 20),

                    // ── File attachment (PDF / PPT / DOC / XLS / image) ─────────
                    Text('Attach File', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text2)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _submitting ? null : _pickFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _pickedFile != null ? AppColors.primary : AppColors.primaryExtraLight,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _pickedFile != null ? Icons.description_rounded : Icons.upload_file_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFile != null ? _pickedFile!.name : 'Choose a PDF, PPT, DOC, XLS or image',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1),
                                  ),
                                  if (_pickedFile != null)
                                    Text(
                                      '${((_pickedFile!.size) / 1024).toStringAsFixed(0)} KB',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3),
                                    ),
                                ],
                              ),
                            ),
                            if (_pickedFile != null)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.red),
                                onPressed: _submitting ? null : () => setState(() {
                                  _pickedFile = null;
                                }),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _linkController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Resource Link (optional)',
                        hintText: 'https://… (used if no file is attached)',
                      ),
                    ),
                    const SizedBox(height: 36),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _uploadMaterial,
                        child: _submitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                  const SizedBox(width: 12),
                                  Text(_uploadingFile ? 'Uploading file…' : 'Publishing…'),
                                ],
                              )
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
