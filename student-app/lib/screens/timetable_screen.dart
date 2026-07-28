import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  int _selectedDay = 1; // 1 = Mon, 2 = Tue, ..., 6 = Sat
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(studentTimetableProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          const AppHeader(
            title: 'My Timetable',
            subtitle: 'Check your daily classes and classroom locations',
            showBackButton: true,
          ),
          const SizedBox(height: 16),

          // Weekday selector
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final dayNum = index + 1;
                final isSel = _selectedDay == dayNum;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = dayNum),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.primaryExtraLight,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _days[index],
                      style: TextStyle(
                        color: isSel ? Colors.white : AppColors.text2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Periods Timeline
          Expanded(
            child: timetableAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonLoader(width: double.infinity, height: 80),
                ),
              ),
              error: (err, stack) => const Center(child: Text('Could not load your timetable right now.')),
              data: (slots) {
                final filtered = slots.where((s) => s.day == _selectedDay).toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

                if (filtered.isEmpty) {
                  return const Center(child: Text('No classes scheduled for this day.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];

                    // Highlight the period happening right now (today only).
                    final isActive = _isLiveNow(item);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: isActive
                            ? const LinearGradient(colors: AppColors.primaryGradient)
                            : null,
                        color: isActive ? null : Colors.white,
                        border: isActive ? null : Border.all(color: AppColors.primaryExtraLight, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(isActive ? 0.2 : 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.startTime} - ${item.endTime}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isActive ? Colors.white70 : AppColors.text3,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subject,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.white : AppColors.text1,
                                ),
                              ),
                              if (item.teacherName.isNotEmpty)
                                Text(
                                  item.teacherName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isActive ? Colors.white70 : AppColors.text2,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          if (item.room.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white.withOpacity(0.2) : const Color(0xFFF1F3F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.room,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.white : AppColors.text2),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // True when [item] is the period covering the current wall-clock time, and
  // the user is viewing today's column. Times are "hh:mm AM/PM" strings.
  bool _isLiveNow(TimetablePeriod item) {
    final now = DateTime.now();
    if (now.weekday != _selectedDay) return false;
    final start = _parseTime(item.startTime, now);
    final end = _parseTime(item.endTime, now);
    if (start == null || end == null) return false;
    return !now.isBefore(start) && now.isBefore(end);
  }

  DateTime? _parseTime(String hhmm, DateTime day) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})\s*([AP]M)?', caseSensitive: false)
        .firstMatch(hhmm.trim());
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final ampm = m.group(3)?.toUpperCase();
    if (ampm == 'PM' && hour != 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}

