import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';

/// Live student records sometimes store performance/attendance as a label
/// string (e.g. "Needs Improvement") instead of a number. Coerce safely so a
/// String value never crashes the render (`as num?` throws on a real String).
double? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

/// A student is "At Risk" only on real evidence: attendance below 75%, a numeric
/// performance below 50, or an explicit low-performance label. A non-numeric
/// performance string (e.g. "Good", "Needs Improvement") must NOT be coerced to
/// 0 and treated as failing — that used to flag every student as At Risk.
bool _isAtRisk(Map<String, dynamic> s) {
  final att = _asNum(s['attendance']);
  if (att != null && att < 75) return true;
  final perf = s['performance'];
  final perfNum = _asNum(perf);
  if (perfNum != null) return perfNum < 50;
  final label = perf?.toString().toLowerCase() ?? '';
  return label.contains('needs improvement') || label.contains('poor') || label.contains('at risk');
}

/// Render a clean "Grade N" label whether the raw value is "3" or already
/// "Grade 3" — records are inconsistent, so strip any existing prefix first to
/// avoid a doubled "Grade Grade 3".
String _gradeLabel(dynamic g) {
  final raw = (g ?? '').toString().trim();
  if (raw.isEmpty) return 'Grade';
  final stripped = raw.replaceFirst(RegExp(r'^grade\s*', caseSensitive: false), '');
  return 'Grade $stripped';
}

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
    final allAsync = ref.watch(myStudentsProvider);
    final homeAsync = ref.watch(teacherHomeroomProvider);

    // Honest "not assigned" state — mirrors the web MyClass page. When the
    // teacher account has no real homeroom on file we show this instead of the
    // demo Grade 3-B roster.
    final notAssigned = homeAsync.maybeWhen(
      data: (h) => h.isFallback,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: notAssigned
          ? _buildNotAssigned()
          : allAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Failed to load students')),
              data: (students) => _buildBody(students),
            ),
    );
  }

  Widget _buildNotAssigned() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.groups_rounded, color: Color(0xFFA855F7), size: 28),
            ),
            const SizedBox(height: 16),
            Text('No Class Assigned Yet',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text(
              "Your account isn't currently set up as a class (homeroom) teacher for any grade/section. Contact your school admin to get a class assigned.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> allStudents) {
    // Get unique grades
    final gradeSet = allStudents.map((s) => _gradeLabel(s['grade'])).toSet().toList()..sort();
    final grades = ['All', ...gradeSet];

    // Filter
    final filtered = allStudents.where((s) {
      final name = s['name'] as String? ?? '';
      final roll = s['rollNumber'] as String? ?? s['studentId'] as String? ?? '';
      final grade = _gradeLabel(s['grade']);
      final isAtRisk = _isAtRisk(s);

      final matchSearch = _searchQuery.isEmpty ||
          name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          roll.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchGrade = _selectedGrade == 'All' || grade == _selectedGrade;
      final matchFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'At Risk' && isAtRisk) ||
          (_selectedFilter == 'Active' && !isAtRisk);
      return matchSearch && matchGrade && matchFilter;
    }).toList();

    final atRiskCount = allStudents.where(_isAtRisk).length;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 175,
          pinned: true,
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
                    prefixIcon: const Icon(Icons.search, color: AppColors.text3),
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
                            color: f == _selectedFilter ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: f == _selectedFilter ? AppColors.primary : AppColors.primaryExtraLight),
                          ),
                          child: Text(f, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                              color: f == _selectedFilter ? Colors.white : AppColors.text2)),
                        ),
                      )),
                      const SizedBox(width: 4),
                      ...grades.where((g) => g != 'All').take(6).map((g) => GestureDetector(
                        onTap: () => setState(() => _selectedGrade = _selectedGrade == g ? 'All' : g),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: g == _selectedGrade ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: g == _selectedGrade ? AppColors.primary : AppColors.primaryExtraLight),
                          ),
                          child: Text(g, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                              color: g == _selectedGrade ? Colors.white : AppColors.text2)),
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
            final grade = _gradeLabel(s['grade']);
            final section = s['section'] as String? ?? '';
            final roll = s['rollNumber'] as String? ?? s['studentId'] as String? ?? '';
            // Nullable — a missing attendance value must NOT be shown as a
            // fabricated 100%. Desktop MyClass renders "No records" instead.
            final att = _asNum(s['attendance']);
            final isAtRisk = _isAtRisk(s);
            final gender = (s['gender'] as String?)?.toLowerCase();
            final attLabel = att != null ? 'Att: ${att.toStringAsFixed(0)}%' : 'Att: —';

            return GestureDetector(
              onTap: () => _showStudentDetail(context, s),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
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
                    Text('$grade - $section  ·  Roll: $roll  ·  $attLabel',
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
    // Nullable so missing values render as "No records"/"Not graded" instead of
    // a fabricated 100%/0%. Risk uses the shared _isAtRisk guard, which treats
    // missing data as non-failing — never the raw 100/0 defaults.
    final att = _asNum(s['attendance']);
    final score = _asNum(s['performance']);
    final isAtRisk = _isAtRisk(s);
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
              Text('${_gradeLabel(s['grade'])} - ${s['section'] ?? ''}  ·  Roll: ${s['rollNumber'] ?? s['studentId'] ?? ''}',
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
            _StatBadge(label: 'Attendance', value: att != null ? '${att.toStringAsFixed(0)}%' : 'No records', color: att == null ? const Color(0xFF94A3B8) : (att >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
            _StatBadge(label: 'Performance', value: score != null ? '${score.toStringAsFixed(0)}%' : 'Not graded', color: score == null ? const Color(0xFF94A3B8) : const Color(0xFF2563EB)),
            _StatBadge(label: 'Risk', value: isAtRisk ? 'At Risk' : 'Good', color: isAtRisk ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
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
        child: Center(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(value, textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: color))),
        ))),
    const SizedBox(height: 6),
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
  ]);
}
