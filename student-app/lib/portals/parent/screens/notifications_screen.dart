import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text1)),
        actions: [
          notifAsync.whenOrNull(
            data: (notifs) {
              final unread = notifs.where((n) => !n.read).toList();
              if (unread.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: Text('Mark all (${unread.length})', style: const TextStyle(fontSize: 12)),
                onPressed: () => _markAllRead(context, ref, unread),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              );
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const EmptyState(icon: Icons.notifications_outlined, title: 'No Notifications'),
        data: (notifications) {
          if (notifications.isEmpty) return const EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'All Clear',
            subtitle: 'You have no notifications at this time.',
          );

          final unread = notifications.where((n) => !n.read).toList();
          final read = notifications.where((n) => n.read).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (unread.isNotEmpty) ...[
                SectionHeader(
                  title: 'New',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text('${unread.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                ...unread.map((n) => _NotifCard(
                  notification: n,
                  onTap: () => _markRead(ref, n),
                )),
              ],
              if (read.isNotEmpty) ...[
                const SectionHeader(title: 'Earlier'),
                ...read.map((n) => _NotifCard(notification: n, dimmed: true)),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _markRead(WidgetRef ref, NotificationModel n) async {
    if (n.read) return;
    try {
      await ApiClient.instance.markNotificationRead(n.id);
      ref.invalidate(notificationsProvider);
    } catch (_) {}
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref, List<NotificationModel> unread) async {
    try {
      await Future.wait(unread.map((n) => ApiClient.instance.markNotificationRead(n.id)));
      ref.invalidate(notificationsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark all as read')),
        );
      }
    }
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notification;
  final bool dimmed;
  final VoidCallback? onTap;
  const _NotifCard({required this.notification, this.dimmed = false, this.onTap});

  IconData get _icon {
    final t = notification.type.toLowerCase();
    if (t.contains('fee') || t.contains('invoice') || t.contains('payment')) return Icons.receipt_outlined;
    if (t.contains('attend')) return Icons.event_available_outlined;
    if (t.contains('exam') || t.contains('result')) return Icons.assignment_outlined;
    if (t.contains('message')) return Icons.message_outlined;
    if (t.contains('alert') || t.contains('warn') || t.contains('urgent')) return Icons.warning_amber_rounded;
    if (t.contains('success') || t.contains('achiev')) return Icons.emoji_events_outlined;
    return Icons.notifications_none_rounded;
  }

  Color get _color {
    final t = notification.type.toLowerCase();
    if (t.contains('alert') || t.contains('warn') || t.contains('urgent')) return AppColors.amber;
    if (t.contains('fee') || t.contains('invoice')) return AppColors.red;
    if (t.contains('success') || t.contains('achiev')) return AppColors.green;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: dimmed ? Colors.white : AppColors.primaryExtraLight,
            borderRadius: BorderRadius.circular(14),
            border: dimmed ? Border.all(color: AppColors.primarySurface) : Border.all(color: AppColors.primary.withOpacity(0.18), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(_icon, color: _color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: notification.read ? FontWeight.w600 : FontWeight.w800,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(notification.body, style: const TextStyle(fontSize: 11, color: AppColors.text2, height: 1.4)),
                if (notification.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(_timeAgo(notification.createdAt!), style: const TextStyle(fontSize: 10, color: AppColors.text3)),
                ],
              ])),
              if (!notification.read)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }
}
