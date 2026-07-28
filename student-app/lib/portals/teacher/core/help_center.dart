// ── Help Center content + role-scoped access (staff mobile portal) ──────────
// Static, in-app documentation for teachers/staff — the same kind of shipped
// help text as the Privacy Policy already in Settings, NOT fabricated DB rows.
// Support tickets (raise-a-ticket / My Tickets) are separate and use REAL data
// via /api/data/support_tickets.
//
// Category access mirrors src/lib/helpCenter/roleAccess.ts:
//   • STAFF tier  → getting-started, user-guides, modules, faq, troubleshooting
//   • MANAGER tier→ STAFF + release-notes (leadership roles)
// getAllowedCategoryIds() applies the tier for the account's real role.

import 'rbac.dart';

/// A help category — a labelled group of articles shown as a section.
class HelpCategory {
  final String id;
  final String title;
  final String description;

  const HelpCategory({
    required this.id,
    required this.title,
    required this.description,
  });
}

/// A single help article. [body] is plain text with blank-line-separated
/// paragraphs; lines beginning with "• " render as bullets in the detail view.
class HelpArticle {
  final String id;
  final String title;
  final String categoryId;
  final String summary;
  final String body;
  final List<String> keywords;

  const HelpArticle({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.summary,
    required this.body,
    this.keywords = const [],
  });

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        summary.toLowerCase().contains(q) ||
        body.toLowerCase().contains(q) ||
        keywords.any((k) => k.toLowerCase().contains(q));
  }
}

// ── Categories (ordered) ────────────────────────────────────────────────────
const List<HelpCategory> kHelpCategories = [
  HelpCategory(
    id: 'getting-started',
    title: 'Getting Started',
    description: 'First steps for new staff',
  ),
  HelpCategory(
    id: 'user-guides',
    title: 'Guides',
    description: 'Step-by-step how-tos for everyday tasks',
  ),
  HelpCategory(
    id: 'modules',
    title: 'Modules',
    description: 'Attendance, gradebook, homework and more',
  ),
  HelpCategory(
    id: 'faq',
    title: 'FAQ',
    description: 'Answers to common questions',
  ),
  HelpCategory(
    id: 'troubleshooting',
    title: 'Troubleshooting',
    description: 'Fix problems and report issues',
  ),
  HelpCategory(
    id: 'release-notes',
    title: 'What\'s New',
    description: 'Latest changes and improvements',
  ),
];

// ── Articles ────────────────────────────────────────────────────────────────
// Concise, role-relevant guidance. Written for the mobile staff portal.
const List<HelpArticle> _articles = [
  // ── Getting started ───────────────────────────────────────────────────────
  HelpArticle(
    id: 'welcome',
    title: 'Welcome to the Staff App',
    categoryId: 'getting-started',
    summary: 'A quick tour of the dashboard and where everything lives.',
    keywords: ['intro', 'tour', 'new', 'start', 'overview'],
    body: 'This app is your mobile staffroom. Everything you do on the web '
        'portal for your own classes — attendance, homework, gradebook, '
        'messages — is here in your pocket.\n\n'
        'The Home tab is your dashboard. It shows your assigned classes, '
        'pending tasks (homework to review, assignments to grade, open '
        'behavior incidents) and quick shortcuts.\n\n'
        '• Tap the menu (☰) top-left to open the full navigation drawer.\n'
        '• Tap the "+" in the bottom bar for quick actions like taking '
        'attendance or creating homework.\n'
        '• Tap your profile picture (top-right) to open Settings.\n\n'
        'The menu only shows the features your role is responsible for, so '
        'what you see is tailored to you.',
  ),
  HelpArticle(
    id: 'first-day',
    title: 'Your First Day: A Checklist',
    categoryId: 'getting-started',
    summary: 'Five things to do the first time you sign in.',
    keywords: ['checklist', 'setup', 'first', 'onboarding'],
    body: 'New to Student Diwan? Work through this once and you\'re set:\n\n'
        '• Add a profile photo — open Settings from your avatar, tap the '
        'photo, and upload one so colleagues and parents recognise you.\n'
        '• Check your classes — the "My Classes" card on Home lists the '
        'grades and sections assigned to you. If something is missing, tell '
        'your coordinator.\n'
        '• Set your theme and language — Settings lets you switch between '
        'light/dark mode and English/Arabic.\n'
        '• Take a test attendance — open Attendance, pick a class, and try '
        'marking one period so the flow is familiar.\n'
        '• Review notifications — the bell (top-right) collects alerts about '
        'your classes, leave requests and meetings.',
  ),
  HelpArticle(
    id: 'navigation',
    title: 'Finding Your Way Around',
    categoryId: 'getting-started',
    summary: 'How the drawer, bottom bar and quick actions fit together.',
    keywords: ['navigate', 'menu', 'drawer', 'bottom bar'],
    body: 'There are three ways to move around:\n\n'
        '• Bottom bar — Home, Classes, Calendar and Profile are always one '
        'tap away, with a "+" in the middle for quick actions.\n'
        '• Navigation drawer — the ☰ menu lists every feature you have '
        'access to, grouped from daily tools down to Settings.\n'
        '• Quick Access grid — the Home screen surfaces your most-used '
        'shortcuts so you rarely need the full menu.\n\n'
        'Use the back gesture or the arrow at the top-left of any screen to '
        'return to where you were.',
  ),

  // ── User guides ───────────────────────────────────────────────────────────
  HelpArticle(
    id: 'guide-attendance',
    title: 'How to Take Attendance',
    categoryId: 'user-guides',
    summary: 'Mark present, absent and late for a class period.',
    keywords: ['attendance', 'present', 'absent', 'late', 'register'],
    body: 'Attendance is scoped to your assigned classes only.\n\n'
        '• Open Attendance from the drawer or the Quick Access grid.\n'
        '• Choose the class and the date (defaults to today).\n'
        '• Tap each student to cycle Present → Absent → Late, or use the '
        'bulk "Mark all present" action and adjust the exceptions.\n'
        '• Save. Parents and the office see the update immediately.\n\n'
        'Class teachers own the homeroom register; subject teachers record '
        'attendance only where their school assigns it.',
  ),
  HelpArticle(
    id: 'guide-homework',
    title: 'Creating and Reviewing Homework',
    categoryId: 'user-guides',
    summary: 'Set homework, attach files, and track what needs review.',
    keywords: ['homework', 'assign', 'review', 'submission'],
    body: 'To set homework:\n\n'
        '• Tap "+" in the bottom bar → Create Homework, or open Homework and '
        'use the add button.\n'
        '• Pick the class, add a title, description and due date, and attach '
        'any files.\n'
        '• Publish. Students and parents are notified.\n\n'
        'The Home dashboard shows a "Homework to Review" count when '
        'submissions are waiting. Tap it to jump straight to grading.',
  ),
  HelpArticle(
    id: 'guide-gradebook',
    title: 'Entering Marks in the Gradebook',
    categoryId: 'user-guides',
    summary: 'Record assessment marks and see computed grades.',
    keywords: ['gradebook', 'marks', 'grades', 'assessment', 'results'],
    body: 'The gradebook uses your school\'s weighting rules to compute a '
        'final grade from the components you enter.\n\n'
        '• Open Gradebook and select a class and assessment.\n'
        '• Enter each student\'s raw mark. The computed grade updates as you '
        'type.\n'
        '• Save to publish. Results become visible to students and parents '
        'according to your school\'s release settings.\n\n'
        'Marks are always tied to your real class roster — there are no '
        'placeholder students.',
  ),

  // ── Modules ───────────────────────────────────────────────────────────────
  HelpArticle(
    id: 'module-behavior',
    title: 'Behavior & Incidents',
    categoryId: 'modules',
    summary: 'Log positive notes and incidents for your homeroom.',
    keywords: ['behavior', 'behaviour', 'incident', 'conduct'],
    body: 'Behavior logging is a homeroom duty, so it appears for class '
        'teachers and leadership.\n\n'
        '• Open Behavior to see open incidents for your class.\n'
        '• Add a note — choose the student, category and severity, and write '
        'what happened.\n'
        '• Mark incidents resolved once handled; the dashboard tracks the '
        'open count.',
  ),
  HelpArticle(
    id: 'module-ptm',
    title: 'Parent–Teacher Meetings (PTM)',
    categoryId: 'modules',
    summary: 'View and manage parent meeting bookings.',
    keywords: ['ptm', 'parent', 'meeting', 'booking'],
    body: 'PTM booking is available to class teachers and leadership.\n\n'
        '• Open Parent Meetings (PTM) to see scheduled slots.\n'
        '• Review who has booked and add notes after each meeting.\n\n'
        'Subject teachers do not manage homeroom PTM bookings, so this item '
        'is hidden for them.',
  ),
  HelpArticle(
    id: 'module-leave',
    title: 'Requesting Leave',
    categoryId: 'modules',
    summary: 'Submit a leave request and track its approval.',
    keywords: ['leave', 'absence', 'time off', 'approval'],
    body: 'To request leave:\n\n'
        '• Open Leave and tap the add button.\n'
        '• Choose the type and dates, and add a reason.\n'
        '• Submit. Your request follows the school\'s approval chain '
        '(typically Principal, then HR).\n\n'
        'The status updates in place — pending, approved or rejected — and '
        'you are notified of any change.',
  ),

  // ── FAQ ───────────────────────────────────────────────────────────────────
  HelpArticle(
    id: 'faq-menu-differs',
    title: 'Why is my menu different from a colleague\'s?',
    categoryId: 'faq',
    summary: 'The app shows features based on your role\'s responsibilities.',
    keywords: ['role', 'menu', 'missing', 'access', 'rbac', 'permission'],
    body: 'The staff app is role-based. It only shows the tools your role is '
        'responsible for, so your menu is tailored to you.\n\n'
        '• A class teacher owns a homeroom, so they see Attendance, Behavior '
        'and Parent Meetings.\n'
        '• A subject teacher teaches across sections without a homeroom, so '
        'those homeroom-only tools are hidden.\n'
        '• Coordinators and principals see the full teacher menu for '
        'oversight.\n\n'
        'If you believe you\'re missing something your role should have, '
        'raise a ticket and your administrator will review your access.',
  ),
  HelpArticle(
    id: 'faq-profile-photo',
    title: 'How do I change my profile photo?',
    categoryId: 'faq',
    summary: 'Upload a photo from Settings.',
    keywords: ['photo', 'picture', 'avatar', 'profile'],
    body: 'Open Settings (tap your avatar on the dashboard, top-right), then '
        'tap the large profile photo at the top. Choose a picture from your '
        'device and it uploads straight away — your new photo then appears on '
        'the dashboard and to colleagues.',
  ),
  HelpArticle(
    id: 'faq-data-real',
    title: 'Is the data I see live?',
    categoryId: 'faq',
    summary: 'Yes — everything is your school\'s real records.',
    keywords: ['data', 'live', 'real', 'sync'],
    body: 'Every class, student, mark and message in this app is your '
        'school\'s live data, the same records as the web portal. Changes you '
        'save here are immediately visible to students, parents and the '
        'office, and vice versa.',
  ),

  // ── Troubleshooting ───────────────────────────────────────────────────────
  HelpArticle(
    id: 'trouble-not-loading',
    title: 'A screen won\'t load or shows nothing',
    categoryId: 'troubleshooting',
    summary: 'Steps to try when data doesn\'t appear.',
    keywords: ['loading', 'blank', 'empty', 'error', 'network'],
    body: 'If a screen is stuck or empty:\n\n'
        '• Check your internet connection — the app needs to reach the '
        'school server.\n'
        '• Pull down to refresh, or leave the screen and return.\n'
        '• If a list is genuinely empty (e.g. no homework set yet), the app '
        'shows a friendly message rather than data — that\'s expected.\n'
        '• If it persists, sign out from Settings and sign back in.\n\n'
        'Still stuck? Raise a ticket describing the screen and what you '
        'expected to see.',
  ),
  HelpArticle(
    id: 'trouble-login',
    title: 'I can\'t sign in',
    categoryId: 'troubleshooting',
    summary: 'What to check when login fails.',
    keywords: ['login', 'sign in', 'password', 'access denied'],
    body: 'If sign-in fails:\n\n'
        '• Confirm you\'re using your school email and current password.\n'
        '• "Access denied" means your account isn\'t a staff role — this app '
        'is for teachers and school staff. Contact your administrator.\n'
        '• Use "Forgot password" on the login screen to reset.\n'
        '• If the server can\'t be reached, check your network and try '
        'again shortly.',
  ),

  // ── Release notes (manager tier) ──────────────────────────────────────────
  HelpArticle(
    id: 'whatsnew',
    title: 'What\'s New in This Release',
    categoryId: 'release-notes',
    summary: 'Recent additions to the staff mobile app.',
    keywords: ['new', 'changes', 'update', 'release'],
    body: 'Recent improvements:\n\n'
        '• Role-based menus — the app now tailors navigation to each staff '
        'role\'s responsibilities.\n'
        '• Help Center — this in-app guide, with articles and support '
        'tickets, scoped to your role.\n'
        '• Profile photo upload — set your picture directly from Settings.\n'
        '• Dark mode and Arabic — switch theme and language in Settings.',
  ),
];

/// Category ids visible to [rawRole]. Managers additionally see release notes.
/// Mirrors getAllowedCategoryIds in roleAccess.ts.
List<String> getAllowedCategoryIds(String? rawRole) {
  const staff = [
    'getting-started',
    'user-guides',
    'modules',
    'faq',
    'troubleshooting',
  ];
  if (isManagerRole(rawRole)) {
    return [...staff, 'release-notes'];
  }
  return staff;
}

/// Categories (with their articles) visible to [rawRole], in display order.
List<HelpCategory> allowedCategories(String? rawRole) {
  final allowed = getAllowedCategoryIds(rawRole).toSet();
  return kHelpCategories.where((c) => allowed.contains(c.id)).toList();
}

/// All articles the role may see, optionally filtered by [query].
List<HelpArticle> articlesFor(String? rawRole, {String query = ''}) {
  final allowed = getAllowedCategoryIds(rawRole).toSet();
  return _articles
      .where((a) => allowed.contains(a.categoryId) && a.matches(query))
      .toList();
}

/// Articles in a single category the role may see (empty if not allowed).
List<HelpArticle> articlesInCategory(String? rawRole, String categoryId,
    {String query = ''}) {
  if (!getAllowedCategoryIds(rawRole).contains(categoryId)) return const [];
  return _articles
      .where((a) => a.categoryId == categoryId && a.matches(query))
      .toList();
}
