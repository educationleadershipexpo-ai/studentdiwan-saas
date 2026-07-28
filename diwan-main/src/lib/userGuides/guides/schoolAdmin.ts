import type { UserGuide } from '@/lib/userGuides/types';

export const schoolAdminGuide: UserGuide = {
  id: 'school-admin',
  role: 'School Administrator',
  title: 'School Administrator Guide',
  tagline: "Run your school's daily operations — from student enrollment to fee management and academic scheduling.",
  audience: 'Principals, academic coordinators, and administrative staff responsible for day-to-day school operations.',
  icon: 'Building2',
  gradient: 'from-blue-600 to-indigo-700',
  accentHex: '#2563eb',
  badgeBg: 'bg-blue-100 dark:bg-blue-950/40',
  badgeText: 'text-blue-700 dark:text-blue-300',
  estimatedMinutes: 35,
  version: '1.0.0',
  lastUpdated: '2026-07-17',
  chapters: [
    {
      id: 'intro',
      number: 1,
      title: 'Introduction to School Admin',
      icon: 'Building2',
      summary: 'Understand the School Admin role, its scope within Student Diwan, and the key modules you will use every day.',
      blocks: [
        {
          type: 'text',
          markdown: `## Welcome, School Administrator

As the **School Administrator** in Student Diwan, you are the operational hub of the school. Your role bridges system configuration (owned by the Super Admin) and the day-to-day work of teachers and HR staff. You are responsible for:

- **Student lifecycle management** — admissions, enrollment, transfers, and graduation
- **Academic structure** — classes, subjects, timetables, and exam schedules
- **Fee administration** — fee plans, invoicing, and payment tracking
- **Staff coordination** — creating teacher accounts, assigning classes, monitoring attendance
- **Reporting** — generating reports for management, parents, and regulatory bodies

You do **not** have access to: system-level settings (e.g., school branding, API integrations), other schools' data (if multi-campus), or the full audit log. Contact your Super Admin for those.`,
        },
        {
          type: 'table',
          caption: 'School Admin module access at a glance',
          headers: ['Module', 'Access Level', 'Key Actions'],
          rows: [
            ['Dashboard', 'Full', 'View all stats, charts, activity feed'],
            ['Students (/students)', 'Read + Write', 'Enroll, edit, transfer, promote, archive'],
            ['Admissions (/admissions)', 'Full', 'Manage applications, approve/reject, convert to student'],
            ['Attendance (/attendance)', 'Read + Override', 'View reports, correct erroneous marks'],
            ['Classes (/academics/classes)', 'Full', 'Create classes, assign teachers, manage sections'],
            ['Subjects (/academics/subjects)', 'Full', 'Create/edit subjects, assign to classes'],
            ['Timetable (/timetable)', 'Full', 'Build and publish class timetables'],
            ['Fee Configuration (/settings/finance)', 'Full', 'Create fee plans, set amounts, apply discounts'],
            ['Fee Collection (/finance/fees)', 'Read + Write', 'Record payments, generate invoices, track outstanding'],
            ['HR Staff (/hr/staff)', 'Read', 'View staff list and basic profiles'],
            ['Reports (/reports)', 'School-scope', 'All reports except audit logs and HR payroll'],
            ['Users (/users)', 'Teacher + Staff roles only', 'Create/edit teacher and admin-staff accounts'],
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Working alongside your Super Admin',
          body: 'Before you start using Student Diwan, your Super Admin must complete the initial setup: school identity (name, logo, timezone), the current academic year, and your own user account. Check with your Super Admin that /settings/academic has an active year before enrolling any students.',
        },
        {
          type: 'steps',
          title: 'School Admin first-day checklist',
          steps: [
            {
              title: 'Verify active academic year',
              description: 'Go to /settings/academic and confirm there is an active academic year shown with a green "Active" badge. If not, contact your Super Admin.',
            },
            {
              title: 'Create your class structure',
              description: 'Navigate to /academics/classes and create the grade levels and sections your school uses (e.g., Grade 1 – Section A, Grade 1 – Section B).',
            },
            {
              title: 'Add subjects',
              description: 'Go to /academics/subjects and create the subjects taught at your school. Assign each subject to the relevant grades.',
            },
            {
              title: 'Set up fee plans',
              description: 'Navigate to /settings/finance and create fee categories and fee plans for each grade level.',
            },
            {
              title: 'Invite teachers',
              description: 'Go to /users and create teacher accounts. Assign each teacher to their class(es) and subject(s).',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-dashboard.png',
          caption: 'The School Admin dashboard mirrors the Super Admin view but is scoped to your school.',
          alt: 'School Admin dashboard showing stats, charts and activity feed',
          annotations: [
            { id: 1, x: 7, y: 50, label: 'Navigation Sidebar', description: 'All modules the School Admin can access. Modules you cannot access (system settings, audit) are not shown.' },
            { id: 2, x: 20, y: 20, label: 'Total Students', description: 'Enrolled students in the active academic year. Click to open /students.' },
            { id: 3, x: 50, y: 20, label: 'Fee Collection', description: 'Total fees collected this month. Click to open /finance/fees.' },
            { id: 4, x: 80, y: 20, label: 'Attendance %', description: 'School-wide attendance for today. Red below 75%, amber 75–89%, green 90%+.' },
            { id: 5, x: 44, y: 4, label: 'Quick Action', description: 'Shortcuts: Add Student, Record Payment, View Timetable, Generate Report.' },
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
            ['Help Center', 'Alt + Z', '⌘ Shift + Z'],
            ['Subjects', 'Alt + S', '⌘ Shift + S'],
            ['Reports', 'Alt + R', '⌘ Shift + R'],
            ['Student Mgmt', 'Alt + SM', '⌘ Shift + SM'],
            ['Room Management', 'Alt + RM', '⌘ Shift + RM'],
            ['Subject Codes', 'Alt + SC', '⌘ Shift + SC'],
            ['Assignments', 'Alt + AM', '⌘ Shift + AM'],
            ['Assessments', 'Alt + AE', '⌘ Shift + AE'],
            ['Transport', 'Alt + V', '⌘ Shift + V'],
            ['Security', 'Alt + U', '⌘ Shift + U'],
            ['Inventory', 'Alt + Y', '⌘ Shift + Y'],
            ['Flashcards', 'Alt + FL', '⌘ Shift + FL'],
            ['Parent-Teacher Meetings', 'Alt + PT', '⌘ Shift + PT'],
            ['Transcripts', 'Alt + TR', '⌘ Shift + TR'],
            ['Certificates', 'Alt + CE', '⌘ Shift + CE'],
            ['Stock', 'Alt + ST', '⌘ Shift + ST'],
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
      id: 'login-setup',
      number: 2,
      title: 'Login & First Setup',
      icon: 'KeyRound',
      summary: 'Log in with your admin credentials, change your password, explore the navigation, and run the Quick Start wizard.',
      blocks: [
        {
          type: 'text',
          markdown: `## Logging In

You will receive a welcome email from Student Diwan with a **\"Set Your Password\"** link. This link is valid for 72 hours. Click it, set a strong password (minimum 10 characters, at least one uppercase letter and one number), and you will be redirected to the login page.

Log in at your school's Student Diwan URL with your email and new password.

## The Quick Start Wizard

After your first login, a **Quick Start** banner appears at the top of the dashboard. Click **\"Go to Quick Start\"** or navigate to **/quick-start** to open the setup checklist. This wizard guides you through:

1. Verifying school identity (name, logo, timezone) — set by your Super Admin
2. Creating the academic year ✓ (your Super Admin should have done this)
3. Setting up grades and classes
4. Adding subjects and assigning to classes
5. Creating teacher accounts
6. Configuring fee plans
7. Enrolling your first students

Each step has a completion indicator. You can complete steps in any order; the wizard remembers your progress.`,
        },
        {
          type: "steps",
          title: 'Setting your password and first login',
          steps: [
            {
              title: 'Find the welcome email',
              description: 'Check your inbox (and spam folder) for an email from no-reply@studentdiwan.com with the subject "Welcome to Student Diwan — Set Your Password".',
            },
            {
              title: 'Click "Set Your Password"',
              description: 'The link opens a page with two fields: New Password and Confirm Password. Enter a strong password and click "Set Password".',
              tip: 'Use a password manager to generate and store a strong, unique password.',
            },
            {
              title: 'Log in for the first time',
              description: 'You will be redirected to the login page. Enter your email and the password you just set, then click "Sign In".',
            },
            {
              title: 'Update your profile',
              description: `Click your avatar in the top-right corner, select "My Profile", and add your phone number and a profile photo. This information appears in staff directories.`,
            },
            {
              title: 'Open the Quick Start wizard',
              description: 'Click the "Go to Quick Start" banner on the dashboard or navigate to /quick-start. Work through the checklist from top to bottom.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/login-portal.png',
          caption: 'The Student Diwan login portal — your entry point every day.',
          alt: 'Login portal with email and password fields',
          annotations: [
            { id: 1, x: 50, y: 30, label: 'Email Field', description: 'Your registered school email address.' },
            { id: 2, x: 50, y: 50, label: 'Password Field', description: 'Your account password. Click the eye icon to reveal.' },
            { id: 3, x: 50, y: 65, label: 'Sign In Button', description: 'Submits your credentials and loads the dashboard.' },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: "Use the Quick Start wizard — don't skip it",
          body: 'The Quick Start wizard at /quick-start is the fastest way to configure Student Diwan correctly. It catches missing steps (like an unlinked fee plan) that would cause errors later when parents try to pay or teachers try to take attendance.',
        },
      ],
    },
    {
      id: 'academic-structure',
      number: 3,
      title: 'Academic Year & Classes',
      icon: 'CalendarDays',
      summary: 'Build your academic structure: grades, sections, subjects, timetables, and the class-teacher assignment.',
      blocks: [
        {
          type: 'text',
          markdown: `## Building Your Academic Structure

Before enrolling students or assigning teachers, you must define the **academic skeleton** of your school. This consists of four layers:

1. **Academic Year** — the overarching container (e.g., 2026–2027). Set by Super Admin.
2. **Grades/Classes** (/academics/classes) — the year levels (Grade 1, Grade 2, … or KG1, KG2, Primary, etc.)
3. **Sections** — divisions within a grade (Section A, B, C). Each section has a class teacher.
4. **Subjects** (/academics/subjects) — the subjects taught, each linked to one or more grades.

### Timetable

Once classes and subjects exist, build the timetable at **/timetable**. The timetable builder uses a drag-and-drop grid: rows are periods (08:00–08:45, 08:45–09:30, …) and columns are days (Sun–Thu or Mon–Fri based on your school's week). Drag a subject card from the right panel onto a cell to assign it.

After publishing a timetable, teachers see it on their dashboard and students see it on their profiles. Timetables are version-controlled — you can make changes and publish a new version without losing the previous one.`,
        },
        {
          type: "steps",
          title: 'Creating classes and assigning teachers',
          steps: [
            {
              title: 'Open Classes',
              description: 'Navigate to /academics/classes. Click "Add Class" to create a new grade level.',
            },
            {
              title: 'Define the grade',
              description: 'Enter the class name (e.g., "Grade 5"), select the academic year, and choose the number of sections. Each section gets its own class teacher.',
            },
            {
              title: 'Assign a class teacher',
              description: 'For each section, select a teacher from the "Class Teacher" dropdown. Only active teacher accounts appear here. The class teacher is responsible for attendance and is the primary contact for parents.',
              tip: 'A teacher can be the class teacher of only one section, but can teach subjects in multiple sections.',
            },
            {
              title: 'Link subjects to the class',
              description: 'In the "Subjects" tab of the class card, add the subjects taught in this grade. For each subject, assign the teacher who will teach it.',
            },
            {
              title: 'Build and publish the timetable',
              description: 'Go to /timetable. Select the class from the dropdown, drag subjects into period slots, then click "Publish". Teachers and students see the timetable immediately.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-timetable.png',
          caption: 'The timetable builder — drag subjects into time slots to create the weekly schedule.',
          alt: 'Timetable builder grid with periods as rows, days as columns, and subject cards in the panel',
          annotations: [
            { id: 1, x: 20, y: 20, label: 'Class Selector', description: 'Choose the class and section you are building the timetable for.' },
            { id: 2, x: 85, y: 40, label: 'Subject Panel', description: 'Drag a subject card from here into a time-slot cell on the grid.' },
            { id: 3, x: 50, y: 50, label: 'Timetable Grid', description: 'Rows = periods, columns = school days. Click a filled cell to edit or remove the assignment.' },
            { id: 4, x: 80, y: 10, label: 'Publish Button', description: 'Makes the timetable visible to teachers and students. Unpublished timetables are drafts only.' },
            { id: 5, x: 20, y: 10, label: 'Version History', description: 'See all previous timetable versions. Restore a version if needed.' },
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Publish before term starts',
          body: 'Teachers cannot take attendance for a class until the timetable is published. Publish timetables at least one day before the term begins to avoid missing attendance records on day one.',
        },
      ],
    },
    {
      id: 'student-management',
      number: 4,
      title: 'Student Management',
      icon: 'UserCheck',
      summary: 'Enroll new students, manage admissions, update student profiles, handle transfers, and promote students between grades.',
      blocks: [
        {
          type: 'text',
          markdown: `## The Student Lifecycle in Student Diwan

A student moves through several stages in the system:

**Application → Admission Review → Enrolled → Active → Promoted / Transferred / Graduated / Archived**

### Admissions (/admissions)

Manage inbound applications from prospective students. Each application has a status: **Pending**, **Under Review**, **Approved**, or **Rejected**. When you approve an application, Student Diwan automatically creates a new student record and prompts you to assign the student to a class.

### Students (/students)

The students page lists all enrolled students. Key columns: Student ID, Full Name, Class, Section, Enrollment Date, and Status. Use the **search bar** to find a student by name or ID. Use the **filters** to narrow by class, section, status, or gender.

### Student Profile

Click any row to open the student's full profile. Tabs include:
- **Personal** — name, date of birth, nationality, contact details
- **Academic** — class, section, subjects, academic history
- **Attendance** — monthly attendance grid, percentage, leave records
- **Finance** — fee plan, invoices, payments, outstanding balance
- **Documents** — uploaded files (birth certificate, passport, previous reports)`,
        },
        {
          type: "steps",
          title: 'Enrolling a new student manually',
          steps: [
            {
              title: 'Open the Students page',
              description: 'Navigate to /students. Alternatively, if the student applied through /admissions and was approved, they are already created — search for them there.',
            },
            {
              title: 'Click "Add Student"',
              description: 'The blue "Add Student" button is at the top-right. This opens the enrollment form.',
            },
            {
              title: 'Enter personal information',
              description: 'Fill in: First Name, Last Name, Date of Birth, Gender, Nationality, and national/passport ID. All fields marked with * are required.',
              tip: "The Student ID field auto-generates based on your school's numbering scheme. You can override it if needed.",
            },
            {
              title: 'Assign to a class',
              description: "Select the Academic Year, Grade, and Section. The class teacher's name appears below the section for confirmation.",
            },
            {
              title: 'Assign a fee plan',
              description: `In the "Finance" tab of the enrollment form, select the fee plan applicable to this student. The system will generate invoices based on the plan's schedule.`,
            },
            {
              title: 'Save and notify',
              description: 'Click "Enroll Student". The student profile is created and, if the student has a parent account, the parent receives a welcome notification.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-students.png',
          caption: 'The Students page with search, filters, and the Add Student button.',
          alt: 'Students page showing search bar, filter dropdowns, student table with columns, and Add Student button',
          annotations: [
            { id: 1, x: 35, y: 11, label: 'Search Bar', description: 'Search by student name, student ID, or parent name. Results update instantly.' },
            { id: 2, x: 85, y: 11, label: 'Add Student', description: 'Opens the enrollment form to manually add a new student.' },
            { id: 3, x: 25, y: 54, label: 'Student Rows', description: 'Each row is a student. Columns: ID, Name, Class, Section, Status. Click any row to open the profile.' },
            { id: 4, x: 92, y: 54, label: 'Row Actions', description: 'Three-dot menu: Edit, View Profile, Transfer, Promote, Archive.' },
            { id: 5, x: 65, y: 11, label: 'Filter Bar', description: 'Filter by Grade, Section, Status (Active/Inactive), or Academic Year.' },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Bulk import from CSV',
          body: 'To enroll many students at once, use the "Import" button next to "Add Student". Download the CSV template, fill in one student per row, and upload. The system validates each row and shows errors before importing. Fix errors in the CSV and re-upload — already-valid rows are not duplicated.',
        },
      ],
    },
    {
      id: 'fee-configuration',
      number: 5,
      title: 'Fee Configuration',
      icon: 'CreditCard',
      summary: 'Create fee categories, build fee plans for each grade, configure invoicing schedules, and apply discounts.',
      blocks: [
        {
          type: 'text',
          markdown: `## Fee Management in Student Diwan

Student Diwan's finance module handles the full fee lifecycle: **configuration → invoice generation → payment collection → reconciliation**.

### Fee Categories (/settings/finance → Fee Categories)

A fee category is the type of charge: Tuition, Transport, Library, Sports, Canteen, Uniform, etc. Create as many categories as your school uses. Each category has a name, description, and whether it is taxable.

### Fee Plans (/settings/finance → Fee Plans)

A fee plan is a schedule of charges applied to a group of students (typically per grade). Each fee plan contains:

| Field | Example |
|---|---|
| Plan Name | Grade 5 Standard 2026–27 |
| Academic Year | 2026–2027 |
| Applicable Grades | Grade 5 |
| Fee Items | Tuition: 5,000 AED/term × 3 terms |
| | Transport: 2,000 AED/year |
| | Activities: 500 AED/year |
| Invoice Schedule | Beginning of each term |
| Late Fee | 2% per month after due date |

### Discounts and Scholarships

Go to /settings/finance → Discounts to create discount schemes: sibling discount (10%), scholarship (full or partial), staff child discount, etc. Discounts are applied at the student level from the student's Finance tab.`,
        },
        {
          type: 'steps',
          title: 'Creating a fee plan for a grade',
          steps: [
            {
              title: 'Open Finance Settings',
              description: 'Navigate to /settings/finance and click the "Fee Plans" tab.',
            },
            {
              title: 'Click "New Fee Plan"',
              description: 'Enter the plan name, select the academic year, and choose which grades this plan applies to.',
            },
            {
              title: 'Add fee items',
              description: 'Click "Add Fee Item". For each item, select the fee category (Tuition, Transport, etc.), enter the amount, and choose the frequency: One-time, Per Term, Per Month, or Annual.',
              tip: 'If tuition is paid in instalments, set the frequency to "Per Term" and Student Diwan will generate one invoice per term automatically.',
            },
            {
              title: 'Set the invoicing schedule',
              description: 'Choose when invoices are generated: at the start of term, 30 days before, or on a fixed date. Set the payment due date (e.g., 30 days after invoice date). Configure the late fee penalty if applicable.',
            },
            {
              title: 'Save and assign to students',
              description: `Click "Save Fee Plan". Go to each student's Finance tab and assign this plan, or use the bulk-assign option: /students → select students → Bulk Action → Assign Fee Plan.`,
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-dashboard.png',
          caption: "The Fee Collection card on the dashboard gives a quick summary of this month's revenue.",
          alt: 'Dashboard fee collection stats card showing collected amount and outstanding balance',
          annotations: [
            { id: 1, x: 50, y: 20, label: 'Fee Collection Card', description: 'Shows total collected this month and total outstanding. Click to open /finance/fees.' },
            { id: 2, x: 20, y: 46, label: 'Fee Chart', description: 'Monthly fee collection bar chart. Hover a bar for collected vs outstanding breakdown.' },
            { id: 3, x: 44, y: 4, label: 'Quick Action', description: 'Use Quick Action > Record Payment for a fast payment entry without navigating to /finance/fees.' },
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Invoices lock fee amounts',
          body: "Once an invoice is generated, the fee amount on that invoice is locked — even if you edit the fee plan later. To apply a corrected amount, you must void the incorrect invoice and generate a new one from the student's Finance tab. Always verify fee amounts before the invoicing date.",
        },
      ],
    },
    {
      id: 'daily-operations',
      number: 6,
      title: 'Daily Operations',
      icon: 'ClipboardList',
      summary: 'Manage day-to-day tasks: monitor attendance, handle parent queries, generate reports, and troubleshoot common issues.',
      blocks: [
        {
          type: 'text',
          markdown: `## Your Daily Workflow as School Admin

A typical school day in Student Diwan follows this rhythm:

**Morning**
- Check the dashboard for today's attendance percentage. If it is below 80% by 09:30, investigate missing class attendance marks.
- Review the activity feed for overnight events: new admissions, parent messages, or fee payments.

**Mid-day**
- Process new admissions in /admissions — approve or reject pending applications.
- Handle parent queries via the notification centre (bell icon, top bar).
- Check /finance/fees for overdue invoices and follow up with reminders.

**End of day**
- Run the \"Daily Attendance Summary\" report from /reports → Attendance.
- Review any teacher leave requests pending your approval in /hr/staff.
- Export the \"Outstanding Fees\" report if required by management.

## Managing Attendance Corrections

Teachers mark attendance daily. As School Admin, you can **override** a mark if it was recorded in error. Go to /attendance, find the class, the date, and the student, click the mark, and select \"Override\". You must enter a reason — this is recorded in the audit log.`,
        },
        {
          type: "steps",
          title: 'Generating a monthly attendance report',
          steps: [
            {
              title: 'Open Reports',
              description: 'Navigate to /reports and click the "Attendance" tab.',
            },
            {
              title: 'Select report type',
              description: 'Choose "Monthly Attendance Summary". This report shows per-student attendance counts and percentage for a selected month.',
            },
            {
              title: 'Set parameters',
              description: 'Select the Month, Class (or "All Classes"), and Academic Year. Click "Generate Report".',
            },
            {
              title: 'Review and export',
              description: 'The report renders in the browser. Use the "Export PDF" button for a printable version or "Export CSV" for spreadsheet analysis.',
              tip: 'Schedule this report to auto-email to the principal every first Monday of the month from Reports → Schedule.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-students.png',
          caption: 'The Students page is the central hub for most daily admin tasks.',
          alt: 'Students page with search, filters, and student list',
          annotations: [
            { id: 1, x: 35, y: 11, label: 'Search', description: 'Find any student instantly by name, ID, or class.' },
            { id: 2, x: 85, y: 11, label: 'Add Student', description: 'Enroll a walk-in student quickly.' },
            { id: 3, x: 25, y: 54, label: 'Student List', description: 'Click a row to open the student profile with tabs for Academic, Attendance, Finance, and Documents.' },
            { id: 4, x: 65, y: 11, label: 'Filters', description: 'Filter by grade, section, and status to find a specific group of students for a bulk action.' },
          ],
        },
        {
          type: 'callout',
          variant: 'success',
          title: 'Use bulk actions to save time',
          body: 'Many repetitive tasks — assigning fee plans, sending notifications, promoting students to the next grade — can be done in bulk. Select multiple students with the checkbox column, then use the "Bulk Actions" toolbar. End-of-year promotions can be done for an entire class in seconds.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'A teacher cannot see their class in the attendance module. What do I check?',
              a: 'Go to /academics/classes, find the relevant class and section, and verify the teacher is assigned as the class teacher or subject teacher for that section. Also check that the timetable for that class is published at /timetable — unpublished timetables prevent attendance marking.',
            },
            {
              q: 'How do I promote all Grade 5 students to Grade 6 at the end of the year?',
              a: 'Go to /students, filter by Grade 5. Select all students using the header checkbox. Click "Bulk Actions" → "Promote to Next Grade". Select the target grade (Grade 6) and section assignments. Review the summary, then confirm. The system creates new enrollment records for the new academic year while preserving all historical data.',
            },
            {
              q: 'A parent says their invoice is wrong. How do I correct it?',
              a: `Open the student's profile → Finance tab. Find the invoice in question. Click the three-dot menu and choose "Void Invoice". Select a reason from the dropdown (Incorrect Amount, Wrong Fee Category, etc.) and add a note. Then click "Generate New Invoice" and enter the correct details. The voided invoice remains on record for audit purposes.`,
            },
            {
              q: 'How do I handle a student transfer mid-year?',
              a: `Go to the student's profile. Click the three-dot menu (top-right of the profile card) and select "Transfer Student". Choose the destination class/section and the effective date. The system transfers attendance responsibilities to the new class teacher from that date forward. Past records stay with the original class.`,
            },
            {
              q: 'The admissions page shows applications I cannot approve because there are no seats available. What do I do?',
              a: 'Seat limits are configured per class section in /academics/classes. Open the relevant class, go to the "Capacity" tab, and increase the maximum enrolment number. Then return to /admissions to approve the application. You can also add a new section to the grade to create additional capacity.',
            },
            {
              q: 'Can I generate report cards from Student Diwan?',
              a: `Yes. Go to /reports → Academic → Report Cards. Select the class, term, and report template. Click "Generate". The system compiles each student's grades, attendance, and teacher comments into a formatted PDF. You can bulk-print all report cards for a class or send them individually to parent email addresses.`,
            },
          ],
        },
      ],
    },
    {
      id: 'school-admin-help',
      number: 7,
      title: 'Help Centre & Support',
      icon: 'LifeBuoy',
      summary: 'Find guidance for daily operations, share resources with staff, and get support when you need it.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Your Help Centre\n\nThe Help Centre gives you access to the School Administrator Guide and all other role guides — making it easy to onboard new teachers, support parents with their portal, and train your finance team. Navigate to `/help` at any time or press **Alt + Z** (Windows) / **⌘ Shift + Z** (Mac) to open it instantly.\n\nThe Guide Hub at `/help/guides` contains guides for every role in your school. As School Admin, you are the first point of contact for staff and parents — use these guides to answer common questions quickly.",
        },
        {
          type: 'steps',
          title: 'How to Open the Help Centre',
          steps: [
            {
              title: 'Press the Keyboard Shortcut',
              description: 'Alt + Z (Windows) or ⌘ Shift + Z (Mac) opens the Help Centre from any page without losing your current context.',
            },
            {
              title: 'Click Help in the Sidebar',
              description: 'The Help icon sits at the bottom of the left navigation sidebar. Click it to open the Help Home page (/help).',
            },
            {
              title: 'Go to the Guide Hub',
              description: 'From Help Home, click "Browse All Role Guides" or navigate directly to /help/guides to see the full library of role manuals.',
            },
            {
              title: 'Use the NeedHelp Widget',
              description: 'Click the floating ✦ button (bottom-right of any page) to report a system issue or request assistance from the platform support team.',
            },
          ],
        },
        {
          type: 'table',
          caption: 'Help Resources Available to School Admin',
          headers: ['Resource', 'What It Covers', 'Where to Find It'],
          rows: [
            ['School Administrator Guide', 'Academic setup, student enrollment, fee configuration, timetables, and daily operations', '/help/guides/school-admin'],
            ['Teacher Guide', 'Share with teachers — classes, attendance, gradebook, leave, and communication', '/help/guides/teacher'],
            ['Parent & Guardian Guide', 'Share with parents — portal login, fee payments, grades, and messaging', '/help/guides/parent'],
            ['Student Guide', 'Share with students — timetable, grades, library, and assignments', '/help/guides/student'],
            ['Accountant Guide', 'Share with finance staff — fee collection, invoicing, expenses, and reports', '/help/guides/accountant'],
            ['Administrator Manual (PDF)', 'Printable offline reference — ideal for staff training days without internet access', 'Help Centre → Downloads'],
            ['NeedHelp Widget', 'Submit system issues or data discrepancies directly to platform support', 'Floating ✦ button — any page'],
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Use Guides to Onboard New Staff',
          body: 'When a new teacher or staff member joins mid-term, share their role guide URL directly from /help/guides. The guides cover the login process, first-day setup, and every core workflow — reducing the time you spend on one-on-one training. For printing, use the PDF download on the Help Centre page.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'A teacher says they cannot find how to record grades. What do I share with them?',
              a: 'Send them to the Teacher Guide at /help/guides/teacher — Chapter 5 (Gradebook & Exams) covers entering marks, creating assessments, and publishing results step by step.',
            },
            {
              q: 'A parent cannot log in to their portal. How do I help them?',
              a: "Ask them to click 'Forgot Password' on the login page and enter their registered email. If the account is missing, go to /users → Add User → Parent, create the account, and share the login credentials. The Parent Guide at /help/guides/parent covers the full login process.",
            },
            {
              q: 'How do I raise a support request for a system issue?',
              a: 'Click the floating ✦ button (NeedHelp widget) on any page and describe the issue with as much detail as possible — include the page URL, what action you were taking, and any error message shown. For urgent issues, contact your Super Administrator, who can escalate to platform support.',
            },
            {
              q: 'Can I get a printable version of the staff guides for a training day?',
              a: 'Yes. Go to the Help Centre at /help and use the Downloads section to generate a PDF of the Administrator Guide. For other roles, the individual guide pages are printer-friendly — use your browser\'s Print function (Ctrl+P / ⌘+P) on any guide page.',
            },
          ],
        },
      ],
    },
  ],
};
