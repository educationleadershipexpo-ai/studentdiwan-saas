import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart' show ParentBottomNav, ParentSideDrawer;

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));

    final examsAsync = ref.watch(examsProvider(kid));
    final noticesAsync = ref.watch(noticesProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider(kid));
    final eventsAsync = ref.watch(calendarEventsProvider);

    void retry() {
      ref.invalidate(examsProvider(kid));
      ref.invalidate(noticesProvider);
      ref.invalidate(assignmentsProvider(kid));
      ref.invalidate(calendarEventsProvider);
    }

    // Flattened combine: one loading spinner while any source loads, one error
    // state if any fails, otherwise render the merged timeline. Avoids the old
    // triple-nested `.when` pyramid.
    final asyncs = [examsAsync, noticesAsync, assignmentsAsync, eventsAsync];

    Widget body;
    if (asyncs.any((a) => a.isLoading)) {
      body = const Center(child: CircularProgressIndicator(color: AppColors.primary));
    } else if (asyncs.any((a) => a.hasError)) {
      body = ErrorState(message: 'Failed to load calendar', onRetry: retry);
    } else {
      final exams = examsAsync.value ?? const [];
      final notices = noticesAsync.value ?? const [];
      final assignments = assignmentsAsync.value ?? const [];
      final schoolEvents = eventsAsync.value ?? const [];

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

      for (final ev in schoolEvents) {
        if (ev.date != null) {
          events.add(_CalEvent(
            date: ev.date!,
            title: ev.title,
            subtitle: ev.location ?? ev.type ?? 'School Event',
            color: AppColors.green,
            icon: Icons.event_outlined,
          ));
        }
      }

      events.sort((a, b) => a.date.compareTo(b.date));

      if (events.isEmpty) {
        body = const EmptyState(
          icon: Icons.calendar_month_outlined,
          title: 'No Upcoming Events',
          subtitle: 'Exams, assignments, and school events will appear here.',
        );
      } else {
        // Group by month
        final Map<String, List<_CalEvent>> grouped = {};
        for (final e in events) {
          final key = DateFormat('MMMM yyyy').format(e.date);
          grouped.putIfAbsent(key, () => []).add(e);
        }

        body = ListView(
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
                _LegendDot(color: AppColors.blue, label: 'Notices'),
                _LegendDot(color: AppColors.green, label: 'Events'),
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
      }
    }

    return Scaffold(
      backgroundColor: context.bgColor,
      drawer: const ParentSideDrawer(),
      appBar: const AppBackHeader(title: 'School Calendar'),
      body: body,
      bottomNavigationBar: const ParentBottomNav(activeRoute: '/parent/calendar'),
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
          color: context.cardColor,
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
