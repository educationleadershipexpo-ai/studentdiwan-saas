import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../widgets/common_widgets.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  String? _selectedTool; // Name of selected AI generator
  final _inputController = TextEditingController();
  bool _generating = false;
  String? _generatedResult;

  final List<Map<String, dynamic>> _aiTools = [
    {'name': 'Lesson Plan Generator', 'desc': 'Create complete session logs & activities', 'icon': Icons.menu_book_rounded, 'color': Color(0xFF6366F1)},
    {'name': 'Worksheet Generator', 'desc': 'Generate algebraic/literary worksheets', 'icon': Icons.note_add_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Quiz Generator', 'desc': 'Create multiple choice exam papers', 'icon': Icons.quiz_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'Rubric Generator', 'desc': 'Assemble matrix indicators for scoring projects', 'icon': Icons.table_chart_rounded, 'color': Color(0xFFEC4899)},
    {'name': 'Report Card Comments', 'desc': 'Draft feedback reports based on student grades', 'icon': Icons.comment_rounded, 'color': Color(0xFF3B82F6)},
    {'name': 'Translation Tool', 'desc': 'Translate curriculums to Arabic or English', 'icon': Icons.g_translate_rounded, 'color': Color(0xFF06B6D4)},
  ];

  Future<void> _runAIGeneration() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _generating = true;
      _generatedResult = null;
    });

    // Simulate AI loading delays
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _generating = false;
        _generatedResult = _generateMockAIText(_selectedTool!, input);
      });
    }
  }

  String _generateMockAIText(String tool, String topic) {
    if (tool.contains('Lesson')) {
      return '### AI Generated Lesson Plan: $topic\n\n'
          '**Grade Level:** Grade 8 · **Duration:** 45 Mins\n\n'
          '**Learning Objectives:**\n'
          '1. Students will comprehend core principles of $topic.\n'
          '2. Apply formulas to solve sample problems.\n\n'
          '**Activities Schedule:**\n'
          '- **00:00 - 00:10 (Warmup):** Introduction to $topic history and basic terms.\n'
          '- **00:10 - 00:25 (Core Lecture):** Teacher models equations on blackboard.\n'
          '- **00:25 - 00:40 (Group Work):** Peer worksheets review.\n'
          '- **00:40 - 00:45 (Summary):** Exit ticket assessment.';
    } else if (tool.contains('Quiz')) {
      return '### AI Generated Quiz: $topic\n\n'
          '**Total Questions:** 3 · **Duration:** 10 mins\n\n'
          '**Q1. What is the fundamental property of $topic?**\n'
          '   A) Variable constant\n'
          '   B) Inverted fraction [Correct]\n'
          '   C) Hexagonal sum\n\n'
          '**Q2. Calculate the derivative/limit of $topic under baseline values:**\n'
          '   A) 1\n'
          '   B) 0 [Correct]\n'
          '   C) Infinite\n\n'
          '**Q3. True or False: $topic is commutative.**\n'
          '   *Answer:* True. Explanation: Commutative laws apply to addition/multiplication.';
    } else if (tool.contains('Worksheet')) {
      return '### AI Generated Student Worksheet: $topic\n\n'
          'Name: ______________________  Date: _________\n\n'
          '**Instructions:** Show all steps clearly. Round answers to 2 decimals.\n\n'
          '1. Solve the following linear expression for $topic: 3x - 12 = 18.\n'
          '   *Solution Box:* ____________________________\n\n'
          '2. Given parameters A=4 and B=9, evaluate the function value of $topic.\n'
          '   *Solution Box:* ____________________________\n\n'
          '3. Draw the corresponding chart mapping $topic trends.';
    } else {
      return '### AI Assistant Output: $topic\n\n'
          'Successfully generated Consolidated insights for "$topic" tailored to school curriculum standards. Review the references below or export to PDF.';
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Diwan AI Copilot',
            subtitle: 'Premium AI assistant for smart worksheet & plan drafting',
            showBackButton: true,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text('Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Main view body
          Expanded(
            child: _selectedTool == null 
                ? _buildToolsGrid() 
                : _buildToolWorkspace(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: _aiTools.length,
      itemBuilder: (context, index) {
        final tool = _aiTools[index];
        final Color col = tool['color'];

        return InkWell(
          onTap: () {
            setState(() {
              _selectedTool = tool['name'];
              _inputController.clear();
              _generatedResult = null;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryExtraLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: col.withOpacity(0.08), shape: BoxShape.circle),
                  child: Icon(tool['icon'], color: col, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool['name'],
                      style: context.heading3.copyWith(fontSize: 13.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool['desc'],
                      style: const TextStyle(fontSize: 10.5, color: AppColors.text3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolWorkspace() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                onPressed: () => setState(() => _selectedTool = null),
              ),
              Text(_selectedTool!, style: context.heading2),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _inputController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Topic or Prompt Input',
              hintText: 'e.g. Quadratic Equations Grade 8, or Newton laws of motion...',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _runAIGeneration,
              icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
              label: const Text('Generate Resource'),
            ),
          ),
          const SizedBox(height: 24),
          if (_generating) ...[
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('AI model synthesizing materials...', style: TextStyle(color: AppColors.text3)),
                ],
              ),
            ),
          ],
          if (_generatedResult != null) ...[
            const Text('Generated Output', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryExtraLight),
              ),
              child: SelectableText(
                _generatedResult!,
                style: GoogleFonts.robotoMono(fontSize: 13, color: AppColors.text1),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied output to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy to Clipboard'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
