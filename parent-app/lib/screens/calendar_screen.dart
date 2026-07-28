import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));

    final examsAsync = ref.watch(examsProvider(kid));
    final noticesAsync = ref.watch(noticesProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider(kid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBackHeader(title: 'School Calendar'),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(message: 'Failed to load calendar', onRetry: () { ref.invalidate(examsProvider(kid)); ref.invalidate(noticesProvider); ref.invalidate(assignmentsProvider(kid)); }),
        data: (exams) => noticesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, __) => ErrorState(message: 'Failed to load calendar', onRetry: () { ref.invalidate(noticesProvider); ref.invalidate(assignmentsProvider(kid)); }),
          data: (notices) => assignmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => ErrorState(message: 'Failed to load calendar', onRetry: () => ref.invalidate(assignmentsProvider(kid))),
            data: (assignments) {
              // Build event list
              final List<_CalEvent> events = [];

              for (final e in exams) {
                if (e.date != null) {
                  events.add(_CalEvent(
                    date: e.date!,
                    title: e.name,
                    subtitle: e.subject ?? 'Exam',
                    color: AppColors.red,
                    icon: Icons.assignment_outlined,
                  ));
                }
              }

              for (final n in notices) {
                if (n.createdAt != null) {
                  events.add(_CalEvent(
                    date: n.createdAt!,
                    title: n.title,
                    subtitle: n.category ?? 'Notice',
                    color: AppColors.blue,
                    icon: Icons.campaign_outlined,
                  ));
                }
              }

              for (final a in assignments) {
                if (a.dueDate != null) {
                  events.add(_CalEvent(
                    date: a.dueDate!,
                    title: a.title,
                    subtitle: 'Assignment · ${a.subject}',
                    color: AppColors.amber,
                    icon: Icons.task_outlined,
                  ));
                }
              }

              events.sort((a, b) => a.date.compareTo(b.date));

              if (events.isEmpty) return const EmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'No Upcoming Events',
                subtitle: 'Exams, assignments, and school events will appear here.',
              );

              // Group by month
              final Map<String, List<_CalEvent>> grouped = {};
              for (final e in events) {
                final key = DateFormat('MMMM yyyy').format(e.date);
                grouped.putIfAbsent(key, () => []).add(e);
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Legend
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [
                      _LegendDot(color: AppColors.red, label: 'Exams'),
                      _LegendDot(color: AppColors.amber, label: 'Assignments'),
                      _LegendDot(color: AppColors.blue, label: 'Events'),
                    ]),
                  ),

                  ...grouped.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: entry.key),
                      ...entry.value.map((e) => _EventTile(event: e)),
                    ],
                  )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CalEvent {
  final DateTime date;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  const _CalEvent({required this.date, required this.title, required this.subtitle, required this.color, required this.icon});
}

class _EventTile extends StatelessWidget {
  final _CalEvent event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(event.date, DateTime.now());
    final isPast = event.date.isBefore(DateTime.now()) && !isToday;

    return Opacity(
      opacity: isPast ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 52,
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.1),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(DateFormat('d').format(event.date),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: event.color)),
              Text(DateFormat('EEE').format(event.date).toUpperCase(),
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: event.color, letterSpacing: 0.5)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1), maxLines: 2),
            const SizedBox(height: 3),
            Text(event.subtitle, style: TextStyle(fontSize: 11, color: event.color, fontWeight: FontWeight.w600)),
          ])),
          if (isToday)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Text('Today', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          const SizedBox(width: 12),
        ]),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w600)),
  ]);
}
