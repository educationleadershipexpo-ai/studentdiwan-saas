import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherExamsScreen extends ConsumerStatefulWidget {
  const TeacherExamsScreen({super.key});
  @override
  ConsumerState<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends ConsumerState<TeacherExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _upcomingExams = [
    {'subject': 'Mathematics', 'class': 'KG2-B', 'type': 'Mid-Term', 'date': 'Jul 28, 2026', 'time': '8:00 AM', 'hall': 'Hall A', 'students': 28, 'status': 'Scheduled', 'color': Color(0xFF7C3AED)},
    {'subject': 'Science', 'class': 'KG2-B', 'type': 'Mid-Term', 'date': 'Jul 30, 2026', 'time': '8:00 AM', 'hall': 'Hall B', 'students': 28, 'status': 'Scheduled', 'color': Color(0xFF059669)},
    {'subject': 'English', 'class': 'KG2-B', 'type': 'Unit Test', 'date': 'Aug 4, 2026', 'time': '10:30 AM', 'hall': 'Hall A', 'students': 28, 'status': 'Draft', 'color': Color(0xFF2563EB)},
  ];

  final List<Map<String, dynamic>> _pastExams = [
    {'subject': 'Mathematics', 'class': 'KG2-B', 'type': 'Unit Test 1', 'date': 'Jun 10, 2026', 'avgScore': 72.5, 'highest': 95, 'lowest': 42, 'color': Color(0xFF7C3AED)},
    {'subject': 'Science', 'class': 'KG2-B', 'type': 'Unit Test 1', 'date': 'Jun 12, 2026', 'avgScore': 80.2, 'highest': 98, 'lowest': 55, 'color': Color(0xFF059669)},
    {'subject': 'English', 'class': 'KG2-B', 'type': 'Unit Test 1', 'date': 'Jun 14, 2026', 'avgScore': 76.8, 'highest': 92, 'lowest': 48, 'color': Color(0xFF2563EB)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFFDC2626),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Create Exam', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
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
                        Text('Examinations', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('KG2-B · ${_upcomingExams.length} upcoming exams',
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
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past Results')],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _upcomingExams.length,
              itemBuilder: (_, i) {
                final e = _upcomingExams[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                  ),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (e['color'] as Color).withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: (e['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.quiz_rounded, color: e['color'] as Color, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${e['subject']} — ${e['type']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                          Text('${e['class']} · ${e['students']} students', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: e['status'] == 'Scheduled' ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(e['status'], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                            color: e['status'] == 'Scheduled' ? const Color(0xFF059669) : const Color(0xFFD97706))),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: const Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text('${e['date']} · ${e['time']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                        const Spacer(),
                        Icon(Icons.location_on_rounded, size: 14, color: const Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(e['hall'], style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                      ]),
                    ),
                  ]),
                );
              },
            ),
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pastExams.length,
              itemBuilder: (_, i) {
                final e = _pastExams[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: (e['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.school_rounded, color: e['color'] as Color, size: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${e['subject']} — ${e['type']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                        Text('${e['date']} · ${e['class']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${e['avgScore']}%', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: e['color'] as Color)),
                        Text('class avg', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                      ]),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      _ScoreBadge(label: 'Highest', value: '${e['highest']}', color: const Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      _ScoreBadge(label: 'Lowest', value: '${e['lowest']}', color: const Color(0xFFEF4444)),
                      const Spacer(),
                      TextButton(onPressed: () {}, child: Text('View Results', style: GoogleFonts.inter(fontSize: 12, color: e['color'] as Color, fontWeight: FontWeight.w600))),
                    ]),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label, value; final Color color;
  const _ScoreBadge({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Text('$label: ', style: GoogleFonts.inter(fontSize: 11, color: color.withOpacity(0.8))),
      Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}
