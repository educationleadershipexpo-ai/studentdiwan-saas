import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';

// Live assignments for the logged-in student, read from /api/data/assignments.
// No mock rows — an empty result renders the empty state.
class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});
  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isSubmitted(AssignmentModel a) {
    final s = a.status.toLowerCase();
    return s == 'submitted' || s == 'graded';
  }

  bool _isOverdue(AssignmentModel a) {
    if (a.status.toLowerCase() == 'overdue') return true;
    if (_isSubmitted(a)) return false;
    final due = DateTime.tryParse(a.dueDate);
    if (due == null) return false;
    return due.isBefore(DateTime.now());
  }

  List<AssignmentModel> _filter(List<AssignmentModel> all) {
    final q = _searchQuery.toLowerCase();
    return all.where((a) {
      final matchSearch = q.isEmpty ||
          a.title.toLowerCase().contains(q) ||
          a.subject.toLowerCase().contains(q);
      final tab = _tabController.index;
      if (tab == 1) return matchSearch && _isSubmitted(a);
      if (tab == 2) return matchSearch && _isOverdue(a);
      return matchSearch && !_isSubmitted(a);
    }).toList();
  }

  Color _statusColor(AssignmentModel a) {
    final s = a.status.toLowerCase();
    if (s == 'submitted') return AppColors.green;
    if (s == 'graded') return AppColors.primary;
    if (_isOverdue(a)) return AppColors.red;
    return AppColors.amber;
  }

  String _statusLabel(AssignmentModel a) {
    if (_isOverdue(a) && a.status.toLowerCase() == 'pending') return 'Overdue';
    return a.status.isEmpty ? 'Pending' : a.status;
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);
    final all = assignmentsAsync.value ?? const <AssignmentModel>[];
    final pending = all.where((a) => !_isSubmitted(a)).length;
    final submitted = all.where(_isSubmitted).length;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 140,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Assignments', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('$pending pending · $submitted submitted',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [Tab(text: 'Pending'), Tab(text: 'Submitted'), Tab(text: 'Overdue')],
            ),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search assignments...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.text3),
                  filled: true, fillColor: context.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: assignmentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _emptyState('Could not load assignments right now.'),
                data: (list) {
                  final filtered = _filter(list);
                  if (filtered.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(studentAssignmentsProvider),
                      child: ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          _emptyBody(list.isEmpty
                              ? 'No assignments have been posted yet.'
                              : 'No assignments in this tab.'),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(studentAssignmentsProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final a = filtered[i];
                        return _AssignmentCard(
                          assignment: a,
                          statusColor: _statusColor(a),
                          statusLabel: _statusLabel(a),
                          submitted: _isSubmitted(a),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) => Center(child: _emptyBody(message));

  Widget _emptyBody(String message) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_outlined, size: 64, color: AppColors.text3),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.text3, fontSize: 15)),
        ],
      );
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final Color statusColor;
  final String statusLabel;
  final bool submitted;
  const _AssignmentCard({
    required this.assignment,
    required this.statusColor,
    required this.statusLabel,
    required this.submitted,
  });

  String _fmtDate(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.assignment_rounded, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text1), maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (a.subject.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(a.subject, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2)),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.text3),
                const SizedBox(width: 4),
                Text(a.dueDate.isEmpty ? 'No due date' : 'Due: ${_fmtDate(a.dueDate)}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2)),
                const Spacer(),
                if (a.score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(8)),
                    child: Text('Score: ${a.score}/${a.points}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  )
                else if (!submitted)
                  Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.upload_file_rounded, size: 14, color: Colors.white),
                        label: const Text('Submit', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => _showSubmissionModal(context, ref, a),
                      );
                    },
                  )
                else if (a.points > 0)
                  Text('${a.points} marks', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmissionModal(BuildContext context, WidgetRef ref, AssignmentModel a) {
    final controller = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Submit Response', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(a.title, style: const TextStyle(color: AppColors.text2, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter your response text or file link...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: submitting ? null : () async {
                    if (controller.text.trim().isEmpty) return;
                    setState(() => submitting = true);
                    try {
                      await submitAssignmentSubmission(ref, assignmentId: a.id, content: controller.text.trim());
                      ref.invalidate(studentAssignmentsProvider);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Assignment submitted successfully!'), backgroundColor: AppColors.green),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        setState(() => submitting = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Could not submit: $e')),
                        );
                      }
                    }
                  },
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Turn In Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

