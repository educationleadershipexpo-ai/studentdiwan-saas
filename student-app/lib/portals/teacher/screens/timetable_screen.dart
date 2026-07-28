import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
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
  int _selectedTab = 0; // 0 = My Timetable, 1 = Exam Timetable
  int _selectedDay = 1; // 1 = Mon, 2 = Tue, ..., 5 = Fri

  // Real teaching days only — Mon–Fri, matching desktop SCHOOL_DAYS. Saturday
  // is not a teaching day in this app's real timetable data.
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
              onPressed: () => context.push('/teacher/calendar'),
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: context.cardColor,
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
                : _buildExamTimetableList(ref.watch(teacherExamsProvider)),
          ),
        ],
      ),
    );
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
          return const Center(child: Text('No classes scheduled for this day.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: context.cardColor,
                border: Border.all(color: AppColors.primaryExtraLight, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.02),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.className,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text1,
                        ),
                      ),
                      Text(
                        item.subject,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.room,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text2,
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

  Widget _buildExamTimetableList(AsyncValue<List<Map<String, dynamic>>> asyncVal) {
    return asyncVal.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(width: double.infinity, height: 80),
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (exams) {
        if (exams.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_note_outlined, size: 48, color: AppColors.text3),
                const SizedBox(height: 12),
                Text('No exams scheduled',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text2)),
                const SizedBox(height: 4),
                Text('Exams for your class will appear here.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final item = exams[index];
            final name = (item['name'] ?? 'Exam').toString();
            final type = (item['type'] ?? '').toString();
            final grade = (item['grade'] ?? '').toString();
            final section = (item['section'] ?? '').toString();
            final subjects = (item['subjects'] ?? '').toString();
            final start = (item['startDate'] ?? item['date'] ?? '').toString();
            final status = (item['status'] ?? 'Scheduled').toString();
            final gradeSec =
                [grade, if (section.isNotEmpty) section].where((s) => s.isNotEmpty).join(' - ');
            final title = type.isEmpty ? name : '$name — $type';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryExtraLight, width: 1.5),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (start.isNotEmpty) ...[
                          Text(start,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                        ],
                        Text(title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text1)),
                        if (gradeSec.isNotEmpty || subjects.isNotEmpty)
                          Text([if (gradeSec.isNotEmpty) gradeSec, if (subjects.isNotEmpty) subjects].join(' · '),
                              style: const TextStyle(fontSize: 13, color: AppColors.text2)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryExtraLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(status,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
