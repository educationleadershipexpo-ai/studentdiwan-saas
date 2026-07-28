import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/common_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(2026, 5, 20); // May 2026 matches mockups
  DateTime _selectedDate = DateTime(2026, 5, 20);

  final List<Map<String, dynamic>> _mockEvents = [
    {'date': DateTime(2026, 5, 20), 'title': 'Faculty review meeting', 'time': '02:00 PM', 'type': 'meeting', 'color': Color(0xFF6366F1)},
    {'date': DateTime(2026, 5, 20), 'title': 'Mathematics Midterm exam', 'time': '09:00 AM', 'type': 'exam', 'color': Color(0xFFEF4444)},
    {'date': DateTime(2026, 5, 22), 'title': 'Algebra worksheet submission due', 'time': '11:59 PM', 'type': 'homework', 'color': Color(0xFFF59E0B)},
    {'date': DateTime(2026, 5, 25), 'title': 'Calculus final grade review', 'time': '10:00 AM', 'type': 'assessment', 'color': Color(0xFF10B981)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'School Calendar',
            subtitle: 'Manage classes, parent meetings, and events',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 16),

          // Calendar Grid Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Month navigation row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: context.heading3.copyWith(fontSize: 16, color: AppColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Calendar Grid
                  _buildCalendarGrid(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Events List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Events on ${DateFormat('dd MMM').format(_selectedDate)}", style: context.heading2),
                const Icon(Icons.filter_list_rounded, color: AppColors.text3),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _buildEventsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;

    // Days listing
    final weekdayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        // Weekday labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdayNames.map((name) {
            return Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text3, fontSize: 12),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Date grid
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
            if (index < firstDayWeekday - 1) {
              return const SizedBox(); // empty day before month start
            }

            final day = index - (firstDayWeekday - 2);
            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            final isSelected = _selectedDate.year == date.year &&
                _selectedDate.month == date.month &&
                _selectedDate.day == date.day;
            final isToday = DateTime.now().year == date.year &&
                DateTime.now().month == date.month &&
                DateTime.now().day == date.day;

            final hasEvent = _mockEvents.any((e) =>
                e['date'].year == date.year &&
                e['date'].month == date.month &&
                e['date'].day == date.day);

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

  Widget _buildEventsList() {
    final filtered = _mockEvents.where((e) =>
        e['date'].year == _selectedDate.year &&
        e['date'].month == _selectedDate.month &&
        e['date'].day == _selectedDate.day).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No events scheduled for this day.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final ev = filtered[index];
        final Color cardColor = ev['color'];

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
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ev['title'], style: context.heading3.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(ev['time'], style: context.bodySmall),
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
      },
    );
  }
}
