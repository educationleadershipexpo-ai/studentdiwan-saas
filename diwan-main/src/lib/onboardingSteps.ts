// Single source of truth for the Quick Start wizard's step list — order,
// copy, deep-link target, and how completion is determined for each step.
// "auto" steps are considered done when real data exists (checked by
// useOnboardingProgress); "manual" steps have no reliable signal to check
// automatically, so the admin ticks them off themselves.
export interface OnboardingStep {
  id: string;
  title: string;
  description: string;
  route: string;
  completion: 'auto' | 'manual';
  tips: string[];
}

export const ONBOARDING_STEPS: OnboardingStep[] = [
  {
    id: 'school-profile',
    title: 'Complete School Profile',
    description: "Set up your institution's basic information — name, logo, address and contact details.",
    route: '/quick-start',
    completion: 'auto',
    tips: ['Upload a clear, square logo for best results on printed documents.'],
  },
  {
    id: 'academic-year',
    title: 'Configure Academic Year',
    description: 'Create the academic year, terms/semesters and holidays your school calendar runs on.',
    route: '/settings/academic',
    completion: 'auto',
    tips: ['Set this up before creating classes — many features key off the active academic year.'],
  },
  {
    id: 'classes',
    title: 'Create Classes',
    description: 'Add classes (grades) and sections, and assign a class teacher to each.',
    route: '/academics/classes',
    completion: 'auto',
    tips: ['Create classes before importing students — student records need a class to belong to.'],
  },
  {
    id: 'subjects',
    title: 'Add Subjects & Assign Teachers',
    description: 'Create subjects and assign a teacher to each subject/class combination.',
    route: '/academics/subjects',
    completion: 'auto',
    tips: ['Assigning teachers here is what powers the timetable and gradebook later.'],
  },
  {
    id: 'teachers',
    title: 'Add Teachers & Staff',
    description: 'Add teacher and administrative staff profiles.',
    route: '/hr/staff',
    completion: 'auto',
    tips: ['Assign roles and permissions before inviting staff to log in.'],
  },
  {
    id: 'students',
    title: 'Import Students',
    description: 'Bulk-import your student roster from a CSV or Excel file, or add students one by one.',
    route: '/students',
    completion: 'auto',
    tips: ['Use the provided template — required columns: Name, Email, Class, Gender, Parent Name, Phone.'],
  },
  {
    id: 'fees',
    title: 'Configure Fee Structure',
    description: 'Set up tuition, transport, library and other fee structures per class.',
    route: '/finance/fees',
    completion: 'auto',
    tips: ['Fee structures can be bulk-imported per grade from a template too.'],
  },
  {
    id: 'timetable',
    title: 'Create Timetable',
    description: 'Build the weekly timetable — assign subject, teacher and time slot per class.',
    route: '/timetable',
    completion: 'auto',
    tips: ['Subjects must have an assigned teacher before they can be scheduled.'],
  },
  {
    id: 'attendance',
    title: 'Configure Attendance',
    description: 'Choose your attendance mode (daily or period-wise) and take your first attendance.',
    route: '/attendance',
    completion: 'auto',
    tips: ['Attendance rules and shift timing live in HR Settings if you need custom rules.'],
  },
  {
    id: 'users',
    title: 'Invite Users',
    description: 'Invite teachers, parents and students — they receive login credentials by email.',
    route: '/users',
    completion: 'auto',
    tips: ['Assign the correct role to each account so they see only what they need.'],
  },
  {
    id: 'test-system',
    title: 'Test the System',
    description: 'Verify students are visible, teachers are assigned, attendance works, fees are configured, and the timetable displays correctly.',
    route: '/',
    completion: 'manual',
    tips: ['Log in as a teacher or parent (use "View as" in the top bar) to confirm what they see.'],
  },
];
