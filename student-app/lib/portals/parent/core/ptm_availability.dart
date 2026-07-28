// PTM availability engine — a direct Dart port of the desktop
// `src/lib/teacherAvailability.ts` + the meeting-mode helpers from
// `src/lib/ptm.ts`. Pure functions (no new deps) so the parent's PTM booking
// flow offers the SAME real bookable times the desktop does: a teacher's own
// configured weekly meeting hours, minus blocked dates, minus already-booked
// slots. Nobody can pick a time the teacher never actually opened up.
//
// `TeacherAvailability` rows live in the raw `TeacherAvailability` entity
// ({ id: teacherId, teacherName, weeklySlots: [{day, slots:[{start,end}]}],
// blockedDates: [...], slotDurationMinutes }). Class.teacher and
// subject_assignments only ever store a teacher NAME, so the parent-side lookup
// matches availability by name (getTeacherAvailabilityByName).

import '../core/api_client.dart';

const int kDefaultSlotDurationMinutes = 15;

// A teacher's configured availability, decoded from a `TeacherAvailability` row.
class TeacherAvailability {
  final String teacherName;
  // day-name → list of {start:"15:00", end:"16:00"} ranges.
  final Map<String, List<Map<String, String>>> weeklySlots;
  final Set<String> blockedDates; // ISO "YYYY-MM-DD"
  final int slotDurationMinutes;

  const TeacherAvailability({
    required this.teacherName,
    required this.weeklySlots,
    required this.blockedDates,
    required this.slotDurationMinutes,
  });

  factory TeacherAvailability.fromJson(Map<String, dynamic> json) {
    final weekly = <String, List<Map<String, String>>>{};
    final rawWeekly = json['weeklySlots'];
    if (rawWeekly is List) {
      for (final d in rawWeekly) {
        if (d is! Map) continue;
        final day = (d['day'] ?? '').toString();
        if (day.isEmpty) continue;
        final ranges = <Map<String, String>>[];
        final rawSlots = d['slots'];
        if (rawSlots is List) {
          for (final s in rawSlots) {
            if (s is! Map) continue;
            final start = (s['start'] ?? '').toString();
            final end = (s['end'] ?? '').toString();
            if (start.isNotEmpty && end.isNotEmpty) {
              ranges.add({'start': start, 'end': end});
            }
          }
        }
        weekly[day] = ranges;
      }
    }
    final blocked = <String>{};
    final rawBlocked = json['blockedDates'];
    if (rawBlocked is List) {
      for (final b in rawBlocked) {
        final v = b?.toString() ?? '';
        if (v.isNotEmpty) blocked.add(v.length > 10 ? v.substring(0, 10) : v);
      }
    }
    final dur = int.tryParse(json['slotDurationMinutes']?.toString() ?? '') ??
        kDefaultSlotDurationMinutes;
    return TeacherAvailability(
      teacherName: (json['teacherName'] ?? '').toString(),
      weeklySlots: weekly,
      blockedDates: blocked,
      slotDurationMinutes: dur <= 0 ? kDefaultSlotDurationMinutes : dur,
    );
  }
}

int _toMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return 0;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h * 60 + m;
}

// "3:15 PM" — the exact display format the desktop stores as a PTMSession
// `timeRange`, so booked-slot de-duplication compares like-for-like.
String _fromMinutes(int mins) {
  final h = (mins ~/ 60) % 24;
  final m = mins % 60;
  final period = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $period';
}

// Expand a configured block (e.g. 3:00 PM – 4:00 PM) into individual bookable
// start times at a fixed increment (so the parent picks "3:00 PM", "3:15 PM"…).
List<String> expandToSlots(Map<String, String> range, int incrementMinutes) {
  final start = _toMinutes(range['start'] ?? '');
  final end = _toMinutes(range['end'] ?? '');
  final out = <String>[];
  for (int t = start; t + incrementMinutes <= end; t += incrementMinutes) {
    out.add(_fromMinutes(t));
  }
  return out;
}

const List<String> _weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

// Day-of-week name for an ISO date "YYYY-MM-DD". DateTime.weekday is 1=Mon..7=Sun.
String dayOfWeekFor(String dateStr) {
  final d = DateTime.tryParse('${dateStr}T00:00:00');
  if (d == null) return '';
  return _weekdayNames[(d.weekday - 1).clamp(0, 6)];
}

// Real bookable slots for a teacher on a date: their configured weekly blocks
// for that weekday, expanded to increments, minus a fully-blocked date, minus
// times already booked (any non-Cancelled PTMSession for this teacher/date).
List<String> computeAvailableSlots(
  TeacherAvailability? availability,
  String date,
  List<String> alreadyBookedTimes, {
  int? incrementMinutes,
}) {
  if (availability == null) return const [];
  if (availability.blockedDates.contains(date)) return const [];
  final day = dayOfWeekFor(date);
  final dayConfig = availability.weeklySlots[day];
  if (dayConfig == null || dayConfig.isEmpty) return const [];
  final inc = incrementMinutes ?? availability.slotDurationMinutes;
  final all = <String>[];
  for (final r in dayConfig) {
    all.addAll(expandToSlots(r, inc));
  }
  final booked = alreadyBookedTimes.toSet();
  return all.where((t) => !booked.contains(t)).toList();
}

// Read the `TeacherAvailability` row whose teacherName matches (case-insensitive)
// — the join path from a Class/subject_assignments teacher NAME to their real
// configured hours. Returns null when the teacher hasn't set availability.
Future<TeacherAvailability?> getTeacherAvailabilityByName(String teacherName) async {
  final target = teacherName.trim().toLowerCase();
  if (target.isEmpty) return null;
  try {
    final rows = await ApiClient.instance.getAll('TeacherAvailability');
    for (final r in rows) {
      if ((r['teacherName'] ?? '').toString().trim().toLowerCase() == target) {
        return TeacherAvailability.fromJson(r);
      }
    }
  } catch (_) {}
  return null;
}

// ── Meeting-mode helpers (ported from ptm.ts) ────────────────────────────────

// A real, working Jitsi Meet link — the only platform we can generate without a
// third-party API key. `seed` varies the room; the timestamp keeps it unique.
String generateJitsiLink(String seed) {
  final slug = seed.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-');
  final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  return 'https://meet.jit.si/StudentDiwan-PTM-$slug-$ts';
}

// The mode actually in effect for a session: Hybrid resolves to whatever the
// parent picked (or "Awaiting Choice" until they do).
String effectiveMode(String meetingMode, String? bookedMode) {
  if (meetingMode != 'Hybrid') return meetingMode;
  if (bookedMode == null || bookedMode.isEmpty) return 'Awaiting Choice';
  return bookedMode == 'Online' ? 'Online' : 'Offline';
}

// One-line human summary of where/how the meeting happens (for list rows).
String meetingSummary(Map<String, dynamic> s) {
  final mode = effectiveMode(
    (s['meetingMode'] ?? '').toString(),
    s['bookedMode']?.toString(),
  );
  if (mode == 'Awaiting Choice') return "Awaiting parent's mode choice";
  if (mode == 'Online') {
    final platform = (s['platform'] ?? '').toString();
    return platform.isNotEmpty ? 'Online — $platform' : 'Online meeting';
  }
  final parts = <String>[];
  final room = (s['roomNumber'] ?? '').toString();
  final building = (s['building'] ?? '').toString();
  final campus = (s['campus'] ?? '').toString();
  if (room.isNotEmpty) parts.add('Room $room');
  if (building.isNotEmpty) parts.add(building);
  if (campus.isNotEmpty) parts.add(campus);
  if (parts.isNotEmpty) return parts.join(', ');
  final location = (s['location'] ?? '').toString();
  return location.isNotEmpty ? location : 'Offline — campus';
}
