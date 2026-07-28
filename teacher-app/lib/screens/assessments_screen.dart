import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../widgets/common_widgets.dart';

class AssessmentsScreen extends ConsumerWidget {
  const AssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock assessments list
    final List<Map<String, dynamic>> assessments = [
      {'id': 'as1', 'title': 'Algebra Term Quiz', 'subject': 'Mathematics', 'grade': 'Grade 8', 'questions': 10, 'duration': '30 mins', 'status': 'Published'},
      {'id': 'as2', 'title': 'Geometry Formative test', 'subject': 'Mathematics', 'grade': 'Grade 8', 'questions': 15, 'duration': '45 mins', 'status': 'Draft'},
      {'id': 'as3', 'title': 'Calculus Final Assessment', 'subject': 'Mathematics', 'grade': 'Grade 9', 'questions': 25, 'duration': '90 mins', 'status': 'Published'},
    ];

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Assessments',
            subtitle: 'Schedule quizzes and tests from Question Bank',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
              onPressed: () => context.push('/create-assessment'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: assessments.length,
              itemBuilder: (context, index) {
                final item = assessments[index];
                final isDraft = item['status'] == 'Draft';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                            Text(item['title'], style: context.heading3),
                            const SizedBox(height: 2),
                            Text(
                              '${item['subject']} · ${item['grade']}',
                              style: context.bodySmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item['questions']} Questions · ${item['duration']}',
                              style: context.bodySmall.copyWith(color: AppColors.text3),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: item['status'],
                        textColor: isDraft ? Colors.grey[700]! : AppColors.green,
                        bgColor: isDraft ? Colors.grey[200]! : AppColors.greenLight,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create Assessment Screen ─────────────────────────────────────────────────
class CreateAssessmentScreen extends StatefulWidget {
  const CreateAssessmentScreen({super.key});

  @override
  State<CreateAssessmentScreen> createState() => _CreateAssessmentScreenState();
}

class _CreateAssessmentScreenState extends State<CreateAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  String _selectedGrade = 'Grade 8';
  int _duration = 30; // mins

  // Mock Question Bank
  final List<Map<String, dynamic>> _questionBank = [
    {'id': 'q1', 'question': 'Solve for x: 3x + 7 = 22', 'type': 'Multiple Choice', 'difficulty': 'Easy', 'selected': false},
    {'id': 'q2', 'question': 'Find the root of quadratic equation x² - 5x + 6 = 0', 'type': 'Multiple Choice', 'difficulty': 'Medium', 'selected': false},
    {'id': 'q3', 'question': 'State and prove Pythagoras theorem.', 'type': 'Subjective', 'difficulty': 'Hard', 'selected': false},
    {'id': 'q4', 'question': 'What is the sum of angles in a hexagon?', 'type': 'Multiple Choice', 'difficulty': 'Easy', 'selected': false},
    {'id': 'q5', 'question': 'Evaluate limit as x approaches 0: sin(x)/x', 'type': 'Multiple Choice', 'difficulty': 'Medium', 'selected': false},
  ];

  bool _saving = false;
  bool _success = false;

  void _toggleQuestion(int index) {
    setState(() {
      _questionBank[index]['selected'] = !_questionBank[index]['selected'];
    });
  }

  Future<void> _publishQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    
    final selectedQuestions = _questionBank.where((q) => q['selected'] == true).toList();
    if (selectedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one question from the bank.'), backgroundColor: AppColors.red),
      );
      return;
    }

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    setState(() {
      _saving = false;
      _success = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _questionBank.where((q) => q['selected'] == true).length;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const AppHeader(
                title: 'New Assessment',
                subtitle: 'Assemble a quiz from the digital question bank',
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
                          decoration: const InputDecoration(labelText: 'Grade'),
                          items: ['Grade 7', 'Grade 8', 'Grade 9']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedGrade = val!),
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

                        // Timer slider
                        const Text('Duration Timer (Minutes)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text2)),
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
                        const SizedBox(height: 24),

                        // Question Bank Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Question Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('$selectedCount Selected', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // List of questions
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _questionBank.length,
                          itemBuilder: (context, index) {
                            final q = _questionBank[index];
                            final isSel = q['selected'] == true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primarySurface : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel ? AppColors.primary : AppColors.primaryExtraLight,
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: isSel,
                                  onChanged: (_) => _toggleQuestion(index),
                                ),
                                title: Text(q['question'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: Row(
                                  children: [
                                    Text(q['type'], style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                                    const SizedBox(width: 8),
                                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.text3, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Text(
                                      q['difficulty'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: q['difficulty'] == 'Easy'
                                            ? AppColors.green
                                            : q['difficulty'] == 'Medium'
                                                ? AppColors.orange
                                                : AppColors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _toggleQuestion(index),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 36),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _publishQuiz,
                            child: const Text('Publish Assessment'),
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
                title: 'Assessment Published!',
                onComplete: () {
                  setState(() => _success = false);
                  context.pop();
                },
              ),
            ),
        ],
      ),
    );
  }
}
