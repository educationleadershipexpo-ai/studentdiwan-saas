import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherNotificationsProvider);
    return Scaffold(
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => ref.invalidate(teacherNotificationsProvider),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Notifications', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Stay updated with school activity', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          async.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
            error: (e, _) => SliverFillRemaining(child: _errorState(e.toString(), () => ref.invalidate(teacherNotificationsProvider))),
            data: (items) {
              if (items.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.text3),
                          SizedBox(height: 12),
                          Text('No notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final n = items[i];
                      return _buildNotifCard(n);
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(NotificationModel n) {
    final meta = _styleFor(n.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: n.read ? Colors.white : (meta.$2).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: n.read ? AppColors.primaryExtraLight : (meta.$2).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: (meta.$2).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(meta.$1, color: meta.$2, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(n.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text1))),
                    const SizedBox(width: 8),
                    Text(_relativeTime(n.createdAt), style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(n.body, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text2, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _styleFor(String type) {
    switch (type.toLowerCase()) {
      case 'daily_digest':
      case 'digest':
        return (Icons.summarize_rounded, AppColors.primary);
      case 'attendance':
        return (Icons.check_circle_rounded, AppColors.green);
      case 'leave':
      case 'leave_request':
        return (Icons.beach_access_rounded, AppColors.red);
      case 'ptm':
      case 'meeting':
        return (Icons.event_rounded, AppColors.primary);
      case 'exam':
        return (Icons.calendar_today_rounded, AppColors.orange);
      case 'homework':
      case 'assignment':
        return (Icons.assignment_rounded, AppColors.amber);
      case 'student':
        return (Icons.person_rounded, AppColors.blue);
      default:
        return (Icons.notifications_rounded, AppColors.primary);
    }
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
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
            Text('Could not load notifications', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
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
