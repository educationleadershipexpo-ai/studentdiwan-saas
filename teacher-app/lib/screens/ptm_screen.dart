import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

class PtmScreen extends ConsumerStatefulWidget {
  const PtmScreen({super.key});
  @override
  ConsumerState<PtmScreen> createState() => _PtmScreenState();
}

class _PtmScreenState extends ConsumerState<PtmScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showScheduleDialog() async {
    final studentCtrl = TextEditingController();
    final parentCtrl = TextEditingController();
    final agendaCtrl = TextEditingController();
    String selectedMode = 'In-Person';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Schedule PTM', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: studentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: parentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Parent Name',
                  prefixIcon: Icon(Icons.family_restroom_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: agendaCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Agenda / Purpose',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMode,
                decoration: const InputDecoration(labelText: 'Meeting Mode'),
                items: ['In-Person', 'Online', 'Hybrid']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setSheet(() => selectedMode = v!),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setSheet(() => selectedDate = picked);
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (studentCtrl.text.trim().isEmpty) return;
                    final auth = ref.read(authProvider);
                    final now = DateTime.now().toUtc().toIso8601String();
                    try {
                      await ApiClient.instance.createRecord('PTMSession', {
                        'id': 'ptm_${auth.user?.uid ?? ''}_${DateTime.now().millisecondsSinceEpoch}',
                        'teacher': auth.user?.displayName ?? '',
                        'teacherId': auth.user?.uid ?? '',
                        'student': studentCtrl.text.trim(),
                        'parent': parentCtrl.text.trim(),
                        'purpose': agendaCtrl.text.trim(),
                        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                        'meetingMode': selectedMode,
                        'status': 'Scheduled',
                        'createdAt': now,
                        'updatedAt': now,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      ref.invalidate(ptmSessionsProvider);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Text('Schedule Meeting', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final sessionsAsync = ref.watch(ptmSessionsProvider);
    final myUid = auth.user?.uid ?? '';
    final myName = (auth.user?.displayName ?? '').toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScheduleDialog,
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Schedule Meeting', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading PTM sessions: $err')),
        data: (allSessions) {
          // Filter to this teacher's sessions only
          final mySessions = allSessions.where((s) {
            final tid = '${s['teacherId'] ?? ''}';
            final tname = '${s['teacher'] ?? ''}'.toLowerCase();
            return (myUid.isNotEmpty && tid == myUid) ||
                   (myName.isNotEmpty && tname == myName);
          }).toList();

          final upcoming = mySessions.where((s) {
            final status = '${s['status'] ?? ''}';
            return status != 'Completed' && status != 'Cancelled' && status != 'No Show';
          }).toList()
            ..sort((a, b) => '${a['date'] ?? ''}'.compareTo('${b['date'] ?? ''}'));

          final completed = mySessions.where((s) => '${s['status'] ?? ''}' == 'Completed').toList()
            ..sort((a, b) => '${b['date'] ?? ''}'.compareTo('${a['date'] ?? ''}'));

          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Parent-Teacher Meetings',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${upcoming.length} upcoming · ${completed.length} completed',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  isScrollable: true,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Completed')],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // Upcoming tab
                upcoming.isEmpty
                    ? const Center(
                        child: Text('No upcoming PTM sessions.', style: TextStyle(color: Color(0xFF94A3B8))),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(ptmSessionsProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: upcoming.length,
                          itemBuilder: (_, i) {
                            final m = upcoming[i];
                            final status = '${m['status'] ?? 'Pending'}';
                            final confirmed = status == 'Confirmed';
                            final isOnline = '${m['meetingMode'] ?? ''}' == 'Online';
                            final parentName = '${m['parent'] ?? m['student'] ?? ''}';
                            final initials = parentName.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: confirmed ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                                  width: 1.5,
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(0xFFEDE9FE),
                                        child: Text(initials.isNotEmpty ? initials : '?',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${m['parent'] ?? 'Parent'}',
                                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                                            Text('Parent of ${m['student'] ?? ''}',
                                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: confirmed ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(status,
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: confirmed ? const Color(0xFF059669) : const Color(0xFFD97706))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if ((m['date'] ?? '').toString().isNotEmpty)
                                        _InfoPill(icon: Icons.calendar_today_rounded, text: '${m['date']}'),
                                      if ((m['timeRange'] ?? m['slot'] ?? '').toString().isNotEmpty)
                                        _InfoPill(icon: Icons.access_time_rounded, text: '${m['timeRange'] ?? m['slot']}'),
                                      _InfoPill(
                                        icon: isOnline ? Icons.videocam_rounded : Icons.location_on_rounded,
                                        text: '${m['meetingMode'] ?? 'In-Person'}',
                                      ),
                                    ],
                                  ),
                                  if ((m['purpose'] ?? m['agenda'] ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text('Agenda: ${m['purpose'] ?? m['agenda']}',
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                                  ],
                                  if (isOnline && (m['meetingLink'] ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.videocam_rounded, size: 16),
                                        label: Text('Join Meeting',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF7C3AED),
                                          side: const BorderSide(color: Color(0xFF7C3AED)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                // Completed tab
                completed.isEmpty
                    ? const Center(
                        child: Text('No completed PTM sessions yet.', style: TextStyle(color: Color(0xFF94A3B8))),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: completed.length,
                        itemBuilder: (_, i) {
                          final m = completed[i];
                          final parentName = '${m['parent'] ?? m['student'] ?? ''}';
                          final initials = parentName.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFFEDE9FE),
                                      child: Text(initials.isNotEmpty ? initials : '?',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${m['parent'] ?? 'Parent'}',
                                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                                          Text('${m['date'] ?? ''} · ${m['meetingMode'] ?? ''}',
                                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                  ],
                                ),
                                if ((m['meetingNotes'] ?? m['actionItems'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Notes: ${m['meetingNotes'] ?? ''}',
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(text, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
          ],
        ),
      );
}
