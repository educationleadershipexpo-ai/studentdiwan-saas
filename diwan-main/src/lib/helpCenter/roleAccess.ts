/**
 * Role-based access control for the Help Center.
 * Defines which guide IDs and category IDs each role may see.
 * Automatically reacts to role changes because callers read from AuthContext.
 */

// All category ids in display order
const ALL_CATEGORIES = [
  'getting-started', 'user-guides', 'modules',
  'system-admin', 'developer-docs',
  'faq', 'troubleshooting', 'release-notes', 'changelog',
];

// Tier sets (cumulative)
const PORTAL_CATEGORIES   = ['getting-started', 'user-guides', 'faq', 'troubleshooting'];
const STAFF_CATEGORIES    = ['getting-started', 'user-guides', 'modules', 'faq', 'troubleshooting'];
const MANAGER_CATEGORIES  = ['getting-started', 'user-guides', 'modules', 'faq', 'troubleshooting', 'release-notes', 'changelog'];
const ADMIN_CATEGORIES    = ALL_CATEGORIES;

const CATEGORY_ACCESS: Record<string, string[]> = {
  // Full platform admins
  super_admin:           ADMIN_CATEGORIES,
  school_owner:          ADMIN_CATEGORIES,
  admin:                 ADMIN_CATEGORIES,
  // Senior management — operational oversight, no sys-admin/dev-docs
  principal:             MANAGER_CATEGORIES,
  vice_principal:        MANAGER_CATEGORIES,
  academic_coordinator:  MANAGER_CATEGORIES,
  grade_coordinator:     MANAGER_CATEGORIES,
  exam_controller:       MANAGER_CATEGORIES,
  // Specialist staff — their department + universal support categories
  class_teacher:         STAFF_CATEGORIES,
  subject_teacher:       STAFF_CATEGORIES,
  accountant:            STAFF_CATEGORIES,
  hr_manager:            STAFF_CATEGORIES,
  transport_manager:     STAFF_CATEGORIES,
  librarian:             STAFF_CATEGORIES,
  receptionist:          STAFF_CATEGORIES,
  nurse:                 STAFF_CATEGORIES,
  counselor:             STAFF_CATEGORIES,
  hostel_warden:         STAFF_CATEGORIES,
  event_coordinator:     STAFF_CATEGORIES,
  alumni_coordinator:    STAFF_CATEGORIES,
  procurement_officer:   STAFF_CATEGORIES,
  // Portal-only users
  student:               PORTAL_CATEGORIES,
  parent:                PORTAL_CATEGORIES,
};

// Which guide IDs (from ALL_GUIDES) are relevant for each role.
// Full admins see all guides so they can support any user.
// Specialist roles see their own guide + guides for the people they interact with.
const ALL_GUIDE_IDS = [
  'super-admin', 'school-admin', 'teacher', 'student',
  'parent', 'accountant', 'hr', 'transport', 'library', 'mobile-app',
];

const GUIDE_ACCESS: Record<string, string[]> = {
  super_admin:           ALL_GUIDE_IDS,
  school_owner:          ALL_GUIDE_IDS,
  admin:                 ALL_GUIDE_IDS,
  principal:             ['school-admin', 'teacher', 'student', 'parent', 'mobile-app'],
  vice_principal:        ['school-admin', 'teacher', 'student', 'parent', 'mobile-app'],
  academic_coordinator:  ['school-admin', 'teacher', 'student', 'mobile-app'],
  grade_coordinator:     ['teacher', 'student', 'mobile-app'],
  exam_controller:       ['teacher', 'student', 'mobile-app'],
  class_teacher:         ['teacher', 'student', 'mobile-app'],
  subject_teacher:       ['teacher', 'student', 'mobile-app'],
  accountant:            ['accountant', 'mobile-app'],
  hr_manager:            ['hr', 'mobile-app'],
  transport_manager:     ['transport', 'mobile-app'],
  librarian:             ['library', 'student', 'mobile-app'],
  receptionist:          ['school-admin', 'student', 'parent', 'mobile-app'],
  nurse:                 ['student', 'mobile-app'],
  counselor:             ['student', 'parent', 'mobile-app'],
  hostel_warden:         ['student', 'parent', 'mobile-app'],
  event_coordinator:     ['student', 'mobile-app'],
  alumni_coordinator:    ['student', 'parent', 'mobile-app'],
  procurement_officer:   ['school-admin', 'mobile-app'],
  student:               ['student', 'mobile-app'],
  parent:                ['parent', 'mobile-app'],
};

// The single guide that best represents a given role (shown as "Your Guide")
const PRIMARY_GUIDE: Record<string, string> = {
  super_admin:           'super-admin',
  school_owner:          'super-admin',
  admin:                 'school-admin',
  principal:             'school-admin',
  vice_principal:        'school-admin',
  academic_coordinator:  'school-admin',
  grade_coordinator:     'school-admin',
  exam_controller:       'teacher',
  class_teacher:         'teacher',
  subject_teacher:       'teacher',
  accountant:            'accountant',
  hr_manager:            'hr',
  transport_manager:     'transport',
  librarian:             'library',
  receptionist:          'school-admin',
  nurse:                 'school-admin',
  counselor:             'school-admin',
  hostel_warden:         'school-admin',
  event_coordinator:     'school-admin',
  alumni_coordinator:    'school-admin',
  procurement_officer:   'school-admin',
  student:               'student',
  parent:                'parent',
};

/** Returns the category IDs visible to the given role (ordered). */
export function getAllowedCategoryIds(role: string | null): string[] {
  if (!role) return PORTAL_CATEGORIES;
  return CATEGORY_ACCESS[role] ?? STAFF_CATEGORIES;
}

/** Returns the guide IDs visible to the given role (ordered). */
export function getAllowedGuideIds(role: string | null): string[] {
  if (!role) return ['mobile-app'];
  return GUIDE_ACCESS[role] ?? ['mobile-app'];
}

/** Returns the guide ID that is the primary/own guide for the given role. */
export function getPrimaryGuideId(role: string | null): string | null {
  if (!role) return null;
  return PRIMARY_GUIDE[role] ?? null;
}

/** Returns true if the role is allowed to view the given category. */
export function canAccessCategory(role: string | null, categoryId: string): boolean {
  return getAllowedCategoryIds(role).includes(categoryId);
}

/** Returns true if the role is allowed to view the given guide. */
export function canAccessGuide(role: string | null, guideId: string): boolean {
  return getAllowedGuideIds(role).includes(guideId);
}
