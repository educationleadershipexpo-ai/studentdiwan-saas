import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/api_client.dart';
import '../providers/data_provider.dart';

class BehaviorScreen extends ConsumerStatefulWidget {
  const BehaviorScreen({super.key});

  @override
  ConsumerState<BehaviorScreen> createState() => _BehaviorScreenState();
}

class _BehaviorScreenState extends ConsumerState<BehaviorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _studentCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _severity = 'Low';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _studentCtrl.dispose();
    _typeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Behavior', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(teacherBehaviorScopedProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.text3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'All Incidents'),
            Tab(text: 'By Student'),
            Tab(text: 'Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildAllIncidents(),
          _buildByStudent(),
          _buildReportForm(),
        ],
      ),
    );
  }

  Widget _buildAllIncidents() {
    final async = ref.watch(teacherBehaviorScopedProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => _errorState(e.toString(), () => ref.invalidate(teacherBehaviorScopedProvider)),
      data: (incidents) {
        if (incidents.isEmpty) {
          return _emptyState(Icons.verified_user_outlined, 'No behavior incidents', 'No incident records found in the system.');
        }
        final total = incidents.length;
        final resolved = incidents.where((i) => (i['status'] ?? '').toString().toLowerCase() == 'resolved').length;
        final active = total - resolved;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(teacherBehaviorScopedProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incidents.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      _buildStatCard('$total', 'Total', AppColors.primary),
                      const SizedBox(width: 10),
                      _buildStatCard('$resolved', 'Resolved', AppColors.green),
                      const SizedBox(width: 10),
                      _buildStatCard('$active', 'Active', AppColors.amber),
                    ],
                  ),
                );
              }
              final inc = incidents[i - 1];
              final sev = (inc['severity'] ?? 'Low').toString();
              final sevColor = sev == 'High' || sev == 'Critical' ? AppColors.red : sev == 'Medium' ? AppColors.amber : AppColors.green;
              final status = (inc['status'] ?? inc['category'] ?? '').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryExtraLight)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: sevColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                          child: Text(sev, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: sevColor)),
                        ),
                        const Spacer(),
                        Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text3)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text((inc['studentName'] ?? 'Unknown Student').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text1)),
                    const SizedBox(height: 2),
                    Text('${inc['type'] ?? ''}  ${_fmtDate(inc['date'])}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
                    if ((inc['description'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(inc['description'].toString(), style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2)),
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

  Widget _buildByStudent() {
    final async = ref.watch(teacherBehaviorScopedProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => _errorState(e.toString(), () => ref.invalidate(teacherBehaviorScopedProvider)),
      data: (incidents) {
        if (incidents.isEmpty) {
          return _emptyState(Icons.groups_outlined, 'No student records', 'No behavior data to summarize yet.');
        }
        final Map<String, List<Map<String, dynamic>>> byStudent = {};
        for (final inc in incidents) {
          final name = (inc['studentName'] ?? 'Unknown').toString();
          byStudent.putIfAbsent(name, () => []).add(inc);
        }
        final entries = byStudent.entries.toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(teacherBehaviorScopedProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              final count = e.value.length;
              final highCount = e.value.where((x) => (x['severity'] ?? '') == 'High' || (x['severity'] ?? '') == 'Critical').length;
              final color = highCount > 0 ? AppColors.red : count > 2 ? AppColors.amber : AppColors.green;
              return _buildStudentBehavior(e.key, count, highCount, color);
            },
          ),
        );
      },
    );
  }

  Widget _buildStudentBehavior(String name, int count, int highCount, Color color) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty ? '?' : parts.map((e) => e[0]).take(2).join();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryExtraLight)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.15),
            child: Text(initials.toUpperCase(), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text1)),
                Text(highCount > 0 ? '$highCount high-severity' : 'No high-severity incidents', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
              ],
            ),
          ),
          Column(
            children: [
              Text('$count', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              Text('incidents', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportForm() {
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
                Text('Report an Incident', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text1)),
                const SizedBox(height: 16),
                TextField(controller: _studentCtrl, decoration: const InputDecoration(labelText: 'Student Name', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
                TextField(controller: _typeCtrl, decoration: const InputDecoration(labelText: 'Incident Type (e.g. Demerit, Merit)', prefixIcon: Icon(Icons.warning_amber_rounded))),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined), alignLabelWithHint: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _severity,
                  decoration: const InputDecoration(labelText: 'Severity', prefixIcon: Icon(Icons.flag_outlined)),
                  items: ['Low', 'Medium', 'High'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) => setState(() => _severity = v ?? 'Low'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submitIncident,
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_submitting ? 'Submitting...' : 'Submit Report'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitIncident() async {
    if (_studentCtrl.text.trim().isEmpty || _typeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student name and incident type are required'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.createRecord('BehaviorRecord', {
        'studentName': _studentCtrl.text.trim(),
        'type': _typeCtrl.text.trim(),
        'severity': _severity,
        'category': 'Conduct',
        'description': _descCtrl.text.trim(),
        'date': DateTime.now().toIso8601String().split('T').first,
        'status': 'Active',
      });
      if (!mounted) return;
      _studentCtrl.clear();
      _typeCtrl.clear();
      _descCtrl.clear();
      setState(() => _severity = 'Low');
      ref.invalidate(teacherBehaviorScopedProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident reported successfully'), behavior: SnackBarBehavior.floating),
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

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text3)),
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
