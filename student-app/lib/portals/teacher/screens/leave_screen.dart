import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/api_client.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

class LeaveScreen extends ConsumerStatefulWidget {
  const LeaveScreen({super.key});

  @override
  ConsumerState<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends ConsumerState<LeaveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _typeCtrl = TextEditingController(text: 'Annual Leave');
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _typeCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Leave', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.invalidate(teacherLeaveProvider)),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.text3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'My Leaves'),
            Tab(text: 'Apply'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildMyLeaves(),
          _buildApplyForm(),
        ],
      ),
    );
  }

  Widget _buildMyLeaves() {
    final async = ref.watch(teacherLeaveProvider);
    final user = ref.watch(authProvider).user;
    final myName = (user?.displayName ?? '').toLowerCase().trim();
    final myId = (user?.teacherId ?? user?.uid ?? '').toLowerCase().trim();

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => _errorState(e.toString(), () => ref.invalidate(teacherLeaveProvider)),
      data: (all) {
        // "My Leaves" must only ever show the signed-in teacher's own requests —
        // matched by their real staffId (uid/teacherId) or staffName. It must
        // never fall back to other staff members' leave records.
        final leaves = all.where((l) {
          final sId = (l['staffId'] ?? '').toString().toLowerCase().trim();
          final sName = (l['staffName'] ?? '').toString().toLowerCase().trim();
          final byId = myId.isNotEmpty && sId.isNotEmpty && sId == myId;
          final byName = myName.isNotEmpty && sName.isNotEmpty &&
              (sName == myName || sName.contains(myName) || myName.contains(sName));
          return byId || byName;
        }).toList();
        if (leaves.isEmpty) {
          return _emptyState(Icons.beach_access_outlined, 'No leave requests',
              "You haven't applied for any leave yet. Use the Apply tab to submit a request.");
        }

        // Balances derived from real approved-days per type.
        final Map<String, int> usedByType = {};
        for (final l in leaves) {
          if ((l['status'] ?? '').toString().toLowerCase() == 'approved') {
            final t = (l['type'] ?? 'Other').toString();
            usedByType[t] = (usedByType[t] ?? 0) + ((l['days'] as num?)?.toInt() ?? 0);
          }
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(teacherLeaveProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaves.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                final sick = usedByType['Sick Leave'] ?? 0;
                final casual = usedByType['Casual Leave'] ?? 0;
                final annual = usedByType['Annual Leave'] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      _buildBalanceCard('Sick', sick, 10, AppColors.blue),
                      const SizedBox(width: 10),
                      _buildBalanceCard('Casual', casual, 12, AppColors.green),
                      const SizedBox(width: 10),
                      _buildBalanceCard('Annual', annual, 21, AppColors.amber),
                    ],
                  ),
                );
              }
              final leave = leaves[i - 1];
              final status = (leave['status'] ?? 'Pending').toString();
              final statusColor = status.toLowerCase() == 'approved' ? AppColors.green : status.toLowerCase() == 'rejected' ? AppColors.red : AppColors.amber;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryExtraLight)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text((leave['type'] ?? 'Leave').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text1)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                          child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.text3),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('${_fmtDate(leave['startDate'])} - ${_fmtDate(leave['endDate'])}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(6)),
                          child: Text('${(leave['days'] as num?)?.toInt() ?? 0} days', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    if ((leave['reason'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(leave['reason'].toString(), style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildApplyForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryExtraLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apply for Leave', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text1)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _typeCtrl.text,
                  decoration: const InputDecoration(labelText: 'Leave Type', prefixIcon: Icon(Icons.category_outlined)),
                  items: ['Sick Leave', 'Casual Leave', 'Annual Leave', 'Emergency Leave'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) => _typeCtrl.text = v ?? 'Annual Leave',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _fromCtrl, readOnly: true, onTap: () => _pickDate(_fromCtrl), decoration: const InputDecoration(labelText: 'From', prefixIcon: Icon(Icons.calendar_today_outlined)))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _toCtrl, readOnly: true, onTap: () => _pickDate(_toCtrl), decoration: const InputDecoration(labelText: 'To', prefixIcon: Icon(Icons.event_outlined)))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Reason', prefixIcon: Icon(Icons.notes_rounded), alignLabelWithHint: true),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submitLeave,
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_submitting ? 'Submitting...' : 'Submit Request'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submitLeave() async {
    final from = DateTime.tryParse(_fromCtrl.text);
    final to = DateTime.tryParse(_toCtrl.text);
    if (from == null || to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick both From and To dates'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final days = to.difference(from).inDays + 1;
    final user = ref.read(authProvider).user;
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.createRecord('leave_requests', {
        'staffId': user?.teacherId ?? user?.uid ?? '',
        'staffName': user?.displayName ?? 'Teacher',
        'type': _typeCtrl.text,
        'startDate': from.toIso8601String(),
        'endDate': to.toIso8601String(),
        'reason': _reasonCtrl.text.trim(),
        'status': 'Pending',
        'days': days < 1 ? 1 : days,
        'appliedOn': DateTime.now().toIso8601String(),
        'category': 'staff',
      });
      if (!mounted) return;
      _fromCtrl.clear();
      _toCtrl.clear();
      _reasonCtrl.clear();
      ref.invalidate(teacherLeaveProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted'), behavior: SnackBarBehavior.floating),
      );
      _tabCtrl.animateTo(0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildBalanceCard(String type, int used, int total, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          children: [
            Text('$used', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text('of $total', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3)),
            const SizedBox(height: 2),
            Text(type, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2)),
          ],
        ),
      ),
    );
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return '';
    final d = DateTime.tryParse(raw.toString());
    if (d == null) return raw.toString();
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.text3),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.red),
            const SizedBox(height: 12),
            Text('Could not load data', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text2)),
            const SizedBox(height: 6),
            Text(msg, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
