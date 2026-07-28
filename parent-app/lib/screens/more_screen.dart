import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../widgets/common_widgets.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _items = [
    {'icon': Icons.bar_chart_rounded, 'label': 'Results', 'route': '/results', 'color': 0xFF00A385, 'bg': 0xFFD8F5EE},
    {'icon': Icons.receipt_outlined, 'label': 'Exams', 'route': '/exams', 'color': 0xFF6C5CE7, 'bg': 0xFFEDE9FF},
    {'icon': Icons.description_outlined, 'label': 'Report Cards', 'route': '/report-cards', 'color': 0xFF0984E3, 'bg': 0xFFE8F4FD},
    {'icon': Icons.psychology_outlined, 'label': 'Behaviour', 'route': '/behaviour', 'color': 0xFFE84040, 'bg': 0xFFFFE5E5},
    {'icon': Icons.emoji_events_outlined, 'label': 'Achievements', 'route': '/achievements', 'color': 0xFFFFA94D, 'bg': 0xFFFFF3DC},
    {'icon': Icons.favorite_outline_rounded, 'label': 'Health', 'route': '/health', 'color': 0xFFE84040, 'bg': 0xFFFFE5E5},
    {'icon': Icons.menu_book_rounded, 'label': 'Library', 'route': '/library', 'color': 0xFF0984E3, 'bg': 0xFFE8F4FD},
    {'icon': Icons.groups_outlined, 'label': 'PTM', 'route': '/ptm', 'color': 0xFF6C5CE7, 'bg': 0xFFEDE9FF},
    {'icon': Icons.notifications_outlined, 'label': 'Notifications', 'route': '/notifications', 'color': 0xFFFFA94D, 'bg': 0xFFFFF3DC},
    {'icon': Icons.folder_outlined, 'label': 'Study Materials', 'route': '/study-materials', 'color': 0xFF2E7D32, 'bg': 0xFFE8F5E9},
    {'icon': Icons.file_copy_outlined, 'label': 'Documents', 'route': '/documents', 'color': 0xFF0984E3, 'bg': 0xFFE8F4FD},
    {'icon': Icons.campaign_outlined, 'label': 'Announcements', 'route': '/announcements', 'color': 0xFFE67E00, 'bg': 0xFFFFF3DC},
    {'icon': Icons.access_time_rounded, 'label': 'Timetable', 'route': '/timetable', 'color': 0xFF6C5CE7, 'bg': 0xFFEDE9FF},
    {'icon': Icons.check_circle_outline_rounded, 'label': 'Attendance', 'route': '/attendance', 'color': 0xFF00A385, 'bg': 0xFFD8F5EE},
    {'icon': Icons.directions_bus_outlined, 'label': 'Transport', 'route': '/transport', 'color': 0xFF4DABF7, 'bg': 0xFFE8F4FD},
    {'icon': Icons.calendar_month_rounded, 'label': 'Calendar', 'route': '/calendar', 'color': 0xFF6C5CE7, 'bg': 0xFFEDE9FF},
    {'icon': Icons.mail_outline_rounded, 'label': 'Messages', 'route': '/messages', 'color': 0xFFC2185B, 'bg': 0xFFFCE4EC},
    {'icon': Icons.settings_outlined, 'label': 'Settings', 'route': '/settings', 'color': 0xFF4A4A6A, 'bg': 0xFFEEEAF8},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: const AppBackHeader(title: 'All Features'),
    body: GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1,
      ),
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final item = _items[i];
        final color = Color(item['color'] as int);
        final bg = Color(item['bg'] as int);
        return GestureDetector(
          onTap: () => context.push(item['route'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 10)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                child: Icon(item['icon'] as IconData, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(item['label'] as String,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2),
                textAlign: TextAlign.center),
            ]),
          ),
        );
      },
    ),
  );
}
