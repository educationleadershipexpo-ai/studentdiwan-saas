import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';

class ProjectReportsScreen extends ConsumerWidget {
  const ProjectReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherProjectReportsProvider);
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Project Reports', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.invalidate(teacherProjectReportsProvider)),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _errorState(e.toString(), () => ref.invalidate(teacherProjectReportsProvider)),
        data: (projects) {
          if (projects.isEmpty) {
            return _emptyState('No project reports', 'No student project reports have been submitted yet.');
          }
          final total = projects.length;
          // Status labels come from the desktop derivation: Reviewed / Late / Submitted.
          final graded = projects.where((p) => (p['status'] ?? '').toString().toLowerCase() == 'reviewed').length;
          final submitted = projects.where((p) {
            final s = (p['status'] ?? '').toString().toLowerCase();
            return s == 'submitted' || s == 'late' || s == 'pending';
          }).length;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(teacherProjectReportsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        _buildStat('$total', 'Total', AppColors.primary),
                        const SizedBox(width: 10),
                        _buildStat('$submitted', 'Active', AppColors.amber),
                        const SizedBox(width: 10),
                        _buildStat('$graded', 'Graded', AppColors.green),
                      ],
                    ),
                  );
                }
                final p = projects[i - 1];
                final status = (p['status'] ?? 'Submitted').toString();
                // Match the real status strings the provider emits (mirrors the
                // desktop derivation): Reviewed / Submitted / Late.
                final sl = status.toLowerCase();
                final statusColor = sl == 'reviewed' ? AppColors.green
                    : sl == 'submitted' ? AppColors.blue
                    : sl == 'late' ? AppColors.red
                    : AppColors.amber;
                // Real grade from the joined submission (desktop shows score/max).
                final score = p['score'];
                final maxScore = p['maxScore'] ?? 100;
                final hasScore = score != null && score.toString().trim().isNotEmpty;
                final feedback = (p['feedback'] ?? '').toString().trim();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryExtraLight)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text((p['title'] ?? 'Untitled Project').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text1)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if ((p['subject'] ?? '').toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(6)),
                              child: Text(p['subject'].toString(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ),
                          const SizedBox(width: 10),
                          const Icon(Icons.person_outline, size: 14, color: AppColors.text3),
                          const SizedBox(width: 4),
                          Expanded(child: Text((p['studentName'] ?? 'Unknown').toString(), style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3))),
                        ],
                      ),
                      if ((p['guideName'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Guide: ${p['guideName']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
                      ],
                      if (hasScore) ...[
                        const SizedBox(height: 12),
                        _buildMetric('Score', '$score / $maxScore', AppColors.green),
                      ],
                      if (feedback.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(feedback, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2, height: 1.4)),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text3)),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text3)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open_outlined, size: 56, color: AppColors.text3),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
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
            Text('Could not load data', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
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
