import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_provider.dart';

class TeacherExamsScreen extends ConsumerStatefulWidget {
  const TeacherExamsScreen({super.key});
  @override
  ConsumerState<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends ConsumerState<TeacherExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Color _colorFor(int i) {
    const palette = [Color(0xFF7C3AED), Color(0xFF059669), Color(0xFF2563EB), Color(0xFFD97706), Color(0xFF0891B2)];
    return palette[i % palette.length];
  }

  double _pct(Map<String, dynamic> r) {
    final m = (r['marksObtained'] as num?)?.toDouble() ?? 0;
    final t = (r['totalMarks'] as num?)?.toDouble() ?? 100;
    if (t <= 0) return 0;
    return (m / t) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(teacherExamsProvider);
    final resultsAsync = ref.watch(teacherExamResultsProvider);
    final examCount = examsAsync.maybeWhen(data: (d) => d.length, orElse: () => 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () {
                  ref.invalidate(teacherExamsProvider);
                  ref.invalidate(teacherExamResultsProvider);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Examinations', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('$examCount exam${examCount == 1 ? '' : 's'} in the system',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [Tab(text: 'Scheduled'), Tab(text: 'Past Results')],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Scheduled exams (real `exams` entity) ──
            examsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _error(e.toString(), () => ref.invalidate(teacherExamsProvider)),
              data: (exams) {
                if (exams.isEmpty) return _empty('No exams scheduled', Icons.quiz_outlined);
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(teacherExamsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exams.length,
                    itemBuilder: (_, i) {
                      final e = exams[i];
                      final color = _colorFor(i);
                      final name = (e['name'] ?? 'Exam').toString();
                      final type = (e['type'] ?? '').toString();
                      final grade = (e['grade'] ?? '').toString();
                      final section = (e['section'] ?? '').toString();
                      final subjects = (e['subjects'] ?? '').toString();
                      final start = (e['startDate'] ?? '').toString();
                      final status = (e['status'] ?? 'Scheduled').toString();
                      final gradeSec = [grade, if (section.isNotEmpty) section].where((s) => s.isNotEmpty).join(' - ');
                      final scheduled = status.toLowerCase() == 'published' || status.toLowerCase() == 'scheduled';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                        ),
                        child: Column(children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.05),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Row(children: [
                              Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.quiz_rounded, color: color, size: 22)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(type.isEmpty ? name : '$name — $type', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                                Text([if (gradeSec.isNotEmpty) gradeSec, if (subjects.isNotEmpty) subjects].join(' · '), style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: scheduled ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: scheduled ? const Color(0xFF059669) : const Color(0xFFD97706))),
                              ),
                            ]),
                          ),
                          if (start.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 6),
                                Text(start, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                              ]),
                            ),
                        ]),
                      );
                    },
                  ),
                );
              },
            ),
            // ── Past results (aggregated from exam_results) ──
            resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _error(e.toString(), () => ref.invalidate(teacherExamResultsProvider)),
              data: (results) {
                if (results.isEmpty) return _empty('No results published', Icons.school_outlined);
                // Group by examName.
                final byExam = <String, List<Map<String, dynamic>>>{};
                for (final r in results) {
                  byExam.putIfAbsent((r['examName'] ?? 'Exam').toString(), () => []).add(r);
                }
                final entries = byExam.entries.toList();
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(teacherExamResultsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final examName = entries[i].key;
                      final recs = entries[i].value;
                      final color = _colorFor(i);
                      final pcts = recs.map(_pct).toList();
                      final avg = pcts.reduce((a, b) => a + b) / pcts.length;
                      final highest = pcts.reduce((a, b) => a > b ? a : b);
                      final lowest = pcts.reduce((a, b) => a < b ? a : b);
                      final gradeSec = recs.isNotEmpty
                          ? [recs.first['grade'], recs.first['section']].where((s) => (s ?? '').toString().isNotEmpty).join(' - ')
                          : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.school_rounded, color: color, size: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(examName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                              Text('${recs.length} student${recs.length == 1 ? '' : 's'}${gradeSec.isNotEmpty ? ' · $gradeSec' : ''}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('${avg.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                              Text('class avg', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                            ]),
                          ]),
                          const SizedBox(height: 14),
                          Row(children: [
                            _ScoreBadge(label: 'Highest', value: '${highest.toStringAsFixed(0)}%', color: const Color(0xFF10B981)),
                            const SizedBox(width: 12),
                            _ScoreBadge(label: 'Lowest', value: '${lowest.toStringAsFixed(0)}%', color: const Color(0xFFEF4444)),
                          ]),
                        ]),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _error(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text('Could not load', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF64748B))),
            const SizedBox(height: 6),
            Text(msg, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label, value; final Color color;
  const _ScoreBadge({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label: ', style: GoogleFonts.inter(fontSize: 11, color: color.withOpacity(0.8))),
      Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}
