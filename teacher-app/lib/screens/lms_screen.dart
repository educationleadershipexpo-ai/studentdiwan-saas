import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class LmsScreen extends ConsumerStatefulWidget {
  const LmsScreen({super.key});
  @override
  ConsumerState<LmsScreen> createState() => _LmsScreenState();
}

class _LmsScreenState extends ConsumerState<LmsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _courses = [
    {
      'title': 'Mathematics — Grade KG2', 'code': 'MATH-KG2', 'lessons': 12, 'done': 8,
      'students': 28, 'lastActive': '2 hrs ago', 'color': Color(0xFF7C3AED),
      'icon': Icons.calculate_rounded,
      'modules': ['Number System', 'Basic Algebra', 'Shapes & Geometry', 'Measurement'],
    },
    {
      'title': 'Science — KG2-B', 'code': 'SCI-KG2', 'lessons': 10, 'done': 6,
      'students': 28, 'lastActive': 'Yesterday', 'color': Color(0xFF059669),
      'icon': Icons.science_rounded,
      'modules': ['Living Things', 'Energy', 'Matter & Materials', 'Earth & Space'],
    },
    {
      'title': 'English Language', 'code': 'ENG-KG2', 'lessons': 15, 'done': 10,
      'students': 28, 'lastActive': '3 hrs ago', 'color': Color(0xFF2563EB),
      'icon': Icons.menu_book_rounded,
      'modules': ['Phonics', 'Reading Comprehension', 'Grammar', 'Creative Writing'],
    },
  ];

  final List<Map<String, dynamic>> _recentActivity = [
    {'student': 'Fatima Al-Balushi', 'action': 'submitted Quiz 3', 'subject': 'Mathematics', 'time': '5 min ago', 'score': '18/20'},
    {'student': 'Ahmed Al-Rashidi', 'action': 'completed Lesson 8', 'subject': 'Science', 'time': '30 min ago', 'score': null},
    {'student': 'Aisha Al-Harthi', 'action': 'submitted Assignment 2', 'subject': 'English', 'time': '1 hr ago', 'score': null},
    {'student': 'Omar Al-Farsi', 'action': 'started Quiz 3', 'subject': 'Mathematics', 'time': '2 hr ago', 'score': null},
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
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
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
                        Text('Learning Management', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${_courses.length} active courses · ${_courses.fold(0, (a, b) => a + (b['students'] as int))} students enrolled',
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
              tabs: const [Tab(text: 'My Courses'), Tab(text: 'Recent Activity')],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Courses tab
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _courses.length,
              itemBuilder: (_, i) {
                final c = _courses[i];
                final progress = (c['done'] as int) / (c['lessons'] as int);
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [(c['color'] as Color).withOpacity(0.08), Colors.white]),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: Row(children: [
                        Container(width: 50, height: 50, decoration: BoxDecoration(color: (c['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                          child: Icon(c['icon'] as IconData, color: c['color'] as Color, size: 26)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A))),
                          Text('${c['code']} · ${c['students']} students', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${(progress * 100).toInt()}%', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: c['color'] as Color)),
                          Text('${c['done']}/${c['lessons']} lessons', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                        ]),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: progress, minHeight: 5,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation(c['color'] as Color)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Modules:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6,
                          children: (c['modules'] as List).map((m) =>
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: (c['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                              child: Text(m.toString(), style: GoogleFonts.inter(fontSize: 11, color: c['color'] as Color, fontWeight: FontWeight.w500)))
                          ).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Text('Last active: ${c['lastActive']}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c['color'] as Color, foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Open Course', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                      ]),
                    ),
                  ]),
                );
              },
            ),
            // Activity tab
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _recentActivity.length,
              itemBuilder: (_, i) {
                final a = _recentActivity[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                  ),
                  child: Row(children: [
                    CircleAvatar(radius: 20, backgroundColor: const Color(0xFFDBEAFE),
                      child: Text(a['student'].toString().split(' ').first[0], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      RichText(text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                        children: [
                          TextSpan(text: a['student'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ' ${a['action']}'),
                        ],
                      )),
                      const SizedBox(height: 3),
                      Text('${a['subject']} · ${a['time']}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                    ])),
                    if (a['score'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
                        child: Text(a['score'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                      ),
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
