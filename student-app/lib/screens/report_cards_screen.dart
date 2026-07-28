import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';

// Real published report cards for the logged-in student, from the live
// `report_cards` table (studentReportCardsProvider). Terms, subjects, marks,
// grades, and the class-teacher remark are all real published data — no
// fabricated ranks, CA/exam splits, term list, or fake PDF download.
class ReportCardsScreen extends ConsumerStatefulWidget {
  const ReportCardsScreen({super.key});
  @override
  ConsumerState<ReportCardsScreen> createState() => _ReportCardsScreenState();
}

class _ReportCardsScreenState extends ConsumerState<ReportCardsScreen> {
  int _selectedTerm = 0;

  Color _gradeColor(String g) {
    if (g.startsWith('A')) return AppColors.green;
    if (g.startsWith('B')) return AppColors.primary;
    if (g.startsWith('C')) return AppColors.amber;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(studentReportCardsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _shell(
          context,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 80),
              child: Text('Could not load your report cards right now.',
                  style: TextStyle(color: AppColors.text3)),
            ),
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return _shell(
              context,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(children: [
                    Icon(Icons.pending_outlined, size: 64, color: AppColors.text3),
                    const SizedBox(height: 12),
                    Text('No report cards published yet',
                        style: GoogleFonts.inter(color: AppColors.text3, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Check back once your school publishes results',
                        style: GoogleFonts.inter(color: AppColors.text3, fontSize: 13)),
                  ]),
                ),
              ),
            );
          }

          final term = _selectedTerm.clamp(0, reports.length - 1);
          final report = reports[term];

          return _shell(
            context,
            average: report.overallPct.toDouble(),
            hasData: report.subjects.isNotEmpty,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Term selector (real published terms)
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final selected = i == term;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTerm = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFD97706) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: selected ? const Color(0xFFD97706) : Colors.grey.shade200),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              reports[i].label.isEmpty ? 'Report ${i + 1}' : reports[i].label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppColors.text2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (report.subjects.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(children: [
                          Icon(Icons.description_outlined, size: 56, color: AppColors.text3),
                          const SizedBox(height: 12),
                          Text('This report has no subject marks.',
                              style: GoogleFonts.inter(color: AppColors.text3, fontSize: 14)),
                        ]),
                      ),
                    )
                  else ...[
                    // Summary card (real overall %, subject count, attendance)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFB45309), Color(0xFFD97706)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryItem(
                              label: 'Average',
                              value: '${report.overallPct}%',
                              icon: Icons.bar_chart_rounded),
                          _SummaryItem(
                              label: 'Subjects',
                              value: '${report.subjects.length}',
                              icon: Icons.book_rounded),
                          _SummaryItem(
                              label: 'Attendance',
                              value: report.attendancePct != null
                                  ? '${report.attendancePct}%'
                                  : '—',
                              icon: Icons.event_available_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    ...report.subjects.map((s) => _SubjectCard(
                          subject: s,
                          gradeColor: _gradeColor(s.letter),
                        )),

                    if (report.classTeacherRemark.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryExtraLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.person_pin_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('Class Teacher Remark',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.text1)),
                            ]),
                            const SizedBox(height: 8),
                            Text('"${report.classTeacherRemark}"',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.text2)),
                          ],
                        ),
                      ),
                    ],

                    if (report.teacherName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Issued by ${report.teacherName}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Shared gradient header + scroll shell.
  Widget _shell(BuildContext context,
      {required Widget child, double? average, bool hasData = false}) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 150,
          pinned: true,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.headerGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Report Cards',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      if (hasData && average != null) ...[
                        const SizedBox(height: 4),
                        Text('Overall Average: ${average.toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: child),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final ReportCardSubjectRow subject;
  final Color gradeColor;
  const _SubjectCard({required this.subject, required this.gradeColor});

  @override
  Widget build(BuildContext context) {
    final s = subject;
    final label = s.subject.isEmpty
        ? '—'
        : s.subject.length >= 2
            ? s.subject.substring(0, 2).toUpperCase()
            : s.subject.toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 12, color: gradeColor)))),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.subject.isEmpty ? 'Subject' : s.subject,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text1)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (s.pct / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(gradeColor),
            ),
          ),
          const SizedBox(height: 4),
          Text('Marks: ${s.obtained % 1 == 0 ? s.obtained.toInt() : s.obtained}/'
              '${s.max % 1 == 0 ? s.max.toInt() : s.max}  ·  ${s.pct}%',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
        ])),
        const SizedBox(width: 12),
        if (s.letter.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text(s.letter,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 16, color: gradeColor)),
          ),
      ]),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SummaryItem({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
      ]);
}
