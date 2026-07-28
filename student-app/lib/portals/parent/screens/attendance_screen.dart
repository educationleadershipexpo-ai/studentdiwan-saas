import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));

    final attAsync = ref.watch(attendanceProvider(kid));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBackHeader(title: 'Attendance · ${kid.firstName}'),
      body: attAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(message: 'Failed to load attendance', onRetry: () => ref.invalidate(attendanceProvider(kid))),
        data: (records) {
          final monthRecords = records.where((r) => r.date.year == _month.year && r.date.month == _month.month).toList();
          // A school day is any date the teacher actually marked. "Present" also
          // covers the partial-presence codes (Late / Half day) for the top-line
          // count; Absent and Excused/Sick are counted on their own.
          final present = monthRecords.where((r) => r.status == 'Present').length;
          final late = monthRecords.where((r) => r.status == 'Late').length;
          final halfDay = monthRecords.where((r) => r.status == 'Half day').length;
          final excused = monthRecords.where((r) => r.status == 'Excused' || r.status == 'Sick').length;
          final absent = monthRecords.where((r) => r.status == 'Absent').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Summary — Present / Absent / Late always shown; Half day and
              // Excused appear only when the teacher actually recorded them, so
              // the row never invents statuses the school didn't use.
              Row(children: [
                _AttStat('$present', 'Present', AppColors.green),
                const SizedBox(width: 8),
                _AttStat('$absent', 'Absent', AppColors.red),
                const SizedBox(width: 8),
                _AttStat('$late', 'Late', AppColors.amber),
              ]),
              if (halfDay > 0 || excused > 0) ...[
                const SizedBox(height: 8),
                Row(children: [
                  if (halfDay > 0) ...[
                    _AttStat('$halfDay', 'Half day', AppColors.blue),
                    const SizedBox(width: 8),
                  ],
                  if (excused > 0)
                    _AttStat('$excused', 'Excused', AppColors.primary),
                  // Keep the row balanced when only one extra stat is present.
                  if (!(halfDay > 0 && excused > 0)) ...[
                    const SizedBox(width: 8),
                    const Spacer(),
                  ],
                ]),
              ],
              const SizedBox(height: 16),

              // Request an absence — real submission to the class teacher.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openRequestSheet(kid),
                  icon: const Icon(Icons.event_busy_rounded, size: 18),
                  label: const Text('Request Absence'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Month nav
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 10)]),
                child: Row(children: [
                  _MonthBtn(icon: Icons.chevron_left_rounded, onTap: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
                  Expanded(child: Text(DateFormat('MMMM yyyy').format(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text1))),
                  _MonthBtn(icon: Icons.chevron_right_rounded, onTap: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
                ]),
              ),
              const SizedBox(height: 12),

              // Calendar
              _AttendanceCalendar(month: _month, records: monthRecords),
              const SizedBox(height: 12),

              // Legend — only the statuses this school actually records.
              Wrap(spacing: 14, runSpacing: 6, children: [
                const _Legend(color: AppColors.green, label: 'Present'),
                const _Legend(color: AppColors.red, label: 'Absent'),
                const _Legend(color: AppColors.amber, label: 'Late'),
                if (halfDay > 0) const _Legend(color: AppColors.blue, label: 'Half day'),
                if (excused > 0) const _Legend(color: AppColors.primary, label: 'Excused'),
              ]),
              const SizedBox(height: 20),

              // My absence requests — real submissions, reviewed by the teacher.
              _MyRequests(studentId: kid.id),
            ]),
          );
        },
      ),
    );
  }

  void _openRequestSheet(StudentModel kid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AbsenceRequestSheet(kid: kid),
    ).then((submitted) {
      if (submitted == true) ref.invalidate(absenceRequestsProvider(kid.id));
    });
  }
}

// ── My Absence Requests panel ──────────────────────────────────────────────────
class _MyRequests extends ConsumerWidget {
  final String studentId;
  const _MyRequests({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reqAsync = ref.watch(absenceRequestsProvider(studentId));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('My Absence Requests',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text1)),
      const SizedBox(height: 8),
      reqAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
        ),
        error: (_, __) => const Text('Could not load requests.', style: TextStyle(fontSize: 12, color: AppColors.text3)),
        data: (reqs) {
          if (reqs.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8)]),
              child: const Text('No absence requests submitted yet.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.text3)),
            );
          }
          return Column(children: reqs.map(_requestCard).toList());
        },
      ),
    ]);
  }

  Widget _requestCard(AbsenceRequestModel r) {
    final s = r.status.toLowerCase();
    final Color clr = s == 'approved'
        ? AppColors.green
        : s == 'rejected'
            ? AppColors.red
            : AppColors.amber;
    final Color bg = s == 'approved'
        ? AppColors.greenLight
        : s == 'rejected'
            ? AppColors.redLight
            : AppColors.amberLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8)]),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${r.date} — ${r.reason}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
          if (r.note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(r.note, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
          ],
        ])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(r.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: clr)),
        ),
      ]),
    );
  }
}

// ── Absence request bottom sheet ────────────────────────────────────────────────
class _AbsenceRequestSheet extends ConsumerStatefulWidget {
  final StudentModel kid;
  const _AbsenceRequestSheet({required this.kid});
  @override
  ConsumerState<_AbsenceRequestSheet> createState() => _AbsenceRequestSheetState();
}

class _AbsenceRequestSheetState extends ConsumerState<_AbsenceRequestSheet> {
  static const _reasons = [
    'Medical / Illness',
    'Family Emergency',
    'Travel',
    'Religious Occasion',
    'Other',
  ];
  DateTime? _date;
  String? _reason;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_date == null || _reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date and reason are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    final user = ref.read(authProvider).user;
    try {
      await AbsenceService.submit(
        kid: widget.kid,
        parentUid: user?.uid ?? '',
        parentEmail: user?.email ?? '',
        date: DateFormat('yyyy-MM-dd').format(_date!),
        reason: _reason!,
        note: _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absence request submitted to the school.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit absence request. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.text3.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          const Text('Absence Request',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.text1)),
          const SizedBox(height: 4),
          Text('For ${widget.kid.fullName}',
              style: const TextStyle(fontSize: 12, color: AppColors.text3)),
          const SizedBox(height: 16),

          // Date
          const Text('Date of Absence *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text2)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE6F5))),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(_date == null ? 'Select date' : DateFormat('EEE, d MMM yyyy').format(_date!),
                    style: TextStyle(fontSize: 13, color: _date == null ? AppColors.text3 : AppColors.text1, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // Reason
          const Text('Reason *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text2)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDE6F5))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _reason,
                isExpanded: true,
                hint: const Text('Select reason', style: TextStyle(fontSize: 13, color: AppColors.text3)),
                items: _reasons.map((r) => DropdownMenuItem(value: r,
                    child: Text(r, style: const TextStyle(fontSize: 13, color: AppColors.text1)))).toList(),
                onChanged: (v) => setState(() => _reason = v),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Note
          const Text('Additional Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text2)),
          const SizedBox(height: 6),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Optional details…',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.text3),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDE6F5))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 20),

          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text2,
                  side: const BorderSide(color: Color(0xFFDDE6F5)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _AttStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _AttStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 10)]),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.text3, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _MonthBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MonthBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: AppColors.primary, size: 20),
    ),
  );
}

class _AttendanceCalendar extends StatelessWidget {
  final DateTime month;
  final List<AttendanceRecord> records;
  const _AttendanceCalendar({required this.month, required this.records});

  @override
  Widget build(BuildContext context) {
    final Map<int, String> statusMap = {for (final r in records) r.date.day: r.status};
    final firstDay = DateTime(month.year, month.month, 1);
    final startOffset = firstDay.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 10)]),
      child: Column(children: [
        Row(children: ['Su','Mo','Tu','We','Th','Fr','Sa'].map((d) =>
          Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text3))))).toList()),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startOffset) return const SizedBox.shrink();
            final day = i - startOffset + 1;
            final status = statusMap[day];
            final isToday = today.year == month.year && today.month == month.month && today.day == day;

            Color bg = Colors.transparent;
            Color fg = AppColors.text2;
            if (status == 'Present') { bg = AppColors.greenLight; fg = AppColors.green; }
            else if (status == 'Absent') { bg = AppColors.redLight; fg = AppColors.red; }
            else if (status == 'Late') { bg = AppColors.amberLight; fg = AppColors.amber; }
            else if (status == 'Half day') { bg = AppColors.blueLight; fg = AppColors.blue; }
            else if (status == 'Excused' || status == 'Sick') { bg = AppColors.primaryExtraLight; fg = AppColors.primary; }

            return Container(
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
              ),
              child: Center(child: Text('$day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isToday ? AppColors.primary : fg))),
            );
          },
        ),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2)),
  ]);
}
