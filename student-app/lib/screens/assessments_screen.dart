import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// Real assessments for the logged-in student. The catalogue, questions, scoring,
// and prior attempts all come from the live backend (studentQuizAssessmentsProvider
// + studentQuizAttemptsProvider). Taking a quiz writes a real assessment_attempts
// row via submitQuizAttempt — no hardcoded questions, no fake "synced to ERP".
class AssessmentsScreen extends ConsumerStatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  ConsumerState<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends ConsumerState<AssessmentsScreen> {
  int _selectedTab = 0; // 0 = Assessments, 1 = Exam timetable

  // Quiz-taking state (null when not in a quiz).
  QuizAssessment? _quiz;
  int _currentQuestionIndex = 0;
  final Map<String, String> _answers = {}; // questionId → selected optionId/text
  bool _submitting = false;
  int? _finalScore; // set once submitted

  void _startQuiz(QuizAssessment quiz) {
    setState(() {
      _quiz = quiz;
      _currentQuestionIndex = 0;
      _answers.clear();
      _submitting = false;
      _finalScore = null;
    });
  }

  void _exitQuiz() {
    setState(() {
      _quiz = null;
      _finalScore = null;
      _submitting = false;
    });
  }

  Future<void> _submitQuiz() async {
    final quiz = _quiz;
    if (quiz == null) return;
    setState(() => _submitting = true);
    try {
      final score = await submitQuizAttempt(ref, assessment: quiz, answers: _answers);
      ref.invalidate(studentQuizAttemptsProvider);
      if (mounted) {
        setState(() {
          _submitting = false;
          _finalScore = score;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit your attempt: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quiz != null) {
      return _buildQuizWorkspace();
    }

    final quizzesAsync = ref.watch(studentQuizAssessmentsProvider);
    final examsAsync = ref.watch(studentExamsProvider);

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Exams & Quizzes',
            subtitle: 'Take your classroom assessments and check exam dates',
            showBackButton: false,
          ),
          const SizedBox(height: 16),

          // Tabs
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
                  _tab('Assessments', 0),
                  _tab('Exam Timetable', 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _selectedTab == 0
                ? _buildAssessmentsList(quizzesAsync)
                : _buildExamsList(examsAsync),
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

  Widget _buildAssessmentsList(AsyncValue<List<QuizAssessment>> asyncVal) {
    final attempts = ref.watch(studentQuizAttemptsProvider).value ?? const <String, int>{};

    return asyncVal.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(width: double.infinity, height: 75),
        ),
      ),
      error: (err, stack) => const Center(
        child: Text('Could not load your assessments right now.',
            style: TextStyle(color: AppColors.text3)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(studentQuizAssessmentsProvider);
              ref.invalidate(studentQuizAttemptsProvider);
            },
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.26),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.quiz_outlined, size: 64, color: AppColors.text3),
                      SizedBox(height: 12),
                      Text('No assessments assigned to your class yet.',
                          style: TextStyle(color: AppColors.text3, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentQuizAssessmentsProvider);
            ref.invalidate(studentQuizAttemptsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final quiz = list[index];
              final taken = attempts.containsKey(quiz.id);
              final score = attempts[quiz.id];
              final canTake = quiz.questions.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryExtraLight),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: taken ? AppColors.green.withOpacity(0.08) : AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      taken ? Icons.assignment_turned_in_rounded : Icons.quiz_rounded,
                      color: taken ? AppColors.green : AppColors.primary,
                    ),
                  ),
                  title: Text(quiz.title, style: context.heading3.copyWith(fontSize: 14)),
                  subtitle: Text(
                    '${quiz.durationMinutes} mins · ${quiz.questions.length} questions'
                    '${quiz.subject.isNotEmpty ? ' · ${quiz.subject}' : ''}',
                    style: context.bodySmall,
                  ),
                  trailing: taken
                      ? StatusChip(
                          label: 'Score: $score/${quiz.totalMarks}',
                          textColor: AppColors.green,
                          bgColor: AppColors.greenLight,
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: canTake ? () => _startQuiz(quiz) : null,
                          child: Text(canTake ? 'Start' : 'No questions',
                              style: const TextStyle(fontSize: 11)),
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExamsList(AsyncValue<List<ExamModel>> asyncVal) {
    return asyncVal.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(width: double.infinity, height: 75),
        ),
      ),
      error: (err, stack) => const Center(
        child: Text('Could not load the exam timetable right now.',
            style: TextStyle(color: AppColors.text3)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentExamsProvider),
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.26),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_note_outlined, size: 64, color: AppColors.text3),
                      SizedBox(height: 12),
                      Text('No exams scheduled yet.',
                          style: TextStyle(color: AppColors.text3, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentExamsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryExtraLight),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: context.heading3.copyWith(fontSize: 14.5)),
                          Text('${item.subject} · ${item.dateRange}', style: context.bodySmall),
                        ],
                      ),
                    ),
                    if (item.room.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.room,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuizWorkspace() {
    final quiz = _quiz!;

    if (_submitting) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Submitting your attempt...',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text2),
              ),
            ],
          ),
        ),
      );
    }

    // Result screen — shows the real computed score.
    if (_finalScore != null) {
      final score = _finalScore!;
      final total = quiz.totalMarks;
      final pct = total > 0 ? (score / total * 100).clamp(0, 100).toDouble() : 0.0;
      final passed = quiz.passingMarks == 0 ? true : score >= quiz.passingMarks;

      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(passed ? Icons.stars_rounded : Icons.check_circle_outline_rounded,
                    color: passed ? AppColors.amber : AppColors.primary, size: 84),
                const SizedBox(height: 20),
                Text('Attempt Submitted',
                    style: GoogleFonts.outfit(
                        fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text1)),
                const SizedBox(height: 6),
                const Text('Your answers have been recorded in the ERP.',
                    style: TextStyle(color: AppColors.text3, fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                CircularProgressRing(
                  percentage: pct,
                  size: 130,
                  strokeWidth: 10,
                  activeColor: passed ? AppColors.green : AppColors.primary,
                  centerWidget: Text(
                    '$score / $total',
                    style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: passed ? AppColors.green : AppColors.primary),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _exitQuiz,
                    child: const Text('Back to Assessments'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = quiz.questions[_currentQuestionIndex];
    final isLast = _currentQuestionIndex == quiz.questions.length - 1;
    final selectedAnswer = _answers[question.id];
    final hasAnswer = selectedAnswer != null && selectedAnswer.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _exitQuiz,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${quiz.questions.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text3),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / quiz.questions.length),
            const SizedBox(height: 30),

            Text(question.text, style: context.heading2.copyWith(fontSize: 17)),
            if (question.marks > 0) ...[
              const SizedBox(height: 6),
              Text('${question.marks} mark${question.marks == 1 ? '' : 's'}',
                  style: context.bodySmall),
            ],
            const SizedBox(height: 24),

            Expanded(child: _buildAnswerArea(question, selectedAnswer)),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: !hasAnswer
                    ? null
                    : () {
                        if (!isLast) {
                          setState(() => _currentQuestionIndex++);
                        } else {
                          _submitQuiz();
                        }
                      },
                child: Text(isLast ? 'Submit Answers' : 'Next Question'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MCQ questions render their real options; open-ended render a text field.
  Widget _buildAnswerArea(QuizQuestion question, String? selectedAnswer) {
    if (question.options.isNotEmpty) {
      return ListView.builder(
        itemCount: question.options.length,
        itemBuilder: (context, index) {
          final option = question.options[index];
          final isSelected = selectedAnswer == option.id;

          return GestureDetector(
            onTap: () => setState(() => _answers[question.id] = option.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.primaryExtraLight,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected ? AppColors.primary : AppColors.text3,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.text2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Open-ended / short-answer question.
    return TextField(
      maxLines: 6,
      minLines: 4,
      onChanged: (val) => _answers[question.id] = val,
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        filled: true,
        fillColor: context.bgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
