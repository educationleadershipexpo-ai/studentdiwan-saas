import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_provider.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});
  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String _searchQuery = '';
  String _selectedGrade = 'All';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allStudentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load students')),
        data: (students) => _buildBody(students),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> allStudents) {
    // Get unique grades
    final gradeSet = allStudents.map((s) => 'Grade ${s['grade'] ?? ''}').toSet().toList()..sort();
    final grades = ['All', ...gradeSet];

    // Filter
    final filtered = allStudents.where((s) {
      final name = s['name'] as String? ?? '';
      final roll = s['rollNumber'] as String? ?? s['studentId'] as String? ?? '';
      final grade = 'Grade ${s['grade'] ?? ''}';
      final score = (s['performance'] as num?)?.toDouble() ?? 0.0;
      final att = (s['attendance'] as num?)?.toDouble() ?? 100.0;
      final isAtRisk = att < 75 || score < 50;

      final matchSearch = _searchQuery.isEmpty ||
          name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          roll.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchGrade = _selectedGrade == 'All' || grade == _selectedGrade;
      final matchFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'At Risk' && isAtRisk) ||
          (_selectedFilter == 'Active' && !isAtRisk);
      return matchSearch && matchGrade && matchFilter;
    }).toList();

    final atRiskCount = allStudents.where((s) {
      final att = (s['attendance'] as num?)?.toDouble() ?? 100.0;
      final score = (s['performance'] as num?)?.toDouble() ?? 0.0;
      return att < 75 || score < 50;
    }).length;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 175,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
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
                      Text('All Students', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(children: [
                        _HeaderStat(label: 'Total', value: '${allStudents.length}'),
                        const SizedBox(width: 20),
                        _HeaderStat(label: 'Active', value: '${allStudents.length - atRiskCount}'),
                        const SizedBox(width: 20),
                        _HeaderStat(label: 'At Risk', value: '$atRiskCount', color: Colors.red.shade200),
                        const SizedBox(width: 20),
                        _HeaderStat(label: 'Showing', value: '${filtered.length}', color: Colors.amber.shade200),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or roll number...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...['All', 'Active', 'At Risk'].map((f) => GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: f == _selectedFilter ? const Color(0xFF2563EB) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: f == _selectedFilter ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(f, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                              color: f == _selectedFilter ? Colors.white : const Color(0xFF64748B))),
                        ),
                      )),
                      const SizedBox(width: 4),
                      ...grades.where((g) => g != 'All').take(6).map((g) => GestureDetector(
                        onTap: () => setState(() => _selectedGrade = _selectedGrade == g ? 'All' : g),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: g == _selectedGrade ? const Color(0xFF7C3AED) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: g == _selectedGrade ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(g, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                              color: g == _selectedGrade ? Colors.white : const Color(0xFF64748B))),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((_, i) {
            final s = filtered[i];
            final name = s['name'] as String? ?? 'Unknown';
            final grade = 'Grade ${s['grade'] ?? ''}';
            final section = s['section'] as String? ?? '';
            final roll = s['rollNumber'] as String? ?? s['studentId'] as String? ?? '';
            final att = (s['attendance'] as num?)?.toDouble() ?? 100.0;
            final score = (s['performance'] as num?)?.toDouble() ?? 0.0;
            final isAtRisk = att < 75 || score < 50;
            final gender = (s['gender'] as String?)?.toLowerCase();

            return GestureDetector(
              onTap: () => _showStudentDetail(context, s),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: isAtRisk ? Border.all(color: const Color(0xFFFCA5A5), width: 1.5) : null,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isAtRisk ? const Color(0xFFFEE2E2) : (gender == 'female' ? const Color(0xFFFCE7F3) : const Color(0xFFDBEAFE)),
                    child: Text(name.isNotEmpty ? name[0] : '?',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15,
                            color: isAtRisk ? const Color(0xFFDC2626) : (gender == 'female' ? const Color(0xFFDB2777) : const Color(0xFF2563EB)))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A))),
                    Text('$grade - $section  ·  Roll: $roll  ·  Att: ${att.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                  ])),
                  if (isAtRisk)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                      child: Text('At Risk', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
                    )
                  else
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ]),
              ),
            );
          }, childCount: filtered.length),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _showStudentDetail(BuildContext context, Map<String, dynamic> s) {
    final name = s['name'] as String? ?? 'Unknown';
    final att = (s['attendance'] as num?)?.toDouble() ?? 100.0;
    final score = (s['performance'] as num?)?.toDouble() ?? 0.0;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            CircleAvatar(radius: 30, backgroundColor: const Color(0xFFDBEAFE),
                child: Text(name.isNotEmpty ? name[0] : '?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 22, color: const Color(0xFF2563EB)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0F172A))),
              Text('Grade ${s['grade'] ?? ''} - ${s['section'] ?? ''}  ·  Roll: ${s['rollNumber'] ?? s['studentId'] ?? ''}',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
            ])),
          ]),
          const SizedBox(height: 20),
          if (s['email'] != null)
            _DetailRow(Icons.email_rounded, 'School Email', s['email'].toString()),
          if (s['fatherName'] != null)
            _DetailRow(Icons.man_rounded, 'Father', '${s['fatherName']} · ${s['fatherPhone'] ?? ''}'),
          if (s['motherName'] != null)
            _DetailRow(Icons.woman_rounded, 'Mother', '${s['motherName']} · ${s['motherPhone'] ?? ''}'),
          if (s['bloodGroup'] != null)
            _DetailRow(Icons.bloodtype_rounded, 'Blood Group', s['bloodGroup'].toString()),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _StatBadge(label: 'Attendance', value: '${att.toStringAsFixed(0)}%', color: att >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            _StatBadge(label: 'Performance', value: '${score.toStringAsFixed(0)}%', color: const Color(0xFF2563EB)),
            _StatBadge(label: 'Risk', value: (att < 75 || score < 50) ? 'At Risk' : 'Good', color: (att < 75 || score < 50) ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
          ]),
        ]),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label, value; final Color? color;
  const _HeaderStat({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: GoogleFonts.inter(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
    Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
  ]);
}

class _DetailRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _DetailRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF2563EB)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A))),
      ])),
    ]),
  );
}

class _StatBadge extends StatelessWidget {
  final String label, value; final Color color;
  const _StatBadge({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: 56, height: 56, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: color)))),
    const SizedBox(height: 6),
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
  ]);
}
