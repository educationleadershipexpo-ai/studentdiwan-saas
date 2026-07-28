import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_provider.dart';

class LmsScreen extends ConsumerWidget {
  const LmsScreen({super.key});

  static const _palette = [Color(0xFF7C3AED), Color(0xFF059669), Color(0xFF2563EB), Color(0xFFD97706), Color(0xFF0891B2)];

  int _lessonCount(Map<String, dynamic> c) {
    final l = c['lessons'];
    return l is List ? l.length : 0;
  }

  int _publishedCount(Map<String, dynamic> c) {
    final l = c['lessons'];
    if (l is! List) return 0;
    return l.where((e) => e is Map && e['published'] == true).length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherLmsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => ref.invalidate(teacherLmsProvider),
              ),
            ],
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
                        async.maybeWhen(
                          data: (courses) => Text('${courses.length} active course${courses.length == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                          orElse: () => Text('Courses & lessons', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _error(e.toString(), () => ref.invalidate(teacherLmsProvider)),
          data: (courses) {
            if (courses.isEmpty) return _empty();
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(teacherLmsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (_, i) {
                  final c = courses[i];
                  final color = _palette[i % _palette.length];
                  final total = _lessonCount(c);
                  final done = _publishedCount(c);
                  final progress = total == 0 ? 0.0 : done / total;
                  final name = (c['name'] ?? 'Untitled Course').toString();
                  final subject = (c['subject'] ?? '').toString();
                  final grade = (c['grade'] ?? '').toString();
                  final teacher = (c['teacher'] ?? '').toString();
                  final description = (c['description'] ?? '').toString();
                  final lessons = (c['lessons'] is List) ? (c['lessons'] as List) : const [];

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
                          gradient: LinearGradient(colors: [color.withOpacity(0.08), Colors.white]),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        child: Row(children: [
                          Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                            child: Icon(Icons.menu_book_rounded, color: color, size: 26)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A))),
                            Text([subject, grade].where((s) => s.isNotEmpty).join(' · '), style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          ])),
                          if (total > 0)
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('${(progress * 100).toInt()}%', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                              Text('$done/$total lessons', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                            ]),
                        ]),
                      ),
                      if (total > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: progress, minHeight: 5,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation(color)),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (description.isNotEmpty) ...[
                            Text(description, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569), height: 1.3)),
                            const SizedBox(height: 10),
                          ],
                          if (lessons.isNotEmpty) ...[
                            Text('Lessons:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                            const SizedBox(height: 8),
                            Wrap(spacing: 6, runSpacing: 6,
                              children: lessons.take(6).map((m) {
                                final title = (m is Map ? (m['title'] ?? '') : m).toString();
                                return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                                  child: Text(title, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w500)));
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (teacher.isNotEmpty)
                            Text('Instructor: $teacher', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                        ]),
                      ),
                    ]),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_outlined, size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text('No courses yet', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text('No LMS courses have been created in the system yet.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
        ],
      ),
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
            Text('Could not load courses', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF64748B))),
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
