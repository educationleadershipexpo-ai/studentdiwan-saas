import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/ptm_availability.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// Real Parent-Teacher Meeting booking — a faithful port of the desktop
// ParentPTM.tsx. Reads the shared `PTMSession` rows, offers only the child's
// really-assigned teachers, and books against each teacher's own configured
// availability (already-booked times hidden). Every write hits real backend
// entities (PTMSession / CalendarEvent / notifications) — no mock/seed data.

class PtmScreen extends ConsumerWidget {
  const PtmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBackHeader(
        title: 'PTM Booking',
        actions: [
          if (kid != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _openBookSheet(context, ref, kid),
                icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                label: const Text('Book',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
            ),
        ],
      ),
      body: kid == null
          ? const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No Child Selected',
              subtitle: 'Select a child from Settings to book and view Parent-Teacher Meetings.',
            )
          : _PtmBody(kid: kid),
    );
  }

  static Future<void> _openBookSheet(BuildContext context, WidgetRef ref, StudentModel kid) async {
    final booked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookSheet(kid: kid),
    );
    if (booked == true) {
      ref.invalidate(parentPtmSessionsProvider(kid));
      ref.invalidate(calendarEventsProvider);
    }
  }
}

class _PtmBody extends ConsumerWidget {
  final StudentModel kid;
  const _PtmBody({required this.kid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(parentPtmSessionsProvider(kid));

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => ErrorState(
        message: 'Failed to load meetings',
        onRetry: () => ref.invalidate(parentPtmSessionsProvider(kid)),
      ),
      data: (sessions) {
        final pending = sessions.where((s) => (s['status'] ?? '') == 'Pending').length;
        final scheduled = sessions.where((s) {
          final st = (s['status'] ?? '').toString();
          return st == 'Scheduled' || st == 'Checked In' || st == 'In Progress';
        }).length;
        final completed = sessions.where((s) => (s['status'] ?? '') == 'Completed').length;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(parentPtmSessionsProvider(kid)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // Summary counts
              Row(children: [
                _SummaryCard(label: 'Awaiting', value: pending, color: AppColors.amber, bg: AppColors.amberLight),
                const SizedBox(width: 10),
                _SummaryCard(label: 'Scheduled', value: scheduled, color: AppColors.primary, bg: AppColors.primaryExtraLight),
                const SizedBox(width: 10),
                _SummaryCard(label: 'Completed', value: completed, color: AppColors.green, bg: AppColors.greenLight),
              ]),
              const SizedBox(height: 8),
              const SectionHeader(title: 'Meeting History'),
              if (sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'No Meetings Yet',
                    subtitle: 'Tap "Book" to request a Parent-Teacher Meeting.',
                  ),
                )
              else
                ...sessions.map((s) => _MeetingCard(
                      session: s,
                      onCancel: () => _confirmCancel(context, ref, s),
                    )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref, Map<String, dynamic> s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Meeting?'),
        content: Text(
          'Cancel your meeting with ${(s['teacher'] ?? 'the teacher')} on ${(s['date'] ?? '')}? The teacher will be notified.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Meeting', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final uid = ref.read(authProvider).user?.uid ?? '';
    try {
      await PtmService.cancel(session: s, parentUid: uid);
      ref.invalidate(parentPtmSessionsProvider(kid));
      ref.invalidate(calendarEventsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting cancelled.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t cancel. Please try again.')),
        );
      }
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;
  const _SummaryCard({required this.label, required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.event_rounded, size: 17, color: color),
          ),
          const SizedBox(height: 8),
          Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.text3)),
        ]),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onCancel;
  const _MeetingCard({required this.session, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final teacher = (session['teacher'] ?? 'Teacher').toString();
    final status = (session['status'] ?? '').toString();
    final date = (session['date'] ?? '').toString();
    final time = (session['timeRange'] ?? session['nextSlot'] ?? '').toString();
    final subject = (session['subject'] ?? '').toString();
    final mode = effectiveMode(
      (session['meetingMode'] ?? '').toString(),
      session['bookedMode']?.toString(),
    );
    final meetingLink = (session['meetingLink'] ?? '').toString();
    final isOnline = mode == 'Online';
    final canCancel = status == 'Pending' || status == 'Scheduled' || status == 'Checked In';

    return WhiteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(teacher, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text1)),
              if (subject.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subject, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.text3)),
              ],
            ]),
          ),
          _PtmStatusPill(status: status),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _MetaChip(icon: Icons.calendar_today_rounded, label: date.isEmpty ? '—' : date),
          const SizedBox(width: 8),
          _MetaChip(icon: Icons.access_time_rounded, label: time.isEmpty ? '—' : time),
          const SizedBox(width: 8),
          _ModeBadge(mode: mode),
        ]),
        if (isOnline && meetingLink.isNotEmpty) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(meetingLink);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.videocam_rounded, size: 15, color: AppColors.blue),
              SizedBox(width: 6),
              Text('Join Meeting',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.blue, decoration: TextDecoration.underline)),
            ]),
          ),
        ] else if (!isOnline) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.place_outlined, size: 14, color: AppColors.text3),
            const SizedBox(width: 6),
            Expanded(
              child: Text(meetingSummary(session),
                  style: const TextStyle(fontSize: 12, color: AppColors.text2)),
            ),
          ]),
        ],
        if ((session['meetingNotes'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Note: ${session['meetingNotes']}',
              style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.text3)),
        ],
        if (canCancel) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.red)),
            ),
          ),
        ],
      ]),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.text3),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2)),
      ]),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String mode;
  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    IconData icon;
    if (mode == 'Online') {
      bg = AppColors.blueLight; fg = AppColors.blue; icon = Icons.videocam_rounded;
    } else if (mode == 'Offline') {
      bg = AppColors.greenLight; fg = AppColors.green; icon = Icons.apartment_rounded;
    } else {
      bg = AppColors.amberLight; fg = AppColors.amber; icon = Icons.help_outline_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 4),
        Text(mode, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}

class _PtmStatusPill extends StatelessWidget {
  final String status;
  const _PtmStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    // "Pending" surfaces to the parent as "Awaiting Confirmation" (matches desktop).
    final label = status == 'Pending' ? 'Awaiting Confirmation' : status;
    Color bg, fg;
    switch (status) {
      case 'Completed':
        bg = AppColors.greenLight; fg = AppColors.green; break;
      case 'Cancelled':
      case 'No Show':
        bg = AppColors.redLight; fg = AppColors.red; break;
      case 'Scheduled':
      case 'Checked In':
      case 'In Progress':
      case 'Rescheduled':
        bg = AppColors.primaryExtraLight; fg = AppColors.primary; break;
      default: // Pending
        bg = AppColors.amberLight; fg = AppColors.amber;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

// ── Book sheet ────────────────────────────────────────────────────────────────
class _BookSheet extends ConsumerStatefulWidget {
  final StudentModel kid;
  const _BookSheet({required this.kid});

  @override
  ConsumerState<_BookSheet> createState() => _BookSheetState();
}

class _BookSheetState extends ConsumerState<_BookSheet> {
  String _meetingWith = ''; // "Class Teacher" | "Subject Teacher"
  AssignedTeacher? _teacher;
  String _meetingType = 'Offline';
  DateTime? _date;
  String? _time;
  final _purposeController = TextEditingController();

  List<String> _slots = const [];
  bool _slotsLoading = false;
  bool _booking = false;

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  String get _dateIso => _date == null ? '' : DateFormat('yyyy-MM-dd').format(_date!);

  Future<void> _loadSlots() async {
    final t = _teacher;
    if (t == null || _date == null) {
      setState(() => _slots = const []);
      return;
    }
    setState(() { _slotsLoading = true; _time = null; });
    try {
      final availability = await getTeacherAvailabilityByName(t.name);
      final allSessions = await ApiClient.instance.getAll('PTMSession').catchError((_) => <Map<String, dynamic>>[]);
      final alreadyBooked = allSessions
          .where((s) =>
              (s['teacher'] ?? '') == t.name &&
              (s['date'] ?? '') == _dateIso &&
              (s['status'] ?? '') != 'Cancelled')
          .map((s) => (s['timeRange'] ?? '').toString())
          .toList();
      final slots = computeAvailableSlots(availability, _dateIso, alreadyBooked);
      if (mounted) setState(() { _slots = slots; _slotsLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _slots = const []; _slotsLoading = false; });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _loadSlots();
    }
  }

  Future<void> _book() async {
    final t = _teacher;
    if (_meetingWith.isEmpty || t == null || _date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose who to meet, a date, and a time slot.')),
      );
      return;
    }
    final me = ref.read(authProvider).user;
    setState(() => _booking = true);
    try {
      await PtmService.book(
        kid: widget.kid,
        parentName: me?.displayName ?? 'Parent',
        parentUid: me?.uid ?? '',
        teacherName: t.name,
        meetingWith: _meetingWith,
        meetingType: _meetingType,
        time: _time!,
        date: _dateIso,
        subject: t.subject,
        purpose: _purposeController.text,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${t.name} — you\'ll be notified once they confirm.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _booking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t book the meeting. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(assignedTeachersProvider(widget.kid));

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Grabber + header
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.text3.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Book a Meeting', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.text1)),
                const SizedBox(height: 2),
                Text('For ${widget.kid.fullName} · ${widget.kid.gradeLabel}',
                    style: const TextStyle(fontSize: 12, color: AppColors.text3, fontWeight: FontWeight.w500)),
              ]),
            ),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.text3)),
          ]),
        ),
        Flexible(
          child: teachersAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(30),
              child: ErrorState(message: 'Failed to load teachers'),
            ),
            data: (teachers) {
              final forRole = teachers.where((t) => t.role == _meetingWith).toList();
              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                children: [
                  _label('Meeting With'),
                  Row(children: [
                    _choice('Class Teacher', Icons.school_rounded, _meetingWith == 'Class Teacher', () {
                      setState(() { _meetingWith = 'Class Teacher'; _teacher = null; _date = null; _time = null; _slots = const []; });
                    }),
                    const SizedBox(width: 10),
                    _choice('Subject Teacher', Icons.menu_book_rounded, _meetingWith == 'Subject Teacher', () {
                      setState(() { _meetingWith = 'Subject Teacher'; _teacher = null; _date = null; _time = null; _slots = const []; });
                    }),
                  ]),
                  if (teachers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('No teachers are assigned to ${widget.kid.fullName}\'s class yet — contact the school office.',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.amber, fontWeight: FontWeight.w600)),
                    ),

                  if (_meetingWith.isNotEmpty) ...[
                    _label('Teacher'),
                    if (forRole.isEmpty)
                      Text('No ${_meetingWith.toLowerCase()} assigned yet.',
                          style: const TextStyle(fontSize: 12, color: AppColors.text3))
                    else
                      ...forRole.map((t) {
                        final selected = _teacher?.name == t.name && _teacher?.subject == t.subject;
                        return GestureDetector(
                          onTap: () {
                            setState(() { _teacher = t; _date = null; _time = null; _slots = const []; });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primaryExtraLight : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.5),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Text(t.subject != null && t.subject!.isNotEmpty ? '${t.name} — ${t.subject}' : t.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
                              ),
                              if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                            ]),
                          ),
                        );
                      }),
                  ],

                  if (_teacher != null) ...[
                    _label('Meeting Type'),
                    Row(children: [
                      _choice('Offline', Icons.apartment_rounded, _meetingType == 'Offline',
                          () => setState(() => _meetingType = 'Offline')),
                      const SizedBox(width: 10),
                      _choice('Online', Icons.videocam_rounded, _meetingType == 'Online',
                          () => setState(() => _meetingType = 'Online')),
                    ]),

                    _label('Date'),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEDE6F8)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(_date == null ? 'Select a date' : DateFormat('EEE, d MMM yyyy').format(_date!),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _date == null ? AppColors.text3 : AppColors.text1)),
                        ]),
                      ),
                    ),

                    _label('Preferred Time'),
                    if (_date == null)
                      Text('Pick a date to see ${_teacher!.name.split(' ').first}\'s open times.',
                          style: const TextStyle(fontSize: 12, color: AppColors.text3))
                    else if (_slotsLoading)
                      const Text('Loading available times…', style: TextStyle(fontSize: 12, color: AppColors.text3))
                    else if (_slots.isEmpty)
                      const Text('No open slots that day — try another date.',
                          style: TextStyle(fontSize: 12, color: AppColors.amber, fontWeight: FontWeight.w600))
                    else
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _slots.map((t) {
                          final sel = _time == t;
                          return GestureDetector(
                            onTap: () => setState(() => _time = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: sel ? AppColors.primary : const Color(0xFFEDE6F8)),
                              ),
                              child: Text(t,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? Colors.white : AppColors.text1)),
                            ),
                          );
                        }).toList(),
                      ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Only the teacher\'s own configured hours are shown — already-booked times are hidden.',
                          style: TextStyle(fontSize: 11, color: AppColors.text3)),
                    ),

                    _label('Purpose (optional)'),
                    TextField(
                      controller: _purposeController,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 300,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 13, color: AppColors.text1),
                      decoration: InputDecoration(
                        hintText: 'e.g. Discuss recent exam performance…',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.text3),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        // Book action
        Container(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(color: Colors.white),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_booking || _teacher == null || _time == null) ? null : _book,
              child: _booking
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Book Slot'),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.text3, letterSpacing: 0.5)),
      );

  Widget _choice(String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryExtraLight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : const Color(0xFFEDE6F8), width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.text3),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.text2)),
          ]),
        ),
      ),
    );
  }
}
