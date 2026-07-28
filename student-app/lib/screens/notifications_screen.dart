import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(studentNotificationsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Notifications', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        notifAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (list) => Text('${list.length} notifications', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          notifAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (_, __) => SliverToBoxAdapter(child: _emptyState()),
            data: (notifications) {
              if (notifications.isEmpty) {
                return SliverFillRemaining(child: _emptyState());
              }
              // Group into recent (today) and earlier
              final now = DateTime.now();
              final recent = notifications.where((n) {
                final t = DateTime.tryParse(n['createdAt'] as String? ?? n['time'] as String? ?? '');
                return t != null && now.difference(t).inDays == 0;
              }).toList();
              final earlier = notifications.where((n) {
                final t = DateTime.tryParse(n['createdAt'] as String? ?? n['time'] as String? ?? '');
                return t == null || now.difference(t).inDays > 0;
              }).toList();

              return SliverList(
                delegate: SliverChildListDelegate([
                  if (recent.isNotEmpty) ...[
                    _SectionHeader('Today'),
                    ...recent.map((n) => _NotificationTile(n: n)),
                  ],
                  if (earlier.isNotEmpty) ...[
                    _SectionHeader('Earlier'),
                    ...earlier.map((n) => _NotificationTile(n: n)),
                  ],
                  const SizedBox(height: 24),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.notifications_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
      const SizedBox(height: 16),
      Text('No notifications yet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
      const SizedBox(height: 8),
      Text('You\'re all caught up!', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8))),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF94A3B8), letterSpacing: 0.5)),
  );
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> n;
  const _NotificationTile({required this.n});

  IconData _icon(String? category, String? type) {
    if (type == 'daily_digest') return Icons.summarize_rounded;
    switch (category) {
      case 'attendance': return Icons.how_to_reg_rounded;
      case 'academic': return Icons.school_rounded;
      case 'fee': return Icons.receipt_long_rounded;
      case 'exam': return Icons.quiz_rounded;
      case 'message': return Icons.message_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _color(String? category) {
    switch (category) {
      case 'attendance': return const Color(0xFF059669);
      case 'academic': return const Color(0xFF2563EB);
      case 'fee': return const Color(0xFFDC2626);
      case 'exam': return const Color(0xFF7C3AED);
      default: return const Color(0xFF0891B2);
    }
  }

  String _timeAgo(String? ts) {
    if (ts == null) return '';
    final t = DateTime.tryParse(ts);
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final category = n['category'] as String?;
    final type = n['type'] as String?;
    final isRead = n['read'] as bool? ?? false;
    final color = _color(category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isRead ? const Color(0xFFF1F5F9) : color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(_icon(category, type), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(n['title'] as String? ?? 'Notification',
                style: GoogleFonts.inter(fontWeight: isRead ? FontWeight.w500 : FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A)))),
            Text(_timeAgo(n['createdAt'] as String? ?? n['time'] as String?),
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
          ]),
          const SizedBox(height: 4),
          Text(n['message'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
        ])),
        if (!isRead) ...[
          const SizedBox(width: 8),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ],
      ]),
    );
  }
}
