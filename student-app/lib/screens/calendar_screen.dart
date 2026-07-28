import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// School calendar driven by live data: admin calendar_events, the student's
// published exams, and homework due dates (see studentCalendarProvider).
// No mock events — days with no real data show an empty agenda.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return AppColors.red;
      case 'homework':
        return AppColors.amber;
      case 'holiday':
        return AppColors.green;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(studentCalendarProvider);
    final events = eventsAsync.value ?? const <CalendarEvent>[];

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'School Calendar',
            subtitle: 'Your exams, homework deadlines and school events',
            showBackButton: false,
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                        onPressed: () => setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                        }),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: context.heading3.copyWith(fontSize: 16, color: AppColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                        onPressed: () => setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCalendarGrid(events),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Agenda: ${DateFormat('dd MMM').format(_selectedDate)}", style: context.heading2),
                if (eventsAsync.isLoading)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(child: _buildEventsList(events)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<CalendarEvent> events) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final weekdayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdayNames.map((name) {
            return Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text3, fontSize: 12)),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: daysInMonth + (firstDayWeekday - 1),
          itemBuilder: (context, index) {
            if (index < firstDayWeekday - 1) return const SizedBox();

            final day = index - (firstDayWeekday - 2);
            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            final isSelected = _isSameDay(_selectedDate, date);
            final isToday = _isSameDay(DateTime.now(), date);
            final hasEvent = events.any((e) => _isSameDay(e.date, date));

            return GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primaryExtraLight
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? AppColors.primary
                                : AppColors.text1,
                      ),
                    ),
                    if (hasEvent)
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events) {
    final filtered = events.where((e) => _isSameDay(e.date, _selectedDate)).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No events scheduled for this day.', style: TextStyle(color: AppColors.text3)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentCalendarProvider),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final ev = filtered[index];
          final Color cardColor = _typeColor(ev.type);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryExtraLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 40,
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ev.title, style: context.heading3.copyWith(fontSize: 14)),
                      if (ev.time.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(ev.time, style: context.bodySmall),
                      ],
                    ],
                  ),
                ),
                StatusChip(
                  label: ev.type.toUpperCase(),
                  textColor: cardColor,
                  bgColor: cardColor.withOpacity(0.08),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
