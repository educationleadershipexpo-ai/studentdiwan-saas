import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';

class PtmScreen extends ConsumerWidget {
  const PtmScreen({super.key});

  bool _isPast(Map<String, dynamic> m) {
    final s = (m['status'] ?? '').toString().toLowerCase();
    if (s == 'completed' || s == 'done' || s == 'past') return true;
    final raw = (m['date'] ?? m['meetingDate'] ?? '').toString();
    final d = DateTime.tryParse(raw);
    if (d != null) return d.isBefore(DateTime.now());
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherPtmProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () => ref.invalidate(teacherPtmProvider),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.headerGradient,
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
                          Text('Parent-Teacher Meetings', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          async.maybeWhen(
                            data: (m) => Text('${m.length} meeting${m.length == 1 ? '' : 's'} on record',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                            orElse: () => Text('Scheduled & past meetings', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [Tab(text: 'Scheduled'), Tab(text: 'Past')],
              ),
            ),
          ],
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _error(e.toString(), () => ref.invalidate(teacherPtmProvider)),
            data: (meetings) {
              final scheduled = meetings.where((m) => !_isPast(m)).toList();
              final past = meetings.where(_isPast).toList();
              return TabBarView(
                children: [
                  _meetingList(scheduled, 'No meetings scheduled', past: false),
                  _meetingList(past, 'No past meetings', past: true),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _meetingList(List<Map<String, dynamic>> items, String emptyMsg, {required bool past}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available_outlined, size: 56, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(emptyMsg, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF64748B))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final m = items[i];
        final parent = (m['parentName'] ?? m['parent'] ?? 'Parent').toString();
        final student = (m['studentName'] ?? m['student'] ?? '').toString();
        final date = (m['date'] ?? m['meetingDate'] ?? '').toString();
        final time = (m['time'] ?? '').toString();
        final mode = (m['mode'] ?? '').toString();
        final status = (m['status'] ?? '').toString();
        final agenda = (m['agenda'] ?? m['purpose'] ?? '').toString();
        final notes = (m['notes'] ?? '').toString();
        final confirmed = status.toLowerCase() == 'confirmed';
        final avatarChar = parent.trim().isNotEmpty ? parent.trim()[0].toUpperCase() : 'P';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 20, backgroundColor: const Color(0xFFEDE9FE),
                child: Text(avatarChar, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(parent, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                if (student.isNotEmpty)
                  Text('Parent of $student', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              ])),
              if (past)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
              else if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: confirmed ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                    color: confirmed ? const Color(0xFF059669) : const Color(0xFFD97706))),
                ),
            ]),
            if (date.isNotEmpty || time.isNotEmpty || mode.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (date.isNotEmpty) _InfoPill(icon: Icons.calendar_today_rounded, text: date),
                if (time.isNotEmpty) _InfoPill(icon: Icons.access_time_rounded, text: time),
                if (mode.isNotEmpty) _InfoPill(icon: mode.toLowerCase() == 'online' ? Icons.videocam_rounded : Icons.location_on_rounded, text: mode),
              ]),
            ],
            if (agenda.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Agenda: $agenda', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                child: Text('Notes: $notes', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)))),
            ],
          ]),
        );
      },
    );
  }

  Widget _error(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text('Could not load meetings', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF64748B))),
            const SizedBox(height: 6),
            Text(msg, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoPill({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: const Color(0xFF64748B)),
      const SizedBox(width: 5),
      Text(text, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
    ]),
  );
}
