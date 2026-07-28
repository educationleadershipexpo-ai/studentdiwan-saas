import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// Real examinations for the logged-in student. Upcoming exams come from the live
// `exams` table (studentExamsProvider); results come from the live results/
// gradebook (studentResultsProvider). No hardcoded subjects, dates, halls, or
// grades — an empty result renders an empty state.
class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});
  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Color> _accentCycle = [
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFDC2626),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(studentExamsProvider);
    final resultsAsync = ref.watch(studentResultsProvider);
    final upcomingCount = examsAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
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
                        Text('Examinations',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.event_note_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              upcomingCount == 0
                                  ? 'No exams scheduled'
                                  : '$upcomingCount upcoming exam${upcomingCount == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ),
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
              tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Results')],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildUpcoming(examsAsync),
            _buildResults(resultsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcoming(AsyncValue<List<ExamModel>> asyncVal) {
    return asyncVal.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(width: double.infinity, height: 110),
        ),
      ),
      error: (err, stack) => const Center(
        child: Text('Could not load the exam schedule right now.',
            style: TextStyle(color: AppColors.text3)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentExamsProvider),
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_available_outlined, size: 64, color: AppColors.text3),
                      SizedBox(height: 12),
                      Text('No upcoming exams scheduled.',
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
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final e = list[i];
              final color = _accentCycle[i % _accentCycle.length];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.06),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    ),
                    child: Row(children: [
                      Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.school_rounded, color: color, size: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.title,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text1)),
                        if (e.subject.isNotEmpty)
                          Text(e.subject,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2)),
                      ])),
                      if (e.dateRange.isNotEmpty)
                        Text(e.dateRange,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 13, color: color)),
                    ]),
                  ),
                  if (e.room.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _InfoRow(icon: Icons.location_on_rounded, label: 'Venue', value: e.room),
                    ),
                ]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildResults(AsyncValue<List<ResultGrade>> asyncVal) {
    return asyncVal.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(width: double.infinity, height: 80),
        ),
      ),
      error: (err, stack) => const Center(
        child: Text('Could not load your results right now.',
            style: TextStyle(color: AppColors.text3)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentResultsProvider),
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.analytics_outlined, size: 64, color: AppColors.text3),
                      SizedBox(height: 12),
                      Text('No published exam results yet.',
                          style: TextStyle(color: AppColors.text3, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Overall % from real marks: sum(score) / sum(total).
        int sumScore = 0, sumTotal = 0;
        for (final g in list) {
          sumScore += g.score;
          sumTotal += g.total;
        }
        final overall = sumTotal > 0 ? (sumScore / sumTotal * 100).round() : 0;
        final overallColor = overall >= 85
            ? AppColors.green
            : (overall >= 75 ? AppColors.amber : AppColors.red);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentResultsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Overall average summary ring (ported from the standalone Results screen).
              GlassCard(
                child: Row(
                  children: [
                    CircularProgressRing(
                      percentage: overall.toDouble(),
                      size: 90,
                      strokeWidth: 8,
                      activeColor: overallColor,
                      centerWidget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$overall%',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.text1)),
                          const Text('Overall',
                              style: TextStyle(fontSize: 9, color: AppColors.text3, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Overall Average',
                              style: context.heading3.copyWith(fontSize: 14, color: overallColor)),
                          const SizedBox(height: 4),
                          Text('$sumScore / $sumTotal marks across ${list.length} subject${list.length == 1 ? '' : 's'}.',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.text2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(list.length, (i) {
                final e = list[i];
                final color = _accentCycle[i % _accentCycle.length];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                  ),
                  child: Row(children: [
                    Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.school_rounded, color: color, size: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.subject.isEmpty ? 'Subject' : e.subject,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text1)),
                      Text('${e.score} / ${e.total}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2)),
                    ])),
                    if (e.grade.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppColors.primaryExtraLight,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(e.grade,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                      ),
                  ]),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 15, color: AppColors.text3),
        const SizedBox(width: 8),
        Text('$label: ',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
        Expanded(
            child: Text(value,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2))),
      ]);
}
