import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// Parent Assessments — real quizzes/tests/exams for the selected child, with
// status driven by the child's actual attempt AND the teacher's results-release
// gate (see parentAssessmentsProvider). A direct mirror of the desktop
// ParentAssessments.tsx page in the parent mobile visual system.
class AssessmentsScreen extends ConsumerStatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  ConsumerState<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends ConsumerState<AssessmentsScreen> {
  String _tab = 'all'; // all | upcoming | awaiting | graded
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) {
      return const Scaffold(body: Center(child: Text('No child selected')));
    }
    final async = ref.watch(parentAssessmentsProvider(kid));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBackHeader(title: 'Assessments · ${kid.firstName}'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(
          message: 'Failed to load assessments',
          onRetry: () => ref.invalidate(parentAssessmentsProvider(kid)),
        ),
        data: (all) {
          final upcoming = all.where((a) => a.status == 'Upcoming').length;
          final awaiting = all.where((a) => a.status == 'Awaiting Marks').length;
          final graded = all.where((a) => a.status == 'Graded').length;
          final missed = all.where((a) => a.status == 'Missed').length;

          final filtered = all.where((a) {
            final matchTab = _tab == 'all'
                ? true
                : _tab == 'upcoming'
                    ? a.status == 'Upcoming'
                    : _tab == 'awaiting'
                        ? a.status == 'Awaiting Marks'
                        : a.status == 'Graded';
            final q = _query.toLowerCase();
            final matchQ = q.isEmpty ||
                a.title.toLowerCase().contains(q) ||
                a.subject.toLowerCase().contains(q);
            return matchTab && matchQ;
          }).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(parentAssessmentsProvider(kid)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Stat grid
                Row(children: [
                  Expanded(child: _stat('Upcoming', upcoming, Icons.schedule_rounded, AppColors.amber, AppColors.amberLight)),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('Awaiting', awaiting, Icons.hourglass_bottom_rounded, AppColors.blue, AppColors.blueLight)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _stat('Graded', graded, Icons.star_rounded, AppColors.green, AppColors.greenLight)),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('Missed', missed, Icons.warning_amber_rounded, AppColors.red, AppColors.redLight)),
                ]),
                const SizedBox(height: 14),

                // Live-data banner (honest state)
                _banner(all.isNotEmpty, kid),
                const SizedBox(height: 14),

                // Tabs
                _tabs(),
                const SizedBox(height: 10),

                // Search
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search assessments…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.text3),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),

                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyState(
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'No assessments found',
                      subtitle: 'Nothing matches this filter yet.',
                    ),
                  )
                else
                  ...filtered.map((a) => _AssessmentCard(row: a)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon, Color fg, Color bg) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10)],
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text1, height: 1)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w600)),
          ]),
        ]),
      );

  Widget _banner(bool live, StudentModel kid) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: live ? AppColors.greenLight : AppColors.amberLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(live ? Icons.wifi_rounded : Icons.warning_amber_rounded,
              size: 16, color: live ? AppColors.green : AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              live
                  ? 'Live assessments from ${kid.gradeLabel} teacher records.'
                  : 'No assessments published yet for this class.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: live ? AppColors.green : AppColors.amber,
              ),
            ),
          ),
        ]),
      );

  Widget _tabs() {
    const tabs = [
      ['all', 'All'],
      ['upcoming', 'Upcoming'],
      ['awaiting', 'Awaiting'],
      ['graded', 'Graded'],
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: tabs.map((t) {
          final active = _tab == t[0];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = t[0]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  t[1],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.text3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final AssessmentRow row;
  const _AssessmentCard({required this.row});

  ({Color bg, Color fg}) get _meta {
    switch (row.status) {
      case 'Graded':
        return (bg: AppColors.greenLight, fg: AppColors.green);
      case 'Awaiting Marks':
        return (bg: AppColors.blueLight, fg: AppColors.blue);
      case 'Upcoming':
        return (bg: AppColors.amberLight, fg: AppColors.amber);
      case 'Missed':
        return (bg: AppColors.redLight, fg: AppColors.red);
      default:
        return (bg: AppColors.primaryExtraLight, fg: AppColors.primary);
    }
  }

  String _fmtNum(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final m = _meta;
    return WhiteCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
            const SizedBox(height: 3),
            Wrap(spacing: 10, runSpacing: 2, children: [
              _dim(row.subject),
              _dim(row.type),
              _dim('Date: ${row.date}'),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (row.score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(7)),
              child: Text(
                row.totalMarks != null
                    ? '${_fmtNum(row.score!)}/${_fmtNum(row.totalMarks!)}'
                    : _fmtNum(row.score!),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.green),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: m.bg, borderRadius: BorderRadius.circular(20)),
            child: Text(row.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: m.fg)),
          ),
        ]),
      ]),
    );
  }

  Widget _dim(String s) => Text(s, style: const TextStyle(fontSize: 11, color: AppColors.text3));
}
