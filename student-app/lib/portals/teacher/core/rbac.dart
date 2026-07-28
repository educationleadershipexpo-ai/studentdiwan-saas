// ── Mobile RBAC for the staff (teacher) portal ──────────────────────────────
// Single source of truth for what a logged-in staff member may see in the
// mobile app. Mirrors the desktop web registry so a role's access is defined
// the same way in both places:
//   • role aliases          → src/lib/roles.ts (ALIASES + resolveRoleId)
//   • subject-teacher gating → src/components/dashboard/DashboardSidebar.tsx
//     (subjectTeacherExcludedTitles = Attendance, Behavior, PTM Booking)
//
// The desktop teacher ("staff") layout shows one flat menu to every teacher-
// layout role; only `subject_teacher` is narrowed — a subject teacher owns no
// homeroom, so attendance, behavior and parent-meeting booking (all homeroom
// duties) are hidden. Manager-tier roles (principal / vice principal /
// coordinators) that log into this mobile app get the full teacher menu.
//
// No data is invented here — this only decides which real feature screens are
// reachable for the account's real role string from the DB.

/// A single navigable capability in the staff portal. The dashboard drawer and
/// quick-access grid gate each entry on one of these keys via [canAccess].
enum Capability {
  dashboard,
  classes,
  students,
  attendance,
  timetable,
  homework,
  assignments,
  materials,
  assessments,
  exams,
  gradebook,
  results,
  flashcards,
  behavior,
  ptm,
  leave,
  calendar,
  reports,
  notifications,
  messages,
  helpCenter,
  settings,
}

// Legacy / alternate role spellings → canonical registry id. Mirrors ALIASES
// in src/lib/roles.ts. Anything not listed (already-canonical ids like
// `principal`, `class_teacher`) passes through unchanged.
const Map<String, String> _aliases = {
  'staff': 'class_teacher',
  'teacher': 'class_teacher',
  'hod': 'academic_coordinator',
  'head_of_department': 'academic_coordinator',
  'coordinator': 'grade_coordinator',
  'headteacher': 'class_teacher',
  'head_teacher': 'class_teacher',
};

/// Canonicalize a raw role string from the DB / session into a registry id.
/// Falls back to `class_teacher` (the most restrictive staff role) for an
/// empty/unknown value so we never accidentally grant a wider menu than a
/// real, recognized role would get.
String resolveStaffRole(String? raw) {
  final r = (raw ?? '').trim().toLowerCase();
  if (r.isEmpty) return 'class_teacher';
  return _aliases[r] ?? r;
}

// Manager / leadership roles that log into the mobile app get the full staff
// menu (they oversee the whole teacher workflow). Mirrors the admin-layout
// leadership roles in roles.ts that also carry teacher-facing oversight.
const Set<String> _fullAccessStaffRoles = {
  'admin',
  'super_admin',
  'school_owner',
  'principal',
  'vice_principal',
  'academic_coordinator',
  'grade_coordinator',
  'exam_controller',
};

// Homeroom-only duties a subject teacher does NOT have. Mirrors
// subjectTeacherExcludedTitles in DashboardSidebar.tsx.
const Set<Capability> _subjectTeacherExcluded = {
  Capability.attendance,
  Capability.behavior,
  Capability.ptm,
};

/// Whether [rawRole] may access [cap] in the staff portal.
///
/// Universal capabilities (dashboard, help, settings, notifications, calendar,
/// messages) are always allowed. Full-access roles see everything. A
/// `class_teacher` sees the full teacher menu. A `subject_teacher` sees it all
/// except the homeroom duties in [_subjectTeacherExcluded].
bool canAccess(String rawRole, Capability cap) {
  // Always-on essentials — every authenticated staff member keeps these.
  const universal = {
    Capability.dashboard,
    Capability.settings,
    Capability.helpCenter,
    Capability.notifications,
    Capability.calendar,
    Capability.messages,
    Capability.leave,
  };
  if (universal.contains(cap)) return true;

  final role = resolveStaffRole(rawRole);
  if (_fullAccessStaffRoles.contains(role)) return true;

  if (role == 'subject_teacher') {
    return !_subjectTeacherExcluded.contains(cap);
  }

  // class_teacher and any other teacher-layout staff → full teacher menu.
  return true;
}

// Human-readable labels for the canonical role ids (mirrors roleLabel in
// roles.ts). Used on the Help Center header and profile role chip.
const Map<String, String> _roleLabels = {
  'super_admin': 'Super Admin',
  'school_owner': 'School Owner',
  'admin': 'School Admin',
  'principal': 'Principal',
  'vice_principal': 'Vice Principal',
  'academic_coordinator': 'Academic Coordinator',
  'grade_coordinator': 'Grade Coordinator',
  'exam_controller': 'Exam Controller',
  'class_teacher': 'Class Teacher',
  'subject_teacher': 'Subject Teacher',
};

/// Display label for a raw role string (e.g. "subject_teacher" → "Subject
/// Teacher"). Falls back to a title-cased version of the raw value.
String roleLabel(String? rawRole) {
  final role = resolveStaffRole(rawRole);
  final known = _roleLabels[role];
  if (known != null) return known;
  // Title-case the underscore-separated fallback.
  return role
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// True for the leadership tier — used to widen Help Center categories
/// (release notes / changelog) the same way MANAGER_CATEGORIES does on desktop
/// (src/lib/helpCenter/roleAccess.ts).
bool isManagerRole(String? rawRole) {
  final role = resolveStaffRole(rawRole);
  return _fullAccessStaffRoles.contains(role);
}
