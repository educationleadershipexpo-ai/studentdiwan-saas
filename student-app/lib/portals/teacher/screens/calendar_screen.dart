import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart' show CustomBottomBar, QuickActionsBottomSheet;

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

  // ── Normalise a raw backend event into {date, title, time, type, color} ──
  Map<String, dynamic>? _normalize(Map<String, dynamic> e) {
    final rawDate = (e['date'] ?? e['startDate'] ?? e['eventDate'] ?? e['start'] ?? '').toString();
    final date = DateTime.tryParse(rawDate);
    if (date == null) return null;
    final type = (e['type'] ?? e['category'] ?? 'event').toString();
    return {
      'date': DateTime(date.year, date.month, date.day),
      'title': (e['title'] ?? e['name'] ?? 'Event').toString(),
      'time': (e['time'] ?? e['startTime'] ?? '').toString(),
      'type': type,
      'color': _colorForType(type),
    };
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return const Color(0xFFEF4444);
      case 'homework':
      case 'assignment':
        return const Color(0xFFF59E0B);
      case 'assessment':
        return const Color(0xFF10B981);
      case 'meeting':
      case 'ptm':
        return const Color(0xFF6366F1);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teacherCalendarProvider);
    return Scaffold(
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: 3,
        onTap: (i) {
          if (i == 0) context.go('/teacher/dashboard');
          if (i == 1) context.go('/teacher/classes');
          if (i == 4) context.go('/teacher/profile');
        },
        onFabPressed: () => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const QuickActionsBottomSheet(),
        ),
      ),
      body: Column(
        children: [
          AppHeader(
            title: 'School Calendar',
            subtitle: 'Classes, parent meetings, and events',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 26),
              onPressed: () => ref.invalidate(teacherCalendarProvider),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => _errorState(e.toString(), () => ref.invalidate(teacherCalendarProvider)),
              data: (raw) {
                final events = raw.map(_normalize).whereType<Map<String, dynamic>>().toList();
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(teacherCalendarProvider),
                  child: ListView(
                    children: [
                      const SizedBox(height: 8),
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
                                    onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
                                  ),
                                  Text(DateFormat('MMMM yyyy').format(_currentMonth), style: context.heading3.copyWith(fontSize: 16, color: AppColors.primary)),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                                    onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
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
                        child: Text("Events on ${DateFormat('dd MMM').format(_selectedDate)}", style: context.heading2),
                      ),
                      const SizedBox(height: 12),
                      _buildEventsList(events),
                      const SizedBox(height: 20),
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

  Widget _buildCalendarGrid(List<Map<String, dynamic>> events) {
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
              child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text3, fontSize: 12)),
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
            final isSelected = _selectedDate.year == date.year && _selectedDate.month == date.month && _selectedDate.day == date.day;
            final now = DateTime.now();
            final isToday = now.year == date.year && now.month == date.month && now.day == date.day;
            final hasEvent = events.any((e) => e['date'].year == date.year && e['date'].month == date.month && e['date'].day == date.day);

            return GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : isToday ? AppColors.primaryExtraLight : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text('$day', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : isToday ? AppColors.primary : AppColors.text1)),
                    if (hasEvent)
                      Positioned(
                        bottom: 4,
                        child: Container(width: 4, height: 4, decoration: BoxDecoration(color: isSelected ? Colors.white : AppColors.primary, shape: BoxShape.circle)),
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

  Widget _buildEventsList(List<Map<String, dynamic>> events) {
    final filtered = events.where((e) =>
        e['date'].year == _selectedDate.year &&
        e['date'].month == _selectedDate.month &&
        e['date'].day == _selectedDate.day).toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy_outlined, size: 44, color: AppColors.text3),
              const SizedBox(height: 8),
              Text('No events on this day', style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: filtered.map((ev) {
        final Color cardColor = ev['color'] as Color;
        final time = (ev['time'] ?? '').toString();
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryExtraLight),
          ),
          child: Row(
            children: [
              Container(width: 5, height: 40, decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ev['title'], style: context.heading3.copyWith(fontSize: 14)),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(time, style: context.bodySmall),
                    ],
                  ],
                ),
              ),
              StatusChip(
                label: ev['type'].toString().toUpperCase(),
                textColor: cardColor,
                bgColor: cardColor.withOpacity(0.08),
              ),
            ],
          ),
        );
      }).toList(),
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
            Text('Could not load calendar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
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
