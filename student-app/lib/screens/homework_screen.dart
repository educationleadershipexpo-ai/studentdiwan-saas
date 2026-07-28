import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// Live homework for the logged-in student. Completion is derived from the
// student's real HomeworkSubmission rows (studentHomeworkSubmissionsProvider),
// and "Submit" writes a real HomeworkSubmission — no fabricated progress bar.
class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({super.key});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  int _selectedTab = 0; // 0 = Pending, 1 = Completed
  String? _expandedHomeworkId;

  @override
  Widget build(BuildContext context) {
    final homeworkAsync = ref.watch(studentHomeworkProvider);
    final submittedIds = ref.watch(studentHomeworkSubmissionsProvider).value ?? <String>{};

    return Scaffold(
      body: Column(
        children: [
          // Header
          const AppHeader(
            title: 'Homework & Tasks',
            subtitle: 'Track your daily homework assignments and submit your work',
            showBackButton: true,
          ),
          const SizedBox(height: 16),

          // Tabs
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
                  _tab('Pending', 0),
                  _tab('Completed', 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: homeworkAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonLoader(width: double.infinity, height: 75),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (list) {
                final filtered = list.where((item) {
                  final done = submittedIds.contains(item.id) || item.isCompleted;
                  return done == (_selectedTab == 1);
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(studentHomeworkProvider);
                      ref.invalidate(studentHomeworkSubmissionsProvider);
                    },
                    child: ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                        Center(
                          child: Text(
                            _selectedTab == 0
                                ? 'Hooray! No pending homework.'
                                : 'No completed homework yet.',
                            style: const TextStyle(color: AppColors.text3),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(studentHomeworkProvider);
                    ref.invalidate(studentHomeworkSubmissionsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isExpanded = _expandedHomeworkId == item.id;
                      final isDone = submittedIds.contains(item.id) || item.isCompleted;
                      final priorityColor = _getPriorityColor(item.priority);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primaryExtraLight, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isDone ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                                  color: priorityColor,
                                ),
                              ),
                              title: Text(item.title, style: context.heading3.copyWith(fontSize: 14.5)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Due: ${item.dueDate}', style: context.bodySmall),
                                  Text(item.subject,
                                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              trailing: StatusChip(
                                label: item.priority,
                                textColor: priorityColor,
                                bgColor: priorityColor.withOpacity(0.08),
                              ),
                              onTap: () {
                                setState(() {
                                  _expandedHomeworkId = isExpanded ? null : item.id;
                                });
                              },
                            ),
                            if (isExpanded) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Instructions:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text1),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.instructions.isEmpty ? 'No instructions provided.' : item.instructions,
                                      style: const TextStyle(fontSize: 13, color: AppColors.text2),
                                    ),
                                    const SizedBox(height: 16),
                                    if (isDone)
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.green.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Submitted ✓',
                                          style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _openSubmitSheet(item),
                                          icon: const Icon(Icons.send_rounded, size: 16),
                                          label: const Text('Submit your work'),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            ]
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

  Widget _tab(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text2,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSubmitSheet(HomeworkModel homework) async {
    final controller = TextEditingController();
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(homework.title, style: sheetContext.heading2),
                  const SizedBox(height: 2),
                  Text(homework.subject,
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Your answer',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text1)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    minLines: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type your homework answer here...',
                      filled: true,
                      fillColor: context.bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (controller.text.trim().isEmpty) return;
                              setSheet(() => submitting = true);
                              try {
                                await submitHomework(ref,
                                    homeworkId: homework.id, content: controller.text.trim());
                                ref.invalidate(studentHomeworkSubmissionsProvider);
                                if (sheetContext.mounted) Navigator.pop(sheetContext);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Homework submitted successfully')),
                                  );
                                }
                              } catch (e) {
                                setSheet(() => submitting = false);
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(content: Text('Could not submit: $e')),
                                  );
                                }
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.red;
      case 'medium':
        return AppColors.amber;
      default:
        return AppColors.green;
    }
  }
}
