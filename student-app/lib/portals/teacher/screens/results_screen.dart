import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  String? _selectedExam; // null = all exams

  double _pct(Map<String, dynamic> r) {
    final m = (r['marksObtained'] as num?)?.toDouble() ?? double.tryParse('${r['marksObtained'] ?? ''}') ?? 0;
    final t = (r['totalMarks'] as num?)?.toDouble() ?? double.tryParse('${r['totalMarks'] ?? ''}') ?? 100;
    if (t <= 0) return 0;
    return (m / t) * 100;
  }

  bool _isPass(Map<String, dynamic> r) {
    final s = (r['status'] ?? '').toString().toLowerCase();
    if (s.isNotEmpty) return s == 'pass';
    return _pct(r) >= 40;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teacherExamResultsProvider);
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Class Results',
            subtitle: 'Visualize student exam records and performance',
            showBackButton: true,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => _errorState(e.toString(), () => ref.invalidate(teacherExamResultsProvider)),
              data: (all) {
                if (all.isEmpty) {
                  return _emptyState();
                }
                // Distinct exam names for the selector.
                final exams = <String>{for (final r in all) (r['examName'] ?? 'Exam').toString()}.toList()..sort();
                final results = _selectedExam == null
                    ? all
                    : all.where((r) => (r['examName'] ?? 'Exam').toString() == _selectedExam).toList();

                // Real stats.
                final pcts = results.map(_pct).toList();
                final avg = pcts.isEmpty ? 0.0 : pcts.reduce((a, b) => a + b) / pcts.length;
                final highest = pcts.isEmpty ? 0.0 : pcts.reduce((a, b) => a > b ? a : b);
                final lowest = pcts.isEmpty ? 0.0 : pcts.reduce((a, b) => a < b ? a : b);
                final passCount = results.where(_isPass).length;
                final passPct = results.isEmpty ? 0.0 : (passCount / results.length) * 100;

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(teacherExamResultsProvider),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      // Exam selector
                      DropdownButtonFormField<String>(
                        initialValue: _selectedExam,
                        isExpanded: true,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        hint: const Text('All Exams'),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('All Exams')),
                          ...exams.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (val) => setState(() => _selectedExam = val),
                      ),
                      const SizedBox(height: 16),
                      // Stats card
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Class Average', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text2)),
                                Text('${avg.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricRow('Highest', '${highest.toStringAsFixed(0)}%', AppColors.green),
                                _buildMetricRow('Lowest', '${lowest.toStringAsFixed(0)}%', AppColors.red),
                                _buildMetricRow('Pass %', '${passPct.toStringAsFixed(0)}%', AppColors.primary),
                                _buildMetricRow('Students', '${results.length}', AppColors.text2),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Student marks list
                      ...results.map((item) {
                        final name = (item['studentName'] ?? 'Unknown').toString();
                        final isPass = _isPass(item);
                        final pct = _pct(item);
                        final gradeSec = '${item['grade'] ?? ''}${(item['section'] ?? '').toString().isNotEmpty ? ' - ${item['section']}' : ''}';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primaryExtraLight),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primaryExtraLight,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: context.heading3.copyWith(fontSize: 14)),
                                    if (gradeSec.trim().isNotEmpty)
                                      Text(gradeSec, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                                  ],
                                ),
                              ),
                              Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: isPass ? AppColors.text1 : AppColors.red),
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
                      }),
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

  Widget _buildMetricRow(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_rounded, size: 56, color: AppColors.text3),
            const SizedBox(height: 12),
            Text('No results published', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
            const SizedBox(height: 6),
            Text('No exam results have been recorded in the system yet.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.red),
            const SizedBox(height: 12),
            Text('Could not load results', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
            const SizedBox(height: 6),
            Text(msg, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
