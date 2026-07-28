import type { UserGuide } from '@/lib/userGuides/types';

export const hrGuide: UserGuide = {
  id: 'hr',
  role: 'HR Manager',
  title: 'HR Manager Guide',
  tagline: 'Manage staff records, leave approvals, payroll, and workforce reports — all in one place.',
  audience: 'Human Resources managers and HR officers responsible for staff administration in Student Diwan.',
  icon: 'UserCog',
  gradient: 'from-orange-600 to-amber-600',
  accentHex: '#d97706',
  badgeBg: 'bg-orange-100 dark:bg-orange-950/40',
  badgeText: 'text-orange-700 dark:text-orange-300',
  estimatedMinutes: 30,
  version: '1.0.0',
  lastUpdated: '2026-07-17',
  chapters: [
    {
      id: 'intro',
      number: 1,
      title: 'Introduction for HR Managers',
      icon: 'UserCog',
      summary: 'Understand the HR Manager role in Student Diwan, the modules available, and how your work connects to the wider school operation.',
      blocks: [
        {
          type: 'text',
          markdown: `## Welcome, HR Manager

As the **HR Manager** in Student Diwan, you are responsible for the full staff lifecycle — from onboarding new employees and tracking daily attendance to approving leave requests, processing payroll, and generating workforce reports.

Your role operates within the **HR module** (/hr/staff and related pages). You work alongside the School Admin (who manages academic operations) and under the oversight of the Super Admin (who owns system-wide configuration).

### Key responsibilities

- Maintaining accurate staff records for all teaching and non-teaching staff
- Tracking staff attendance and linking it to payroll
- Processing and approving leave applications
- Running the monthly payroll cycle
- Generating HR reports for management and compliance
- Coordinating with the School Admin on teacher assignments`,
        },
        {
          type: 'table',
          caption: 'HR Manager permissions in Student Diwan',
          headers: ['Module / Action', 'HR Manager', 'School Admin', 'Teacher'],
          rows: [
            ['Staff directory (/hr/staff)', '✅ Full CRUD', '✅ Read only', '❌'],
            ['Staff profile — personal details', '✅ Read + Write', '✅ Read only', '❌'],
            ['Staff profile — documents', '✅ Upload + Delete', '✅ View only', '❌'],
            ['Leave applications — view all', '✅ All staff', '✅ Own school', '✅ Own only'],
            ['Leave applications — approve/reject', '✅', '✅', '❌'],
            ['Payroll — view', '✅ Full', '❌', '❌'],
            ['Payroll — process', '✅ With Super Admin approval', '❌', '❌'],
            ['HR Reports', '✅ All HR reports', '✅ Summary only', '❌'],
            ['Student records', '❌', '✅', '✅ Own classes'],
            ['Fee / Finance module', '❌', '✅', '❌'],
            ['System settings', '❌', '❌', '❌'],
            ['User accounts', '❌', '✅ Teacher/Staff', '❌'],
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'HR and School Admin work together',
          body: "The School Admin creates teacher user accounts in /users and assigns teachers to classes. The HR Manager manages the employment record of those same teachers in /hr/staff. Both views are linked by the staff member's account — updating a name in HR reflects everywhere. Coordinate with your School Admin when onboarding new teachers.",
        },
        {
          type: 'steps',
          title: 'HR Manager first-day checklist',
          steps: [
            {
              title: 'Log in and verify your profile',
              description: 'Use the credentials in your welcome email. After logging in, click your avatar (top-right) and verify your name, title, and department are correct.',
            },
            {
              title: 'Review existing staff records',
              description: 'Navigate to /hr/staff. Check that all current staff members are in the system and their employment details (designation, join date, salary) are accurate.',
            },
            {
              title: 'Verify leave balances',
              description: 'Go to /hr/staff → Leave Management and check that each staff member has been allocated the correct annual leave entitlement for the current year.',
            },
            {
              title: 'Review payroll configuration',
              description: 'Go to /settings/finance (ask your School Admin for access if needed) and verify that salary components — basic pay, allowances, deduction categories — are configured correctly.',
            },
            {
              title: 'Set up your approval workflow',
              description: 'In /hr/staff → Settings, configure who receives leave notifications and whether leave above a certain duration requires Super Admin co-approval.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/hr-staff.png',
          caption: 'The HR Staff directory — the starting point for all people management.',
          alt: 'HR Staff page showing staff list with name, designation, department, and status columns',
          annotations: [
            { id: 1, x: 7, y: 50, label: 'Sidebar', description: 'HR navigation: Staff Directory, Leave Management, Payroll, Attendance, Reports.' },
            { id: 2, x: 35, y: 11, label: 'Search', description: 'Find a staff member by name, employee ID, or department.' },
            { id: 3, x: 85, y: 11, label: 'Add Staff', description: 'Opens the new staff member form.' },
            { id: 4, x: 50, y: 54, label: 'Staff List', description: 'Columns: Name, Designation, Department, Join Date, Employment Type, Status.' },
            { id: 5, x: 92, y: 54, label: 'Action Menu', description: 'Three-dot menu: Edit, View Profile, Suspend, Archive.' },
          ],
        },
        {
          type: 'table',
          caption: 'Keyboard Shortcuts — Quick Navigation',
          headers: ['Module', 'Windows / Linux', 'macOS'],
          rows: [
            ['Dashboard', 'Alt + D', '⌘ Shift + D'],
            ['HR / Staff', 'Alt + H', '⌘ Shift + H'],
            ['Messages', 'Alt + M', '⌘ Shift + M'],
            ['Notifications', 'Alt + N', '⌘ Shift + N'],
            ['Calendar', 'Alt + X', '⌘ Shift + X'],
            ['Help Center', 'Alt + Z', '⌘ Shift + Z'],
            ['Payroll', 'Alt + PY', '⌘ Shift + PY'],
            ['Recruitment', 'Alt + RE', '⌘ Shift + RE'],
            ['Appraisals', 'Alt + AP', '⌘ Shift + AP'],
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
      id: 'login-dashboard',
      number: 2,
      title: 'Login & Dashboard',
      icon: 'KeyRound',
      summary: 'Log in with your HR credentials, understand your dashboard widgets, and navigate to key HR sections.',
      blocks: [
        {
          type: 'text',
          markdown: `## Logging In

Your account was created by the Super Admin or School Admin. You received a welcome email with a **"Set Your Password"** link, valid for 72 hours. If the link has expired, use "Forgot Password?" on the login page.

Log in at your school's Student Diwan URL with your registered email and password.

## The HR Dashboard

After login, you land on the main dashboard at **/**. As an HR Manager, your dashboard shows an HR-focused view:

### Dashboard Widgets (HR view)

- **Total Staff** — Active teaching and non-teaching staff count. Click to open /hr/staff.
- **On Leave Today** — Staff with approved leave for today. Click to see who is absent.
- **Pending Leave Requests** — Leave applications awaiting your approval, shown as a count badge.
- **Payroll Status** — Current month's payroll status: Not Started, In Progress, Processed, or Disbursed.
- **Contract Expiry Alerts** — Staff whose contracts expire within the next 30 days (requires documents to be uploaded).

### Top Bar Tools

- **Language (EN/AR)** — Toggle the interface language. Arabic mode uses RTL layout.
- **Notifications Bell** — Leave requests, contract alerts, system messages.
- **Quick Action** — Shortcuts: Add Staff, Approve Leave, Process Payroll.`,
        },
        {
          type: 'steps',
          title: 'Logging in and navigating to HR sections',
          steps: [
            {
              title: 'Go to the login page',
              description: `Navigate to your school's Student Diwan URL. Enter your email and password. Click "Sign In".`,
            },
            {
              title: 'Check the dashboard summary',
              description: 'Review the Total Staff card and Pending Leave Requests count. If there are urgent leave requests, click the count to go directly to the approval queue.',
              tip: 'Bookmark the login URL and set it as your browser homepage for fast access each morning.',
            },
            {
              title: 'Open the HR sidebar section',
              description: 'In the left sidebar, look for the "HR & Staff" group. It contains: Staff Directory, Leave Management, Payroll, Attendance, and Reports.',
            },
            {
              title: 'Navigate to Staff Directory',
              description: 'Click "Staff Directory" (or navigate to /hr/staff). This is your primary workspace — all staff management starts here.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-dashboard.png',
          caption: 'The main dashboard showing HR-relevant stats for the HR Manager role.',
          alt: 'Dashboard with Total Staff card, Pending Leave count, and Payroll Status widget',
          annotations: [
            { id: 1, x: 20, y: 20, label: 'Total Staff Card', description: 'Active staff count. Click to open the full staff directory at /hr/staff.' },
            { id: 2, x: 80, y: 20, label: 'Pending Leave', description: 'Number of leave requests awaiting your approval. Red badge when above 0.' },
            { id: 3, x: 44, y: 4, label: 'Quick Action', description: 'Shortcut menu: Add Staff Member, Approve Leave, Open Payroll.' },
            { id: 4, x: 52, y: 4, label: 'Notifications Bell', description: 'Alerts for new leave requests, contract expiry warnings, and system announcements.' },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Start your day with the notifications bell',
          body: 'Every morning, click the notification bell in the top bar to see overnight leave requests and any contract expiry alerts. Processing leave requests early means teachers know their status before the school day begins.',
        },
      ],
    },
    {
      id: 'staff-management',
      number: 3,
      title: 'Staff Management',
      icon: 'Users2',
      summary: 'Add new staff members, maintain employment records, upload documents, and manage the offboarding process.',
      blocks: [
        {
          type: 'text',
          markdown: `## Staff Records in Student Diwan

The **/hr/staff** page is the master registry for every person employed by the school. It includes teaching and non-teaching staff.

### Staff Profile Tabs

When you open a staff member's profile, you'll see these tabs:

| Tab | Contents |
|-----|----------|
| **Personal** | Full name, date of birth, nationality, national/passport ID, contact details, emergency contact |
| **Employment** | Designation, department, join date, employment type (full-time/part-time/contract), reporting manager |
| **Compensation** | Basic salary, allowances breakdown, deduction details, bank account for payroll |
| **Leave** | Annual entitlement per leave type, leave history, current balance |
| **Attendance** | Monthly attendance calendar and summary statistics |
| **Documents** | Uploaded files: passport, visa, work permit, contract, qualification certificates |
| **Academic** | (Teachers only) Assigned classes, subjects, timetable — synced from the Academic module |

### Employment Types

Student Diwan tracks three employment types: **Full-Time**, **Part-Time**, and **Contract**. Contract employees have an end date — the system alerts you 30 days before expiry.`,
        },
        {
          type: 'steps',
          title: 'Adding a new staff member',
          steps: [
            {
              title: 'Open the Staff Directory',
              description: 'Navigate to /hr/staff and click the "Add Staff" button (top-right, blue).',
            },
            {
              title: 'Enter personal details',
              description: 'Fill in: Full Name (Arabic and English if applicable), Date of Birth, Gender, Nationality, National ID or Passport Number, Personal Email, and Mobile Number.',
              tip: "The personal email is used for onboarding notifications until their school email is set up. Do not use the school email here if it hasn't been created yet.",
            },
            {
              title: 'Set employment details',
              description: `Enter: Designation (e.g., "Mathematics Teacher", "Administrative Officer"), Department, Join Date, Employment Type, and Probation End Date if applicable.`,
            },
            {
              title: 'Enter compensation details',
              description: `Go to the "Compensation" tab. Enter the Basic Salary and any allowances (Housing, Transport, Food). Add the staff member's bank account IBAN for payroll transfer.`,
            },
            {
              title: 'Upload required documents',
              description: 'Go to the "Documents" tab. Click "Upload Document" for each: Passport Copy, Visa, Work Permit, Signed Contract. Set an expiry date for time-limited documents.',
            },
            {
              title: 'Set leave entitlements',
              description: 'Go to the "Leave" tab. Verify that the system has applied the default leave entitlement for each leave type. Adjust if this staff member has a special agreement (e.g., additional annual leave).',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/hr-staff.png',
          caption: 'The Staff Directory with search, filters, and per-row action controls.',
          alt: 'HR Staff page with staff list, search bar, filter dropdowns, and Add Staff button',
          annotations: [
            { id: 1, x: 35, y: 11, label: 'Search', description: 'Search by staff name, employee ID, or email.' },
            { id: 2, x: 85, y: 11, label: 'Add Staff', description: 'Open the new staff member form.' },
            { id: 3, x: 20, y: 11, label: 'Department Filter', description: 'Filter the list by department: Teaching, Administration, Finance, Operations, etc.' },
            { id: 4, x: 50, y: 54, label: 'Staff List', description: 'Click any row to open the staff profile. Status badge: Active (green), On Leave (amber), Suspended (red).' },
            { id: 5, x: 92, y: 54, label: 'Actions', description: 'Three-dot menu: Edit, Archive (for departing staff), Reset Password (delegates to Super Admin).' },
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Archiving vs deleting a staff member',
          body: 'When a staff member leaves the school, use "Archive" — not Delete. Archiving removes them from active lists and prevents login, but preserves all their attendance, payroll, and leave history for compliance. Delete is permanent and removes all records. Only the Super Admin can delete a staff profile.',
        },
      ],
    },
    {
      id: 'leave-attendance',
      number: 4,
      title: 'Leave & Attendance',
      icon: 'CalendarCheck',
      summary: 'Process leave requests, manage leave balances, track staff attendance, and handle corrections.',
      blocks: [
        {
          type: 'text',
          markdown: `## Leave Management

Navigate to **HR → Leave Management** (or /hr/staff → Leave tab within a profile) to manage all staff leave.

### The Leave Approval Workflow

1. Staff member submits a leave application (from their portal or mobile app)
2. System notifies you (HR Manager) via email and in-app notification
3. You review the request — checking leave balance, team availability, and documentation
4. You approve or reject with a reason
5. Staff member receives the decision notification instantly

### Leave Types (Default Configuration)

| Leave Type | Annual Entitlement | Carry Forward | Documentation |
|---|---|---|---|
| Annual Leave | 30 working days | Up to 15 days | None |
| Sick Leave | 15 days | None | Medical certificate >2 days |
| Emergency Leave | 3 days | None | None |
| Maternity Leave | 60 calendar days | N/A | Hospital confirmation |
| Paternity Leave | 5 working days | None | Birth certificate |
| Unpaid Leave | No limit | N/A | Written request |
| Study Leave | Policy-dependent | No | Exam schedule |

Leave types and entitlements can be customised in HR → Settings → Leave Policies.

## Staff Attendance

Staff attendance can be recorded in three ways:
- **Manual entry** — HR marks attendance from the staff list
- **Staff self-entry** — Staff check in/out through the portal or mobile app
- **Biometric sync** — If your school has fingerprint or face recognition devices, attendance syncs automatically`,
        },
        {
          type: 'steps',
          title: 'Reviewing and approving a leave request',
          steps: [
            {
              title: 'Open Leave Management',
              description: 'Go to /hr/staff and click the "Leave Management" tab, or click the notification badge from the dashboard or bell icon.',
            },
            {
              title: 'Review pending requests',
              description: 'Pending requests are listed at the top, sorted by submission date (oldest first). Each card shows: Staff Name, Leave Type, Date Range, Duration, and Reason.',
            },
            {
              title: 'Check the leave balance',
              description: "Click the staff member's name to open their profile. Go to the Leave tab to see their remaining balance for the requested leave type.",
              tip: "If the staff member doesn't have enough balance for a paid leave, you can either reject the request or approve it as Unpaid Leave after discussing with the staff member.",
            },
            {
              title: 'Verify team coverage',
              description: "For teachers, check whether a substitute can be arranged during the requested period. Check the timetable (/timetable) for the teacher's classes during those days.",
            },
            {
              title: 'Approve or reject',
              description: 'Click "Approve" to grant the leave — the balance is automatically deducted. Click "Reject" and select a rejection reason from the dropdown (optional: add a note). The staff member is notified immediately.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/hr-leave.png',
          caption: 'The Leave Management page showing pending requests and approved history.',
          alt: 'Leave management page with pending leave request cards and leave history table',
          annotations: [
            { id: 1, x: 50, y: 15, label: 'Pending Requests', description: 'Leave applications awaiting approval, sorted by submission date. Oldest first.' },
            { id: 2, x: 85, y: 15, label: 'Approve / Reject', description: 'Action buttons on each pending card. Rejection requires a reason.' },
            { id: 3, x: 25, y: 20, label: 'Leave Type Badge', description: 'Color-coded by type: Annual (blue), Sick (red), Emergency (amber), Unpaid (grey).' },
            { id: 4, x: 50, y: 60, label: 'Leave History', description: 'All approved, rejected, and cancelled leave records for all staff. Filterable by staff name, type, or date.' },
            { id: 5, x: 85, y: 60, label: 'Export', description: 'Download the leave history as CSV or PDF for compliance reporting.' },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Bulk approve annual leave before the holiday season',
          body: 'Before school holidays, many staff submit annual leave requests simultaneously. Use the "Bulk Actions" checkbox on the leave management page to select multiple requests and approve them in one click — much faster than approving one by one.',
        },
      ],
    },
    {
      id: 'payroll',
      number: 5,
      title: 'Payroll Management',
      icon: 'Banknote',
      summary: 'Process monthly payroll, manage salary components, handle deductions, and distribute pay slips.',
      blocks: [
        {
          type: 'text',
          markdown: `## Payroll in Student Diwan

The payroll module processes monthly salaries for all active staff. It automatically incorporates:

- **Base salary** — from the staff member's Compensation tab
- **Allowances** — Housing, Transport, Food (configured per staff member)
- **Attendance deductions** — Calculated from unauthorised absences in the attendance record
- **Leave deductions** — Unpaid leave days are automatically deducted
- **Overtime** — If tracked, added as additional pay
- **Manual adjustments** — Bonuses, one-time deductions, advances

### Payroll Cycle

Student Diwan uses a monthly payroll cycle. The recommended workflow:

1. Close attendance for the month (confirm all marks are final) — by the 25th
2. Run payroll preview — review all calculations — 26th–28th
3. Get Super Admin approval if required by your school's policy
4. Process payroll — 28th–30th
5. Export bank file or trigger bank transfer — 30th
6. Distribute pay slips via email — 30th–1st

### Payroll Statuses

| Status | Meaning |
|--------|---------|
| Not Started | Payroll for this month has not been initiated |
| In Progress | Preview generated; under review |
| Approved | Confirmed; awaiting processing |
| Processed | Finalized; pay slips generated |
| Disbursed | Bank transfers completed |`,
        },
        {
          type: 'steps',
          title: 'Processing the monthly payroll',
          steps: [
            {
              title: 'Navigate to Payroll',
              description: 'Go to /hr/staff → Payroll, or click "Payroll" in the HR sidebar section.',
            },
            {
              title: 'Select the payroll month',
              description: 'Choose the month and year from the dropdown. Click "Start Payroll" to generate the preview. This pulls attendance data, leave records, and salary configurations automatically.',
            },
            {
              title: 'Review the payroll preview',
              description: 'The preview shows a table: one row per staff member with columns for Base Salary, Allowances, Deductions, Overtime, and Net Pay. Click any row to see the full earnings breakdown.',
              tip: 'Filter by "Has Deductions" to quickly spot staff with attendance or leave deductions that need verification.',
            },
            {
              title: 'Add manual adjustments',
              description: 'Click the pencil icon on any staff row to add: a one-time bonus, advance recovery, or a custom deduction. Enter the amount and a description (shown on the pay slip).',
            },
            {
              title: 'Submit for approval (if required)',
              description: 'If your school requires Super Admin approval before processing, click "Submit for Approval". The Super Admin receives a notification and can approve from their dashboard.',
            },
            {
              title: 'Process and distribute pay slips',
              description: 'Once approved, click "Process Payroll". The status changes to Processed. Then click "Send Pay Slips" to email each staff member a password-protected PDF of their pay slip.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/hr-staff.png',
          caption: 'The Staff Directory is the entry point for accessing individual payroll records.',
          alt: 'Staff list page with action controls linking to payroll and leave records',
          annotations: [
            { id: 1, x: 50, y: 54, label: 'Staff Rows', description: 'Click any staff member to open their profile and navigate to the Compensation tab for salary details.' },
            { id: 2, x: 20, y: 11, label: 'Department Filter', description: 'Filter by department to review payroll for a specific team.' },
            { id: 3, x: 85, y: 11, label: 'Payroll Button', description: 'Opens the payroll processing page for the selected month.' },
          ],
        },
        {
          type: 'callout',
          variant: 'danger',
          title: 'Payroll cannot be reversed once processed',
          body: 'Clicking "Process Payroll" locks the payroll for that month. Errors discovered after processing must be corrected via a supplementary payroll in the following month — you cannot reopen a processed payroll. Always complete a thorough review of the preview before processing.',
        },
      ],
    },
    {
      id: 'reports-faq',
      number: 6,
      title: 'Reports & FAQ',
      icon: 'FileBarChart',
      summary: 'Generate HR reports for management and compliance, schedule automated reports, and find answers to common questions.',
      blocks: [
        {
          type: 'text',
          markdown: `## HR Reports

Navigate to **/reports** and click the "HR" tab to access all HR-specific reports. Reports can be generated on demand or scheduled for automatic delivery.

### Available HR Reports

| Report | Description | Frequency |
|--------|-------------|-----------|
| Staff Directory | Full list with designation, department, contact, join date | On demand |
| Staff Attendance Summary | Monthly attendance rates per staff member | Monthly |
| Leave Balance Report | Remaining leave balances for all staff | On demand / Monthly |
| Leave Utilisation Report | Leave taken vs entitlement by leave type | Quarterly |
| Payroll Summary | Total payroll cost breakdown by department | Monthly |
| Pay Slip Archive | All pay slips for a selected period | On demand |
| Contract Expiry Report | Staff with contracts expiring in the next N days | On demand / Weekly |
| Staff Turnover Report | Joiners and leavers for a selected period | Quarterly |

### Scheduling Reports

To schedule a report for automatic delivery:
1. Open /reports → HR tab → select the report
2. Click "Schedule Report"
3. Set the frequency (Daily, Weekly, Monthly) and the delivery day
4. Enter the recipient email addresses (comma-separated)
5. Click "Save Schedule"

The report runs at midnight on the scheduled day and is emailed as a PDF attachment.`,
        },
        {
          type: 'steps',
          title: 'Generating the monthly payroll summary report',
          steps: [
            {
              title: 'Open Reports',
              description: 'Navigate to /reports and click the "HR" tab.',
            },
            {
              title: 'Select Payroll Summary',
              description: 'Click "Payroll Summary" from the report list.',
            },
            {
              title: 'Set parameters',
              description: 'Choose the Month and Year. Select whether to include All Departments or a specific one. Click "Generate Report".',
            },
            {
              title: 'Review the output',
              description: 'The report shows: total payroll cost, breakdown by department, per-staff net pay, and total deductions. Charts show the cost distribution.',
            },
            {
              title: 'Export',
              description: `Click "Export PDF" for a management-ready formatted report, or "Export CSV" for a spreadsheet that can be imported into your school's accounting software.`,
              tip: 'Save the monthly payroll PDF in a shared folder as part of your financial record-keeping process.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/hr-staff.png',
          caption: 'The Staff Directory — the foundation for accurate reports.',
          alt: 'HR Staff page showing staff list from which all HR reporting data is drawn',
          annotations: [
            { id: 1, x: 50, y: 54, label: 'Staff Data', description: 'All HR report data originates from staff profiles. Keep profiles up to date for accurate reports.' },
            { id: 2, x: 20, y: 11, label: 'Department Filter', description: 'Filter by department before exporting to generate department-specific reports quickly.' },
            { id: 3, x: 85, y: 11, label: 'Export', description: 'Export the filtered staff list as CSV or PDF — useful for the Staff Directory report.' },
          ],
        },
        {
          type: 'callout',
          variant: 'success',
          title: 'Schedule the Contract Expiry report weekly',
          body: "Set up a weekly Contract Expiry report scheduled to run every Monday, sent to yourself and the School Admin. This ensures you never miss a contract renewal — giving you at least 4 weeks' notice before a contract expires.",
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'A staff member says their leave balance is wrong. How do I correct it?',
              a: `Open the staff member's profile in /hr/staff and go to the "Leave" tab. You will see their balance per leave type. Click "Adjust Balance" next to the relevant type, enter the correction amount, and add a note explaining the reason (e.g., "Correction for carry-forward from previous year"). The adjustment is logged in the audit trail.`,
            },
            {
              q: 'I forgot to mark a staff member as absent for a day. Can I correct past attendance?',
              a: `Yes. Go to /hr/staff, open the staff member's profile, click the "Attendance" tab, and find the date in question. Click the calendar cell for that day and change the status. You will need to enter a correction reason. Past attendance corrections are logged in the audit trail.`,
            },
            {
              q: "A teacher was added by the School Admin in /users but doesn't appear in the HR Staff directory. Why?",
              a: 'User accounts (created in /users) and HR Staff records (/hr/staff) are linked but created separately. When the School Admin creates a teacher account, an HR record is not automatically created. You need to manually add the staff member in /hr/staff and link their user account using the "Link to User Account" option in the Employment tab.',
            },
            {
              q: 'How do I handle a staff member who is leaving the school?',
              a: 'Go to their staff profile in /hr/staff. Click the three-dot menu (top-right) and select "Offboard Staff". The offboarding wizard prompts you to: set the last working day, process any final pay or leave encashment, collect and archive company assets, and archive the profile. After archiving, the staff member cannot log in but their records are preserved.',
            },
            {
              q: 'Can I configure different payroll cycles for different staff groups?',
              a: 'Student Diwan supports one payroll cycle per school (monthly, bi-weekly, or weekly, configured by the Super Admin). If different staff groups (e.g., full-time vs. hourly) need different cycles, contact your Super Admin to discuss whether multi-cycle configuration is available in your deployment.',
            },
            {
              q: 'How do I generate an official employment letter for a staff member?',
              a: `Go to the staff member"s profile in /hr/staff. Click the three-dot menu and select \"Generate Letter\". Choose \"Employment Verification Letter\" from the template list. The letter auto-fills the staff member\"s name, designation, department, join date, and salary. Click "Generate PDF" to download the letter with your school's letterhead and signature block.`,
            },
          ],
        },
      ],
    },
    {
      id: 'hr-help',
      number: 7,
      title: 'Help Centre & Support',
      icon: 'LifeBuoy',
      summary: 'Find HR documentation, resolve payroll and leave questions, and get platform support.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Your Help Centre\n\nThe Help Centre at `/help` gives you access to the HR Manager Guide along with articles covering payroll setup, leave policy configuration, and staff record management. For technical issues with payroll calculations or data exports, the NeedHelp widget connects you directly to platform support.\n\nPress **Alt + Z** (Windows) or **⌘ Shift + Z** (Mac) from any page to open the Help Centre instantly.",
        },
        {
          type: 'steps',
          title: 'How to Open the Help Centre',
          steps: [
            {
              title: 'Press Alt + Z or ⌘ Shift + Z',
              description: 'Open the Help Centre keyboard shortcut from any page — useful when you need a quick answer on a payroll or leave procedure without navigating away.',
            },
            {
              title: 'Click Help in the Sidebar',
              description: 'The Help icon at the bottom of the left sidebar opens the Help Home page at /help.',
            },
            {
              title: 'Open the HR Manager Guide',
              description: 'Go to /help/guides/hr or select the HR Manager card on the Guide Hub for the complete role manual covering staff management, leave, payroll, and reports.',
            },
            {
              title: 'Report a Payroll or System Error',
              description: 'For payroll calculation errors or data inconsistencies that cannot be resolved manually, click the floating ✦ button and provide the affected employee IDs, pay period, and the discrepancy details.',
            },
          ],
        },
        {
          type: 'table',
          caption: 'Help Resources Available to HR Managers',
          headers: ['Resource', 'What It Covers', 'Where to Find It'],
          rows: [
            ['HR Manager Guide — Chapter 3', 'Staff Management: onboarding, profile creation, document uploads, and role assignment', '/help/guides/hr'],
            ['HR Manager Guide — Chapter 4', 'Leave & Attendance: leave policy setup, approval workflows, and attendance reporting', '/help/guides/hr'],
            ['HR Manager Guide — Chapter 5', 'Payroll Management: salary structures, allowances, deductions, and payslip generation', '/help/guides/hr'],
            ['HR Manager Guide — Chapter 6', 'Reports & FAQ: workforce reports, common payroll issues, and escalation steps', '/help/guides/hr'],
            ['Help Category Browser — HR', 'Searchable articles on leave entitlements, payroll tax setup, and staff document management', '/help'],
            ['NeedHelp Widget', 'Escalate payroll calculation errors, export failures, or data integrity issues to platform support', 'Floating ✦ button — any page'],
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Payroll Discrepancies: Steps Before Escalating',
          body: 'Before using the NeedHelp widget for a payroll issue, verify: (1) the correct salary structure is assigned to the employee, (2) all allowances and deductions are active for the pay period, (3) any leave without pay has been recorded and approved. If all three are correct and the figure is still wrong, use the ✦ widget to escalate — include the employee ID, pay period, expected amount, and calculated amount.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'A staff member was on unpaid leave but their payslip shows a full month salary. How do I correct it?',
              a: 'Go to the staff member\'s leave record (/hr/leave) and confirm the leave is approved and marked as "Leave Without Pay" (LWP). If it is, regenerate the payslip for that month — the system should deduct the LWP days automatically. If the deduction still does not appear after regenerating, use the NeedHelp widget and include the employee ID and pay period.',
            },
            {
              q: 'A new teacher joined mid-month. How is their salary calculated?',
              a: "Student Diwan calculates pro-rated salary based on the joining date you entered when creating the staff profile. Go to /hr/staff, open the profile, and verify the 'Date of Joining' is correct. If the date is right but the payslip is still showing a full month, re-run payroll for that employee using the 'Recalculate' option in the payroll module.",
            },
            {
              q: 'How do I export the full staff list with salary details for an audit?',
              a: 'Go to /reports → HR → Staff Salary Report. Select the pay period and click "Generate". The report includes employee names, designations, base salary, allowances, deductions, and net pay. Export it as CSV or Excel using the download button. For an audit-grade report with a timestamp and your name, click "Export Certified Report".',
            },
            {
              q: 'A staff member disputes their leave balance. How do I verify it?',
              a: "Open the staff member's leave record at /hr/leave and select their name. The Leave Ledger tab shows every leave application, approval, cancellation, and balance adjustment from the start of the leave year. If the balance looks incorrect, check whether any manually adjusted entries exist — these are flagged with a pencil icon and the name of the admin who made the change.",
            },
          ],
        },
      ],
    },
  ],
};
