import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';
import '../providers/auth_provider.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  int _selectedTab = 0; // 0 = My Timetable, 1 = Exam Timetable
  // Default to today's weekday (Mon=1...Fri=5); weekends fall back to Mon
  late int _selectedDay = () {
    final wd = DateTime.now().weekday; // Mon=1, Tue=2...Sun=7
    return wd >= 1 && wd <= 5 ? wd : 1;
  }();

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(teacherTimetableProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Schedule & Timetable',
            subtitle: 'Track your daily classes and examinations room mapping',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
              onPressed: () => context.push('/calendar'),
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'My Timetable',
                          style: TextStyle(
                            color: _selectedTab == 0 ? Colors.white : AppColors.text2,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Exam Timetable',
                          style: TextStyle(
                            color: _selectedTab == 1 ? Colors.white : AppColors.text2,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Weekday selector
          if (_selectedTab == 0) ...[
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
          ],

          // List of Slots
          Expanded(
            child: _selectedTab == 0
                ? _buildTimetableList(timetableAsync)
                : _buildExamTimetableList(),
          ),
        ],
      ),
    );
  }

  bool _isCurrentPeriod(String start, String end) {
    try {
      int _parseTime(String t) {
        final clean = t.trim();
        final isPM = clean.toUpperCase().contains('PM');
        final isAM = clean.toUpperCase().contains('AM');
        final parts = clean.replaceAll(RegExp(r'[APMapm ]'), '').split(':');
        int h = int.parse(parts[0]);
        int m = parts.length > 1 ? int.parse(parts[1]) : 0;
        if (isPM && h != 12) h += 12;
        if (isAM && h == 12) h = 0;
        return h * 60 + m;
      }
      final now = TimeOfDay.now();
      final nowMin = now.hour * 60 + now.minute;
      return nowMin >= _parseTime(start) && nowMin <= _parseTime(end);
    } catch (_) {
      return false;
    }
  }

  Widget _buildTimetableList(AsyncValue<List<TimetableSlot>> asyncVal) {
    return asyncVal.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(width: double.infinity, height: 80),
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (slots) {
        final filtered = slots.where((s) => s.day == _selectedDay).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No classes scheduled for today.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            
            final isActive = _selectedDay == DateTime.now().weekday &&
                _isCurrentPeriod(item.startTime, item.endTime);

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
                        item.className,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : AppColors.text1,
                        ),
                      ),
                      Text(
                        item.subject,
                        style: TextStyle(
                          fontSize: 13,
                          color: isActive ? Colors.white70 : AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
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
                        color: isActive ? Colors.white : AppColors.text2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExamTimetableList() {
    final auth = ref.watch(authProvider);
    final examsAsync = ref.watch(examsListProvider);

    return examsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(width: double.infinity, height: 80),
        ),
      ),
      error: (err, _) => Center(child: Text('Error loading exam schedule: $err')),
      data: (exams) {
        if (exams.isEmpty) {
          return const Center(
            child: Text('No exam schedule published yet.', style: TextStyle(color: AppColors.text3)),
          );
        }

        // Filter by teacher if possible
        final myName = (auth.user?.displayName ?? '').toLowerCase();
        final filtered = exams.where((e) {
          if (myName.isEmpty) return true;
          final teacher = '${e['teacher'] ?? e['invigilator'] ?? ''}'.toLowerCase();
          return teacher.isEmpty || teacher.contains(myName.split(' ').first);
        }).toList();

        final list = filtered.isNotEmpty ? filtered : exams;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final date = '${item['date'] ?? item['examDate'] ?? ''}';
            final time = '${item['time'] ?? item['startTime'] ?? ''}';
            final grade = '${item['grade'] ?? item['class'] ?? ''}';
            final section = '${item['section'] ?? ''}';
            final className = section.isNotEmpty ? '$grade - $section' : grade;
            final subject = '${item['subject'] ?? item['name'] ?? ''}';
            final room = '${item['room'] ?? item['venue'] ?? item['hall'] ?? ''}';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryExtraLight, width: 1.5),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${date.isNotEmpty ? date : '—'}${time.isNotEmpty ? ' · $time' : ''}',
                        style: const TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        className.isNotEmpty ? className : subject,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text1),
                      ),
                      if (className.isNotEmpty && subject.isNotEmpty)
                        Text(subject, style: const TextStyle(fontSize: 13, color: AppColors.text2)),
                    ],
                  ),
                  const Spacer(),
                  if (room.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.redLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(room, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.red)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
