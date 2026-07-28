import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});
  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> with WidgetsBindingObserver {
  int _selectedDay = DateTime.now().weekday.clamp(1, 5); // 1=Mon–5=Fri; weekend clamps to Friday
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Poll for re-published timetables every 15s, matching the desktop portal's
    // live-refresh behaviour so parents never sit on a stale schedule.
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pull the latest as soon as the app comes back to the foreground.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    ref.read(timetableRefreshTick.notifier).state++;
  }

  static const _days = {1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday', 5: 'Friday'};
  static const _subjectColors = {
    'mathematics': Color(0xFF6C5CE7), 'math': Color(0xFF6C5CE7),
    'english': Color(0xFF0984E3), 'science': Color(0xFFC2185B),
    'history': Color(0xFFE67E00), 'bahasa': Color(0xFF00A385),
    'islamic': Color(0xFF6C5CE7), 'pe': Color(0xFF00A385), 'art': Color(0xFF0984E3),
  };

  Color _subjectColor(String subject) {
    final lower = subject.toLowerCase();
    for (final entry in _subjectColors.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final ttAsync = ref.watch(timetableProvider(kid));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBackHeader(title: 'Timetable · ${kid.gradeLabel}'),
      body: Column(children: [
        // Day tabs
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            children: _days.entries.map((e) {
              final active = e.key == _selectedDay;
              return GestureDetector(
                onTap: () => setState(() => _selectedDay = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: active ? AppColors.primary : AppColors.primaryExtraLight, width: 1.5),
                  ),
                  child: Text(e.value.substring(0, 3),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.text3)),
                ),
              );
            }).toList(),
          ),
        ),

        // Slots
        Expanded(
          child: ttAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => ErrorState(message: 'Failed to load timetable'),
            data: (byDay) {
              final slots = byDay[_selectedDay] ?? [];
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: slots.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          EmptyState(icon: Icons.schedule_rounded, title: 'No Classes', subtitle: 'No classes scheduled for ${_days[_selectedDay]}.'),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: slots.length,
                        itemBuilder: (_, i) {
                  final s = slots[i];
                  final color = _subjectColor(s.subject);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(left: BorderSide(color: color, width: 4)),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10)],
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 64,
                        child: Column(children: [
                          Text(s.startTime, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                          Text('–', style: TextStyle(color: color, fontSize: 10)),
                          Text(s.endTime, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                        ]),
                      ),
                      Container(width: 1, height: 40, color: AppColors.primarySurface, margin: const EdgeInsets.symmetric(horizontal: 12)),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text1)),
                        if (s.teacher != null) Text(s.teacher!, style: const TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w500)),
                      ])),
                      if (s.room != null) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(s.room!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ]),
                  );
                },
                      ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
