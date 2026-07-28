import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  int _selectedTab = 0;
  String? _selectedExam;

  @override
  Widget build(BuildContext context) {
    final selectedClass = ref.watch(selectedClassProvider);
    final classId = selectedClass?.id ?? 'all';
    final marksAsync = ref.watch(examMarksListProvider(classId));

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Class Results',
            subtitle: 'Visualize student exam records and performance',
            showBackButton: true,
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
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'By Exam',
                          style: TextStyle(
                            color: _selectedTab == 0 ? Colors.white : AppColors.text2,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'By Student',
                          style: TextStyle(
                            color: _selectedTab == 1 ? Colors.white : AppColors.text2,
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

          Expanded(
            child: marksAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonLoader(width: double.infinity, height: 70),
                ),
              ),
              error: (err, _) => Center(child: Text('Error loading results: $err')),
              data: (marks) {
                if (marks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.text3),
                          SizedBox(height: 16),
                          Text('No results found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
                          SizedBox(height: 8),
                          Text('Exam marks will appear here once entered through the admin panel or Exams section.', style: TextStyle(color: AppColors.text3), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                // Get unique exam names
                final examNames = marks.map((m) => m.examName).where((e) => e.isNotEmpty).toSet().toList()..sort();

                // Pick a default exam if none selected
                if (_selectedExam == null || !examNames.contains(_selectedExam)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && examNames.isNotEmpty) {
                      setState(() => _selectedExam = examNames.last);
                    }
                  });
                }

                // Filter by selected exam
                final filtered = _selectedExam != null
                    ? marks.where((m) => m.examName == _selectedExam).toList()
                    : marks;

                // Compute stats
                final scores = filtered.map((m) => m.maxMarks > 0 ? (m.marks / m.maxMarks) * 100 : 0.0).toList();
                final avgScore = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
                final highest = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a > b ? a : b);
                final lowest = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a < b ? a : b);
                final passCount = scores.where((s) => s >= 60).length;
                final passRate = scores.isEmpty ? 0.0 : (passCount / scores.length) * 100;

                // Sort for chart: sorted scores (normalized)
                final sortedScores = [...scores]..sort();
                final chartPoints = sortedScores.map((s) => s / 100).toList();

                return Column(
                  children: [
                    // Exam selector dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DropdownButtonFormField<String>(
                        value: examNames.contains(_selectedExam) ? _selectedExam : (examNames.isNotEmpty ? examNames.last : null),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        items: examNames.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (val) => setState(() => _selectedExam = val),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chart card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Score Distribution',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text2),
                                ),
                                Text(
                                  '${avgScore.toStringAsFixed(1)}%',
                                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 120,
                              child: CustomPaint(
                                painter: _LiveLineChartPainter(points: chartPoints),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricRow('Highest', '${highest.toStringAsFixed(0)}%', AppColors.green),
                                _buildMetricRow('Lowest', '${lowest.toStringAsFixed(0)}%', AppColors.red),
                                _buildMetricRow('Pass %', '${passRate.toStringAsFixed(0)}%', AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Students listing
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => ref.invalidate(examMarksListProvider(classId)),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final pct = item.maxMarks > 0 ? (item.marks / item.maxMarks) * 100 : 0.0;
                            final isPass = pct >= 60;
                            final displayScore = item.grade != null && item.grade!.isNotEmpty
                                ? item.grade!
                                : '${pct.toStringAsFixed(1)}%';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryExtraLight),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primaryExtraLight,
                                    child: Text(
                                      item.studentName.isNotEmpty ? item.studentName[0] : '?',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.studentName, style: context.heading3.copyWith(fontSize: 14)),
                                        if (_selectedTab == 1 && item.subject.isNotEmpty)
                                          Text(item.subject, style: context.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    displayScore,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      color: isPass ? AppColors.text1 : AppColors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    isPass ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                                    color: isPass ? AppColors.green : AppColors.red,
                                    size: 20,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _LiveLineChartPainter extends CustomPainter {
  final List<double> points;
  const _LiveLineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    final offsets = List.generate(points.length, (i) {
      final x = points.length == 1 ? size.width / 2 : size.width * i / (points.length - 1);
      final y = size.height * (1 - points[i].clamp(0.0, 1.0));
      return Offset(x, y);
    });

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      path.quadraticBezierTo(
        (offsets[i - 1].dx + offsets[i].dx) / 2,
        (offsets[i - 1].dy + offsets[i].dy) / 2,
        offsets[i].dx,
        offsets[i].dy,
      );
    }

    final fillPath = Path()
      ..addPath(path, Offset.zero)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    final dotPaint = Paint()..color = AppColors.primary;
    final outerDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var p in offsets) {
      canvas.drawCircle(p, 4.0, dotPaint);
      canvas.drawCircle(p, 4.0, outerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveLineChartPainter old) => old.points != points;
}
