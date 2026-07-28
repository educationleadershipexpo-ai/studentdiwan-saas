import type { UserGuide } from '@/lib/userGuides/types';

export const superAdminGuide: UserGuide = {
  id: 'super-admin',
  role: 'Super Administrator',
  title: 'Super Administrator Guide',
  tagline: 'Complete system ownership — configure, control, and monitor every aspect of Student Diwan.',
  audience: 'IT administrators and system owners responsible for the full Student Diwan deployment.',
  icon: 'ShieldCheck',
  gradient: 'from-violet-600 to-purple-700',
  accentHex: '#7c3aed',
  badgeBg: 'bg-violet-100 dark:bg-violet-950/40',
  badgeText: 'text-violet-700 dark:text-violet-300',
  estimatedMinutes: 45,
  version: '1.0.0',
  lastUpdated: '2026-07-17',
  chapters: [
    {
      id: 'intro',
      number: 1,
      title: 'Introduction to Super Admin',
      icon: 'ShieldCheck',
      summary: 'Understand the Super Admin role, its full scope of permissions, and how it differs from other roles in Student Diwan.',
      blocks: [
        {
          type: 'text',
          markdown: `## Welcome, Super Administrator

As the **Super Administrator** of Student Diwan, you hold the highest level of access in the system. This role is designed for the **IT owner or system administrator** responsible for the school's entire ERP deployment — from onboarding the institution to configuring financial structures, managing every user account, and maintaining system health.

This guide walks you through every capability available to you, with step-by-step instructions, best practices, and real workflow examples.

### What makes Super Admin unique?

- **Unrestricted access** to all modules: students, staff, finance, academics, and system settings
- **User and role management** — create, edit, suspend, or delete any account
- **System-level configuration** — academic years, grading schemes, fee structures, and integrations
- **Cross-school visibility** if the deployment serves multiple campuses
- **Audit trail access** — review every change made by every user`,
        },
        {
          type: "table",
          caption: 'Super Admin permissions compared to other roles',
          headers: ['Feature / Module', 'Super Admin', 'School Admin', 'Teacher', 'HR Manager'],
          rows: [
            ['Dashboard & Stats', '✅ Full', '✅ Full', '✅ Own data', '✅ HR data'],
            ['Student Records', '✅ Read + Write + Delete', '✅ Read + Write', '✅ Read only', '❌'],
            ['User Management', '✅ All roles', '✅ Teacher/Staff', '❌', '❌'],
            ['System Settings', '✅ Full', '❌', '❌', '❌'],
            ['Academic Configuration', '✅ Full', '✅ Full', '❌', '❌'],
            ['Fee Structures', '✅ Full', '✅ Full', '❌', '❌'],
            ['HR & Payroll', '✅ Full', '✅ View', '❌', '✅ Full'],
            ['Reports & Exports', '✅ All reports', '✅ School reports', '✅ Class reports', '✅ HR reports'],
            ['Audit Logs', '✅ Full history', '❌', '❌', '❌'],
            ['Integrations & API', '✅ Full', '❌', '❌', '❌'],
          ],
        },
        {
          type: 'callout',
          variant: 'danger',
          title: 'Handle with care',
          body: 'Super Admin credentials should be stored securely and shared with as few people as possible. Destructive actions — deleting academic years, removing users, resetting fee records — cannot be undone without a database backup. Always verify before confirming any deletion prompt.',
        },
        {
          type: 'steps',
          title: 'Your first-day checklist',
          steps: [
            {
              title: 'Log in and change your password',
              description: 'Use the credentials provided by the implementation team. Immediately navigate to your profile (top-right corner) and set a strong password of at least 12 characters.',
              tip: 'Enable two-factor authentication (2FA) from Settings > Security if your deployment supports it.',
            },
            {
              title: 'Review system settings',
              description: 'Go to /system-settings and verify the school name, logo, timezone, and currency are all correct. These appear on every printed report and invoice.',
            },
            {
              title: 'Configure the academic year',
              description: 'Navigate to /settings/academic and create the current academic year with correct start and end dates. All student enrollment and attendance records are tied to this.',
            },
            {
              title: 'Create admin and teacher accounts',
              description: 'Go to /users and invite your School Admin and teaching staff. Assign roles carefully — each role determines what the user can see and do.',
            },
            {
              title: 'Run the Quick Start wizard',
              description: 'Visit /quick-start for a guided checklist that ensures all critical configuration steps are complete before students and staff begin using the system.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-dashboard.png',
          caption: "The Super Admin dashboard gives a bird's-eye view of the entire school.",
          alt: 'Student Diwan Super Admin dashboard showing stats cards, charts, and activity feed',
          annotations: [
            { id: 1, x: 7, y: 50, label: 'Sidebar', description: 'Navigation sidebar with all modules: Students, Admissions, Attendance, HR, Finance, Users, Settings, Reports.' },
            { id: 2, x: 50, y: 20, label: 'Stats Cards', description: "Real-time totals for Total Students, Staff count, Fee Collection this month, and Today's Attendance %." },
            { id: 3, x: 50, y: 46, label: 'Charts', description: 'Enrollment trends, fee collection by month, and attendance rate over the past 30 days.' },
            { id: 4, x: 85, y: 4, label: 'Profile Menu', description: `Access your profile, switch roles with "View As", and log out.` },
            { id: 5, x: 44, y: 4, label: 'Quick Action', description: 'One-click shortcuts to add a student, record a fee payment, or mark attendance.' },
          ],
        },
        {
          type: 'table',
          caption: 'Keyboard Shortcuts — Quick Navigation',
          headers: ['Module', 'Windows / Linux', 'macOS'],
          rows: [
            ['Dashboard', 'Alt + D', '⌘ Shift + D'],
            ['All Students', 'Alt + AS', '⌘ Shift + AS'],
            ['Attendance', 'Alt + W', '⌘ Shift + W'],
            ['Admissions', 'Alt + A', '⌘ Shift + A'],
            ['Classes', 'Alt + C', '⌘ Shift + C'],
            ['Timetable', 'Alt + T', '⌘ Shift + T'],
            ['Gradebook', 'Alt + J', '⌘ Shift + J'],
            ['Library', 'Alt + L', '⌘ Shift + L'],
            ['Exam Operations', 'Alt + EO', '⌘ Shift + EO'],
            ['Report Cards', 'Alt + RC', '⌘ Shift + RC'],
            ['Finance & Fees', 'Alt + F', '⌘ Shift + F'],
            ['HR / Staff', 'Alt + H', '⌘ Shift + H'],
            ['Announcements', 'Alt + Q', '⌘ Shift + Q'],
            ['Messages', 'Alt + M', '⌘ Shift + M'],
            ['Notifications', 'Alt + N', '⌘ Shift + N'],
            ['Calendar', 'Alt + X', '⌘ Shift + X'],
            ['Transport', 'Alt + V', '⌘ Shift + V'],
            ['Hostel', 'Alt + O', '⌘ Shift + O'],
            ['Security', 'Alt + U', '⌘ Shift + U'],
            ['Inventory', 'Alt + Y', '⌘ Shift + Y'],
            ['Coding Lab / Teaching', 'Alt + K', '⌘ Shift + K'],
            ['AI Center / Intelligence', 'Alt + I', '⌘ Shift + I'],
            ['Branches', 'Alt + B', '⌘ Shift + B'],
            ['Graduates', 'Alt + G', '⌘ Shift + G'],
            ['Help Center', 'Alt + Z', '⌘ Shift + Z'],
            ['Student Mgmt', 'Alt + SM', '⌘ Shift + SM'],
            ['Subjects', 'Alt + S', '⌘ Shift + S'],
            ['Reports', 'Alt + R', '⌘ Shift + R'],
            ['Room Management', 'Alt + RM', '⌘ Shift + RM'],
            ['Subject Codes', 'Alt + SC', '⌘ Shift + SC'],
            ['Assignments', 'Alt + AM', '⌘ Shift + AM'],
            ['Assessments', 'Alt + AE', '⌘ Shift + AE'],
            ['Health Records', 'Alt + HR', '⌘ Shift + HR'],
            ['Conduct & Discipline', 'Alt + CD', '⌘ Shift + CD'],
            ['Alumni Network', 'Alt + AN', '⌘ Shift + AN'],
            ['Payroll', 'Alt + PY', '⌘ Shift + PY'],
            ['Routes', 'Alt + VR', '⌘ Shift + VR'],
            ['Allocations', 'Alt + AL', '⌘ Shift + AL'],
            ['AI Timetable', 'Alt + AI', '⌘ Shift + AI'],
            ['Visitors', 'Alt + VI', '⌘ Shift + VI'],
            ['Incidents', 'Alt + IN', '⌘ Shift + IN'],
            ['Fees', 'Alt + FE', '⌘ Shift + FE'],
            ['Transactions', 'Alt + TX', '⌘ Shift + TX'],
            ['Portals', 'Alt + P', '⌘ Shift + P'],
            ['Parent-Teacher Meetings', 'Alt + PT', '⌘ Shift + PT'],
            ['Transcripts', 'Alt + TR', '⌘ Shift + TR'],
            ['Certificates', 'Alt + CE', '⌘ Shift + CE'],
            ['Plagiarism Checker', 'Alt + PC', '⌘ Shift + PC'],
            ['Stock', 'Alt + ST', '⌘ Shift + ST'],
            ['Purchases', 'Alt + PU', '⌘ Shift + PU'],
            ['Vendors', 'Alt + VE', '⌘ Shift + VE'],
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'More Ways to Navigate',
          body: 'Hold Alt (Windows) or ⌘+Shift (Mac) then press the letter(s) shown above. For two-letter shortcuts like Alt + SM, keep holding Alt and press S then M in sequence. Press ? anywhere (when not typing) to open the full Keyboard Shortcuts guide.',
        },
      ],
    },
    {
      id: 'login',
      number: 2,
      title: 'Getting Started & Login',
      icon: 'KeyRound',
      summary: 'Log in securely, navigate the top bar and sidebar, and understand the "View As" role-switcher feature.',
      blocks: [
        {
          type: 'text',
          markdown: `## Logging In to Student Diwan

Access Student Diwan through your school's designated URL (e.g., \`https://diwan.yourschool.edu\`). The login portal accepts your **email address** and **password**. If your institution uses Single Sign-On (SSO), click the **\"Sign in with SSO\"** button instead.

### Navigating the Interface

Once logged in, you"ll see three primary interface zones:

- **Left Sidebar** — The main navigation. Grouped into sections: Academics, Students, HR, Finance, Administration, and Reports. Collapse it with the arrow icon at the bottom for more screen space.
- **Top Bar** — Contains the school logo/name, breadcrumb trail, role switcher, language toggle (EN/AR), Quick Action button, notification bell, and your profile avatar.
- **Main Content Area** — Changes based on the active route.

### The "View As" Role Switcher

This powerful Super Admin feature lets you **temporarily see the system through another role\"s eyes** without logging out. Click **\"View As\"** in the top bar, choose a role (School Admin, Teacher, HR Manager, or Student), and the interface adapts to show only that role's permitted screens. Switch back to Super Admin at any time.`,
        },
        {
          type: "steps",
          title: 'Logging in step by step',
          steps: [
            {
              title: 'Open the login portal',
              description: `Navigate to your school's Student Diwan URL. The login page shows the school logo, an email field, a password field, and a "Sign In" button.`,
              tip: 'Bookmark this URL for quick access. The page also works on mobile browsers.',
            },
            {
              title: 'Enter your credentials',
              description: `Type your registered email address and password. Both fields are case-sensitive. If you've forgotten your password, click "Forgot password?" to receive a reset link.`,
            },
            {
              title: 'Complete 2FA if enabled',
              description: 'If two-factor authentication is active on your account, enter the 6-digit code from your authenticator app or SMS. The code expires after 30 seconds.',
            },
            {
              title: 'Verify your landing page',
              description: 'After login, you should land on the dashboard at /. The top bar should display your school name on the left and your profile avatar on the right.',
            },
            {
              title: 'Test the "View As" switcher',
              description: 'Click the "View As" button in the top bar. A dropdown shows available roles. Select "School Admin" to preview that view, then switch back to "Super Admin".',
              tip: `Use "View As" when troubleshooting user permission complaints — you'll see exactly what they see.`,
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/login-portal.png',
          caption: 'The Student Diwan login portal.',
          alt: 'Student Diwan login page with email, password fields and sign in button',
          annotations: [
            { id: 1, x: 50, y: 30, label: 'Email Field', description: 'Enter your registered email address. SSO users click the separate SSO button below.' },
            { id: 2, x: 50, y: 50, label: 'Password Field', description: 'Your account password. Click the eye icon to toggle visibility.' },
            { id: 3, x: 50, y: 65, label: 'Sign In Button', description: 'Submits credentials. Disabled until both fields have content.' },
            { id: 4, x: 50, y: 78, label: 'Forgot Password', description: 'Sends a secure reset link to your registered email, valid for 24 hours.' },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Arabic / RTL interface',
          body: 'Click the language toggle (EN/AR) in the top bar to switch the entire interface to Arabic with full right-to-left layout. All student names, reports, and printed documents respect the selected language direction.',
        },
      ],
    },
    {
      id: 'dashboard',
      number: 3,
      title: 'Dashboard Overview',
      icon: 'LayoutDashboard',
      summary: 'Read the dashboard stats cards, interpret charts, use the activity feed, and set up Quick Actions.',
      blocks: [
        {
          type: 'text',
          markdown: `## Your Command Center

The Super Admin dashboard at **/** is your real-time view of the school's operational health. It refreshes automatically every 5 minutes and can be manually refreshed by clicking the circular arrow icon.

### Stats Cards (top row)

| Card | What it shows |
|------|---------------|
| **Total Students** | Active enrolled students across all grades. Click to open /students filtered to active. |
| **Staff** | Total teaching and non-teaching staff. Click to open /hr/staff. |
| **Fee Collection** | Total fees collected in the current calendar month. |
| **Attendance %** | School-wide attendance rate for today. Color-coded: green ≥90%, amber 75–89%, red <75%. |

### Charts Section

- **Enrollment Trend** (line chart) — Monthly enrollment numbers over the academic year. Hover any point for the exact count.
- **Fee Collection by Month** (bar chart) — Revenue per month. Toggle between \"Collected\" and \"Outstanding\" using the legend.
- **Attendance Heatmap** — Class-by-class attendance rates for the current week.

### Activity Feed

The right-hand panel shows the 20 most recent system events: new student enrollments, fee payments, user logins, and configuration changes. Each entry shows the timestamp, the acting user, and the action taken. Click any entry to see full details.`,
        },
        {
          type: "steps",
          title: 'Customising your dashboard view',
          steps: [
            {
              title: 'Filter the date range',
              description: 'Click the date-range picker (top-right of the charts section) to change the reporting window. Options: Today, This Week, This Month, This Term, This Year, or Custom Range.',
            },
            {
              title: 'Pin a specific class',
              description: 'Use the "Class filter" dropdown above the attendance heatmap to focus on a single grade or section. The stats cards also update to reflect only that segment.',
            },
            {
              title: 'Export dashboard data',
              description: 'Click the download icon (↓) on any chart to export the underlying data as CSV or PDF. For a full school report, go to /reports and select "Dashboard Summary".',
            },
            {
              title: 'Set up Quick Actions',
              description: 'Click the ⚡ Quick Action button in the top bar, then select "Customise". Drag and drop up to 6 shortcuts — such as Add Student, Record Payment, or Generate Report — for one-click access.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-dashboard.png',
          caption: 'Dashboard overview with stats, charts, and activity feed.',
          alt: 'Full admin dashboard showing four stats cards, enrollment and fee charts, and activity feed',
          annotations: [
            { id: 1, x: 20, y: 20, label: 'Total Students Card', description: 'Tap to drill into /students with the active filter pre-applied.' },
            { id: 2, x: 50, y: 20, label: 'Fee Collection Card', description: `Shows this month's total in the school's configured currency.` },
            { id: 3, x: 50, y: 46, label: 'Enrollment Chart', description: 'Hover any month bar for exact enrollment numbers and a breakdown by grade.' },
            { id: 4, x: 85, y: 50, label: 'Activity Feed', description: 'Live log of system events. Each entry links to the affected record.' },
            { id: 5, x: 20, y: 46, label: 'Fee Collection Chart', description: 'Bar chart comparing collected vs outstanding fees per month.' },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Dashboard data latency',
          body: 'The stats cards refresh every 5 minutes. If you just enrolled a large batch of students via CSV import, allow up to 5 minutes before the Total Students card reflects the new count. Charts update nightly at midnight (server timezone).',
        },
      ],
    },
    {
      id: 'users-roles',
      number: 4,
      title: 'User & Role Management',
      icon: 'Users',
      summary: 'Create user accounts, assign roles, manage permissions, reset passwords, and suspend or delete accounts.',
      blocks: [
        {
          type: 'text',
          markdown: `## Managing Every Account in the System

Navigate to **/users** to access the complete user registry. You can create, search, filter, edit, suspend, and delete any account from this single page.

### User Roles in Student Diwan

| Role | Primary access | Typical user |
|------|----------------|--------------|
| **Super Admin** | Everything | IT owner, system administrator |
| **School Admin** | Academics, students, finance, reporting | Principal, academic coordinator |
| **Teacher** | Own classes, attendance, gradebook | Classroom teachers |
| **HR Manager** | Staff records, leave, payroll | HR department staff |
| **Finance Officer** | Fee collection, invoices, reports | Accountants, bursars |
| **Student** | Own profile, timetable, results | Enrolled students (read-only) |
| **Parent** | Child's profile, attendance, fees | Parent or guardian |

### Bulk Operations

The Users page supports bulk actions: select multiple users with the checkbox column, then choose **Activate**, **Suspend**, or **Export** from the bulk-actions toolbar that appears at the top of the table.`,
        },
        {
          type: "steps",
          title: 'Creating a new user account',
          steps: [
            {
              title: 'Open the Users page',
              description: 'Click "Users" in the left sidebar (Administration group) or navigate directly to /users.',
            },
            {
              title: 'Click "Add User"',
              description: 'The blue "Add User" button is at the top right of the page. This opens a modal form.',
            },
            {
              title: 'Fill in the user details',
              description: 'Enter: Full Name, Email Address, Role (select from dropdown), and optionally a Phone Number and Employee/Student ID. The system sends an invitation email automatically.',
              tip: 'The email address is the login identifier — ensure it is correct before saving.',
            },
            {
              title: 'Set initial permissions',
              description: 'For Teacher and HR roles, you can restrict access to specific classes or departments from the "Permissions" tab within the user form.',
            },
            {
              title: 'Save and notify',
              description: 'Click "Create User". The system sends a welcome email with a secure link to set their password. The link expires in 72 hours.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-users.png',
          caption: 'The Users management page showing the full user list and controls.',
          alt: 'Users page with search bar, role filter, user table and Add User button',
          annotations: [
            { id: 1, x: 35, y: 11, label: 'Search Bar', description: 'Filter users by name, email, or employee ID in real time.' },
            { id: 2, x: 85, y: 11, label: 'Add User Button', description: 'Opens the new-user form modal. Only Super Admins see this button.' },
            { id: 3, x: 20, y: 20, label: 'Role Filter', description: 'Dropdown to show only users with a specific role. Useful for bulk management.' },
            { id: 4, x: 50, y: 54, label: 'User Table', description: 'Columns: Name, Email, Role, Last Login, Status. Click any row to open the edit panel.' },
            { id: 5, x: 92, y: 54, label: 'Action Menu', description: 'Three-dot menu per row: Edit, Reset Password, Suspend, or Delete.' },
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Deleting vs suspending',
          body: 'Deleting a user permanently removes their account and cannot be undone. Suspending an account blocks login while preserving all associated records (grades, attendance marks, payments). Always prefer suspending a user who may need to be reinstated later — for example, staff on long leave.',
        },
      ],
    },
    {
      id: 'system-config',
      number: 5,
      title: 'System Configuration',
      icon: 'Settings2',
      summary: 'Configure academic years, grading schemes, fee structures, school branding, and system-wide settings.',
      blocks: [
        {
          type: 'text',
          markdown: `## System-Wide Settings

The **/system-settings** page is the control room for your entire Student Diwan deployment. Changes here affect every user, every report, and every printed document.

### Key Configuration Areas

**General Settings** (/system-settings → General)
- School name, address, phone, email
- School logo (uploaded as PNG/SVG, recommended 200×200 px)
- Timezone and date format
- Currency and number format

**Academic Settings** (/settings/academic)
- Academic years (create, set as current, close)
- Terms and semesters within each year
- Grading scales (percentage-based, letter grades, GPA)
- Subject and class structure

**Finance Settings** (/settings/finance)
- Fee categories (Tuition, Transport, Canteen, Activities)
- Invoice numbering prefix and auto-increment
- Late payment penalties (flat fee or percentage)
- Payment methods accepted (cash, bank transfer, card)

**Notification Settings**
- Email templates for fee reminders, attendance alerts, report card notifications
- SMS gateway configuration (if enabled)
- In-app notification preferences per role`,
        },
        {
          type: 'steps',
          title: 'Setting up a new academic year',
          steps: [
            {
              title: 'Navigate to Academic Settings',
              description: 'Go to /settings/academic and click the "Academic Years" tab.',
            },
            {
              title: 'Create the new year',
              description: 'Click "New Academic Year". Enter the name (e.g., "2026–2027"), the start date, and the end date. Optionally add term divisions (Term 1, Term 2, Term 3).',
            },
            {
              title: 'Configure grading for this year',
              description: 'In the "Grading" tab, select or create a grading scale. Define grade boundaries: e.g., A = 90–100%, B = 80–89%, and so on. These apply to all subjects unless overridden.',
              tip: 'You can assign different grading scales to individual subjects from /academics/subjects.',
            },
            {
              title: 'Set as the active year',
              description: 'Click the three-dot menu next to the new year and choose "Set as Current". All new enrollments, attendance, and fee records will be linked to this year.',
            },
            {
              title: 'Notify school admins',
              description: 'Send a message to your School Admin users confirming the new year is active and any configuration changes they should be aware of.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-system-settings.png',
          caption: 'System Settings page showing General, Academic, and Finance tabs.',
          alt: 'System settings page with tabs for General, Academic, Finance, Notifications, and Integrations',
          annotations: [
            { id: 1, x: 20, y: 15, label: 'Settings Tabs', description: 'Navigate between General, Academic, Finance, Notifications, Integrations, and Security.' },
            { id: 2, x: 50, y: 35, label: 'School Identity', description: 'Name, logo, address, and contact details used on all printed output.' },
            { id: 3, x: 50, y: 55, label: 'Academic Year Panel', description: 'List of years with status badges (Active / Closed). The current year is highlighted.' },
            { id: 4, x: 80, y: 35, label: 'Save Button', description: 'Changes are not applied until you click Save. Unsaved changes show a yellow dot on the tab.' },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: "Clone a previous year's settings",
          body: 'When creating a new academic year, click "Clone from previous year" to copy all grade structures, fee categories, and subject lists. You only need to update dates and any changed fee amounts — saving hours of manual setup.',
        },
      ],
    },
    {
      id: 'reports-troubleshooting',
      number: 6,
      title: 'Reports & Troubleshooting',
      icon: 'FileBarChart',
      summary: 'Generate system-wide reports, export data, read audit logs, and resolve common issues.',
      blocks: [
        {
          type: 'text',
          markdown: `## Reports Available to Super Admin

Navigate to **/reports** to access the full reporting suite. Reports are grouped by module:

| Report Group | Key Reports |
|---|---|
| **Student Reports** | Enrollment summary, student directory, grade-wise count, new admissions |
| **Attendance Reports** | School-wide attendance %, class-wise daily report, absentee list |
| **Finance Reports** | Fee collection summary, outstanding fees, payment ledger, category-wise revenue |
| **HR Reports** | Staff directory, leave balance summary, attendance records |
| **Academic Reports** | Result sheets, subject performance, class toppers |
| **Audit Reports** | User activity log, configuration change history, login events |

All reports can be exported as **PDF** or **CSV**. Scheduled reports can be configured to email automatically — go to Reports → Schedule, set the report type, frequency (daily/weekly/monthly), and recipient email addresses.

## Troubleshooting Common Issues

Use the information below alongside the FAQ section to diagnose and resolve the most frequent Super Admin support requests.`,
        },
        {
          type: 'steps',
          title: 'Reading the audit log',
          steps: [
            {
              title: 'Open the Audit Log',
              description: 'Go to /reports, click the "Audit" tab, then select "User Activity Log".',
            },
            {
              title: 'Filter by user or action',
              description: `Use the search bar to filter by a specific user's name or email. Use the "Action Type" dropdown to narrow to: Login, Create, Edit, Delete, Export, or Settings Change.`,
            },
            {
              title: 'Read an entry',
              description: 'Each log entry shows: Timestamp, User (name + email), Action, Affected Record, and Before/After values for edit actions. Click any entry to expand the full diff.',
            },
            {
              title: 'Export for compliance',
              description: 'Click "Export CSV" to download the filtered log. For audit compliance, export monthly logs and store them securely off-platform.',
              tip: 'Audit logs are retained for 12 months by default. Contact support to configure longer retention.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-dashboard.png',
          caption: 'Activity feed on the dashboard acts as a real-time mini audit log.',
          alt: 'Dashboard activity feed showing recent system events with timestamps and user names',
          annotations: [
            { id: 1, x: 85, y: 50, label: 'Activity Feed', description: 'Lists the 20 most recent events across the system. Click any event to navigate to the affected record.' },
            { id: 2, x: 85, y: 80, label: 'View All Link', description: 'Opens the full audit log in /reports with the same time window.' },
            { id: 3, x: 50, y: 4, label: 'Quick Action', description: 'Use Quick Action > Generate Report to jump straight to the reports module.' },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'When to contact support',
          body: 'Student Diwan support handles: data migration issues, integration failures, database-level problems, and feature requests. For access issues or configuration help, consult this guide first. To reach support, go to /system-settings → Support, or email support@studentdiwan.com with your school ID and a description of the issue.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: "A user says they can't see a module they should have access to. What do I check?",
              a: 'Go to /users, find the user, and open their profile. Check their assigned Role — it must match the intended role. Then use the "View As" switcher in the top bar to simulate their session and confirm what they see. If the role is correct but access is still missing, check if the module is enabled in /system-settings → Modules.',
            },
            {
              q: "How do I reset a user's password?",
              a: 'Go to /users, find the user, click the three-dot menu on their row, and select "Reset Password". This sends a secure reset link to their registered email. Alternatively, the user can click "Forgot password?" on the login page themselves.',
            },
            {
              q: 'A student was enrolled in the wrong academic year. How do I move them?',
              a: `Go to /students, open the student's profile, click the "Enrollment" tab, and use "Change Academic Year". Select the correct year and confirm. Attendance and grade records remain tied to the original year; only future records will be created under the new year.`,
            },
            {
              q: 'Fee amounts on reports look wrong. What could cause this?',
              a: "Fee amounts may look wrong if (1) the fee category was edited after invoices were generated — invoices lock the amount at creation time; (2) a late fee penalty was applied automatically; or (3) a partial payment was recorded. Open the student's Finance tab to see the full payment ledger and invoice history.",
            },
            {
              q: 'How do I export the full student list for an external spreadsheet?',
              a: 'Go to /students, apply any desired filters (grade, status, academic year), then click the "Export" button (top-right, next to "Add Student"). Choose CSV or Excel format. The export includes all visible columns plus any optional fields you tick in the export dialog.',
            },
            {
              q: "The dashboard stats card shows a student count that doesn't match what I see in /students. Why?",
              a: 'The dashboard stats card caches data and refreshes every 5 minutes, while /students always shows live data. If you just performed a bulk import or deletion, wait 5 minutes and hard-refresh the dashboard. If the discrepancy persists after 10 minutes, contact support with your school ID.',
            },
          ],
        },
      ],
    },
    {
      id: 'super-admin-help',
      number: 7,
      title: 'Help Centre & Support',
      icon: 'LifeBuoy',
      summary: 'Access every resource, manage help for your team, and get direct platform support.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Your Help Centre\n\nAs Super Administrator you have access to the full Student Diwan documentation library — every role guide, the Quick Start wizard, the Administrator Manual, and the API reference. The Help Centre at `/help` is your single source of truth for setup guides, troubleshooting steps, and platform updates.\n\nYou are also responsible for directing staff, teachers, and parents to their own role-specific guides whenever they need assistance.",
        },
        {
          type: 'steps',
          title: 'How to Open the Help Centre',
          steps: [
            {
              title: 'Use the Keyboard Shortcut',
              description: 'Press Alt + Z (Windows) or ⌘ Shift + Z (Mac) from anywhere in the app to jump instantly to the Help Centre.',
              tip: 'This works even when you are deep inside System Settings or the Finance module.',
            },
            {
              title: 'Click Help in the Sidebar',
              description: 'Scroll to the bottom of the left sidebar and click the Help icon to open the Help Home page (/help).',
            },
            {
              title: 'Browse or Search Resources',
              description: 'The Help Home page lists Popular Articles, a category browser, all role guides, and PDF downloads. Use the search bar on the Guide Hub (/help/guides) to find any guide by role or topic.',
            },
            {
              title: 'Open the NeedHelp Widget',
              description: 'Click the floating ✦ button in the bottom-right corner of any page to report an issue, request assistance, or suggest a product improvement.',
            },
          ],
        },
        {
          type: 'table',
          caption: 'Help Resources Available to Super Admin',
          headers: ['Resource', 'What It Covers', 'Where to Find It'],
          rows: [
            ['Super Administrator Guide', 'System configuration, user management, academic setup, security, and troubleshooting', '/help/guides/super-admin'],
            ['Quick Start Wizard', 'Guided checklist to configure the system for a new school or academic year', '/quick-start'],
            ['Administrator Manual (PDF)', 'Offline-ready full reference guide — ideal for printing and training sessions', 'Help Centre → Downloads'],
            ['API Manual (PDF)', 'Integration reference for connecting third-party systems via the Student Diwan API', 'Help Centre → Downloads'],
            ['All 10 Role Guides', 'Individual guides for School Admin, Teacher, Student, Parent, Accountant, HR, Transport, Librarian, and Mobile users', '/help/guides'],
            ['Help Category Browser', 'Searchable knowledge base grouped by topic: Finance, Academic, HR, IT, Reporting, and more', '/help'],
            ['NeedHelp Widget', 'Submit platform bugs, request new features, or raise support requests to the development team', 'Floating ✦ button — any page'],
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Share the Right Guide with Every Staff Member',
          body: 'Before each term, share the relevant guide URL with your team: /help/guides/teacher for teachers, /help/guides/school-admin for coordinators, /help/guides/accountant for finance staff, and /help/guides/parent for parent orientation sessions. All guides are mobile-friendly and available offline as PDFs from the Help Centre downloads page.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'A staff member cannot find their guide. Where do I send them?',
              a: 'Direct them to /help/guides and ask them to click the card for their role — Teacher, HR Manager, Accountant, Transport Manager, or Librarian. Each guide is self-contained with login instructions, feature walkthroughs, keyboard shortcuts, and an FAQ.',
            },
            {
              q: 'How do I report a platform bug or request a new feature?',
              a: 'Click the floating ✦ button on any page to open the NeedHelp widget. Select "Report an Issue" or "Suggest an Improvement" and describe the problem. For critical production issues, use the support email address provided in your deployment welcome email.',
            },
            {
              q: 'How do I access the Quick Start wizard after initial setup?',
              a: 'Navigate to /quick-start at any time. The wizard remembers completed steps and lets you re-run any step — useful when adding a new campus, starting a new academic year, or onboarding a replacement administrator.',
            },
            {
              q: 'Can I download all guides as PDFs for offline training?',
              a: 'Yes. The Help Centre at /help has a Downloads section with compiled PDF manuals for the Quick Start Guide, Administrator Guide, and API Manual. These are always generated from the latest guide content.',
            },
            {
              q: 'How do I reset a staff member\'s password if they are locked out?',
              a: 'Go to /users, search for the staff member, open their profile, and click "Reset Password". You can either generate a temporary password to share with them or trigger an email reset link to their registered address. The reset takes effect immediately.',
            },
          ],
        },
      ],
    },
  ],
};
