import type { UserGuide } from '@/lib/userGuides/types';

export const teacherGuide: UserGuide = {
  id: 'teacher',
  role: 'Teacher',
  title: 'Teacher Guide',
  tagline: 'Everything you need to manage your classes, take attendance, record grades, and communicate with your school.',
  audience: 'Classroom teachers, subject teachers, and homeroom teachers who use Student Diwan daily.',
  icon: 'Presentation',
  gradient: 'from-emerald-600 to-teal-700',
  accentHex: '#059669',
  badgeBg: 'bg-emerald-100 dark:bg-emerald-950/40',
  badgeText: 'text-emerald-700 dark:text-emerald-300',
  estimatedMinutes: 30,
  version: '1.0.0',
  lastUpdated: '2026-07-17',
  chapters: [
    {
      id: 'intro',
      number: 1,
      title: 'Introduction for Teachers',
      icon: 'Presentation',
      summary: 'Understand what Student Diwan offers you as a teacher, what you can and cannot do, and how your daily workflow fits into the system.',
      blocks: [
        {
          type: 'text',
          markdown: `## Welcome, Teacher!

Student Diwan gives you a **focused, clutter-free workspace** for the tasks that matter most: taking attendance, recording grades, viewing your timetable, and managing your professional leave.

You do **not** need to worry about school-wide configuration, fee management, or HR payroll — those are handled by the School Admin and HR Manager. Your view of Student Diwan is scoped to the classes and subjects assigned to you.

### Your Daily Tools

| Tool | Where | What you do |
|------|-------|-------------|
| My Dashboard | / | See today's schedule, pending tasks, notifications |
| Attendance | /attendance | Mark present / absent / late for each class period |
| Gradebook | /academics | Enter assessment scores, view class averages |
| Timetable | /timetable | View your weekly teaching schedule |
| Leave | /hr/staff | Apply for personal or sick leave |
| Reports | /reports | Class attendance report, student grade report |

### What teachers cannot access

- Other teachers' gradebooks or classes (unless you are a co-teacher)
- Student fee information (Finance tab on student profiles is hidden)
- HR payroll data
- System settings or user management`,
        },
        {
          type: 'table',
          caption: 'Teacher permissions in Student Diwan',
          headers: ['Action', 'Class Teacher', 'Subject Teacher', 'Co-Teacher'],
          rows: [
            ['Mark attendance', '✅ Own class, all periods', '✅ Own subject periods only', '✅ Shared class'],
            ['Override attendance', '✅ Own class (with reason)', '❌', '❌'],
            ['Enter grades', '✅ All subjects in own class', '✅ Own subject only', '✅ Shared class'],
            ['View student profile (academic)', '✅ Full academic view', '✅ Limited', '✅ Shared class'],
            ['View student profile (finance)', '❌', '❌', '❌'],
            ['Add student remarks / comments', '✅', '✅ Own subject', '✅'],
            ['Apply for leave', '✅', '✅', '✅'],
            ["Approve others' leave", '❌', '❌', '❌'],
            ['View class timetable', '✅', '✅ Own subject slots', '✅'],
            ['Export class report', '✅', '✅ Own subject', '✅'],
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Class teacher vs subject teacher',
          body: 'A class teacher is the primary responsible teacher for a section (e.g., Grade 4B). A subject teacher teaches a specific subject across multiple sections. You may be both — for example, the class teacher of Grade 4B and the Math teacher for Grades 4A, 4B, and 4C. Your permissions adjust automatically based on these assignments.',
        },
        {
          type: 'steps',
          title: 'Getting oriented on your first day',
          steps: [
            {
              title: 'Log in and check your profile',
              description: 'Use the credentials from your welcome email. After logging in, click your avatar (top-right) to confirm your name, email, and assigned classes are correct.',
            },
            {
              title: 'Review your timetable',
              description: 'Navigate to /timetable. Confirm that all your assigned periods and subjects are listed. If a subject or class is missing, inform your School Admin.',
            },
            {
              title: 'Explore the student list',
              description: "Go to /students and filter by your assigned class. Familiarise yourself with the students' names and the information available on their profiles.",
            },
            {
              title: 'Try marking attendance',
              description: `Go to /attendance and select today's date and your class. Even if school hasn"t started, you can explore the interface and understand how marking works.`,
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/teacher-dashboard.png',
          caption: "The teacher dashboard shows today's schedule, pending tasks, and class summaries.",
          alt: 'Teacher dashboard with timetable widget, attendance pending alert, and class summary cards',
          annotations: [
            { id: 1, x: 7, y: 50, label: 'Sidebar', description: 'Navigation: Dashboard, My Classes, Attendance, Gradebook, Timetable, Leave, Reports.' },
            { id: 2, x: 50, y: 20, label: "Today's Schedule", description: 'A compact timetable showing your periods for today with class name and subject.' },
            { id: 3, x: 50, y: 46, label: 'Pending Tasks', description: 'Alerts for: attendance not yet marked for today, assessments due for grading, leave status updates.' },
            { id: 4, x: 85, y: 4, label: 'Profile', description: 'Access your profile and notification preferences.' },
          ],
        },
        {
          type: 'table',
          caption: 'Keyboard Shortcuts — Quick Navigation',
          headers: ['Module', 'Windows / Linux', 'macOS'],
          rows: [
            ['Dashboard', 'Alt + D', '⌘ Shift + D'],
            ['Attendance', 'Alt + W', '⌘ Shift + W'],
            ['Gradebook', 'Alt + J', '⌘ Shift + J'],
            ['Timetable', 'Alt + T', '⌘ Shift + T'],
            ['Classes', 'Alt + C', '⌘ Shift + C'],
            ['Library', 'Alt + L', '⌘ Shift + L'],
            ['Messages', 'Alt + M', '⌘ Shift + M'],
            ['Notifications', 'Alt + N', '⌘ Shift + N'],
            ['Calendar', 'Alt + X', '⌘ Shift + X'],
            ['Help Center', 'Alt + Z', '⌘ Shift + Z'],
            ['Assignments', 'Alt + AM', '⌘ Shift + AM'],
            ['Assessments', 'Alt + AE', '⌘ Shift + AE'],
            ['Achievements', 'Alt + AC', '⌘ Shift + AC'],
            ['Subjects', 'Alt + S', '⌘ Shift + S'],
            ['Flashcards', 'Alt + FL', '⌘ Shift + FL'],
            ['Parent-Teacher Meetings', 'Alt + PT', '⌘ Shift + PT'],
            ['Coding Lab', 'Alt + CL', '⌘ Shift + CL'],
            ['Plagiarism Checker', 'Alt + PC', '⌘ Shift + PC'],
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
      summary: 'Log in with your teacher credentials, understand your dashboard widgets, and use the top bar effectively.',
      blocks: [
        {
          type: 'text',
          markdown: `## Logging In

You received a welcome email with the subject **"Welcome to Student Diwan — Set Your Password"**. Click the link in that email to set your password. Links expire after 72 hours — if yours has expired, use "Forgot Password?" on the login page.

Log in at your school's Student Diwan URL with your school email address and the password you set.

## Your Dashboard Explained

The teacher dashboard at **/** shows information relevant to **you and your classes only**. It does not show school-wide statistics (those are for School Admin and Super Admin).

### Dashboard Widgets

- **Today's Schedule** — Your teaching periods for today, in chronological order. Each card shows the period time, class, section, and subject. Click a card to jump to that class's attendance form.
- **Pending Attendance** — A red badge appears if you have a period today where attendance has not yet been marked. Marking attendance as soon as students are seated is considered best practice.
- **My Classes** — Cards for each class/section you are assigned to. Shows total students, today's attendance rate (once marked), and a link to the gradebook.
- **Recent Notifications** — Messages from the School Admin, leave approval updates, and system announcements.`,
        },
        {
          type: 'steps',
          title: 'Setting your password and logging in',
          steps: [
            {
              title: 'Open the welcome email',
              description: "Check your school email inbox for the welcome message from Student Diwan. If you can't find it, check your spam folder or ask your School Admin to resend the invitation.",
            },
            {
              title: 'Set your password',
              description: 'Click "Set Your Password" in the email. Enter a password with at least 10 characters. Click "Confirm". You are redirected to the login page.',
            },
            {
              title: 'Sign in',
              description: 'Enter your school email and the password you just created. Click "Sign In". You land on your teacher dashboard.',
              tip: "Add the login URL to your browser bookmarks or your phone's home screen for quick morning access.",
            },
            {
              title: 'Verify your class assignments',
              description: 'On the dashboard, check the "My Classes" section. Each class you are assigned to should appear here. If a class is missing, contact your School Admin.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/teacher-dashboard.png',
          caption: "Teacher dashboard showing today's schedule and class cards.",
          alt: 'Teacher dashboard with schedule widget, my classes section, and notifications panel',
          annotations: [
            { id: 1, x: 25, y: 30, label: "Today's Schedule", description: "Periods for today. Click any card to go directly to that period's attendance form." },
            { id: 2, x: 70, y: 30, label: 'Pending Attendance Alert', description: 'Red badge shows periods where attendance has not been marked yet.' },
            { id: 3, x: 25, y: 65, label: 'My Classes', description: "One card per class. Shows student count and today's attendance rate." },
            { id: 4, x: 44, y: 4, label: 'Quick Action', description: 'Shortcut to Mark Attendance, Enter Grades, or Apply for Leave.' },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Switch the interface to Arabic',
          body: 'Click the language toggle (EN/AR) in the top bar to switch the entire interface to Arabic with right-to-left layout. Student names, parent names, and report cards also display in Arabic when this mode is active.',
        },
      ],
    },
    {
      id: 'classes-timetable',
      number: 3,
      title: 'My Classes & Timetable',
      icon: 'CalendarDays',
      summary: 'View your weekly timetable, see your assigned classes and subjects, and access individual student profiles.',
      blocks: [
        {
          type: 'text',
          markdown: `## Your Timetable

Navigate to **/timetable** to see your full weekly teaching schedule. The timetable is published by your School Admin and you cannot edit it — if you need a change, contact the School Admin.

### Reading Your Timetable

The timetable is a grid:
- **Rows** = time periods (e.g., Period 1: 07:30–08:15, Period 2: 08:15–09:00, …)
- **Columns** = school days (Sunday–Thursday or Monday–Friday depending on your school)
- **Cells** = your teaching assignment for that slot: **class name + subject**

Empty cells mean no teaching assignment in that period — you may have free periods for preparation.

### My Classes

Click "My Classes" in the left sidebar (or navigate to /academics/classes) to see a card for each class you are assigned to. Each card shows:

- Class name and section (e.g., Grade 4 — Section B)
- Number of students
- Your role (Class Teacher / Subject Teacher)
- Subjects you teach in this class
- A link to the **Student List** and **Gradebook**

### Viewing Student Profiles

From the class card, click "Student List" to see all students in that class. Click any student's name to open their profile. You can view their personal details, academic history, and attendance record. You **cannot** see their finance information.`,
        },
        {
          type: 'steps',
          title: "Finding a student's attendance history",
          steps: [
            {
              title: 'Open your class',
              description: 'Click "My Classes" in the sidebar and select the relevant class card.',
            },
            {
              title: 'Open the Student List',
              description: 'Click "Student List" on the class card to see all students in that section.',
            },
            {
              title: 'Open the student profile',
              description: "Click the student's name. The profile page opens with tabs at the top.",
            },
            {
              title: 'Go to the Attendance tab',
              description: `Click "Attendance" in the profile tabs. You'll see a monthly calendar grid: green = present, red = absent, yellow = late, grey = no school. The percentage is shown at the top.`,
              tip: "If you believe a student's attendance record is wrong, contact your School Admin — only they can override marks.",
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/admin-timetable.png',
          caption: 'The timetable view — read-only for teachers, showing your weekly schedule.',
          alt: 'Timetable grid with periods as rows and days as columns, showing class and subject assignments',
          annotations: [
            { id: 1, x: 20, y: 20, label: 'Class Selector', description: 'If you teach multiple classes, switch between them here.' },
            { id: 2, x: 50, y: 50, label: 'Schedule Grid', description: 'Your teaching assignments for the week. Click a cell to see period details.' },
            { id: 3, x: 80, y: 10, label: 'Week Navigation', description: "Move forward or back to view other weeks' schedules." },
            { id: 4, x: 50, y: 85, label: 'Free Periods', description: 'Empty cells are your free/prep periods — no student is assigned to these slots.' },
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Timetable changes',
          body: 'If your timetable changes mid-year (e.g., a subject is reassigned), your School Admin publishes a new version. You will receive a notification when a new timetable takes effect. Always check your timetable after receiving a "Timetable Updated" notification.',
        },
      ],
    },
    {
      id: 'attendance',
      number: 4,
      title: 'Attendance Management',
      icon: 'ClipboardCheck',
      summary: 'Mark daily attendance for your classes, handle late arrivals and early departures, and view attendance summaries.',
      blocks: [
        {
          type: 'text',
          markdown: `## Taking Attendance in Student Diwan

Attendance is one of the most important daily tasks in the system. Accurate attendance records directly affect student progression, parent notifications, and school compliance reports.

### When to Mark Attendance

- Mark attendance **at the start of each class period**.
- The system allows marking from **15 minutes before** the period starts to **30 minutes after** it ends.
- If you miss the window, contact your School Admin to enter the record manually.

### Attendance Statuses

| Status | Icon | Meaning |
|--------|------|---------|
| Present | ✅ Green | Student attended the full period |
| Absent | ❌ Red | Student did not attend |
| Late | 🕐 Amber | Student arrived after the roll was called |
| Excused | 📄 Blue | Absent with an approved excuse (medical, official) |
| Early Departure | 🚪 Purple | Student left before the period ended |

### Bulk Marking

If most of your class is present, use the **"Mark All Present"** button at the top of the attendance form — then individually change the status for the absent or late students. This is much faster than marking each student one by one.`,
        },
        {
          type: 'steps',
          title: 'Marking attendance for a class period',
          steps: [
            {
              title: 'Navigate to Attendance',
              description: `Click "Attendance" in the sidebar, or from your dashboard click the period card in "Today's Schedule".`,
            },
            {
              title: 'Select the class and date',
              description: 'Use the dropdowns to select your class, section, and the date (defaults to today). The student list loads automatically.',
            },
            {
              title: 'Select the period',
              description: 'Choose the period from the "Period" dropdown (Period 1, Period 2, etc.). Only your assigned periods appear.',
            },
            {
              title: 'Mark all present, then adjust',
              description: 'Click "Mark All Present" to set every student to Present. Then click the status icon next to any absent or late student to change their status.',
              tip: "Click a student's name to open a pop-over with options: Present, Absent, Late, Excused, or Early Departure. You can also add a note for the record.",
            },
            {
              title: 'Submit',
              description: 'Click "Submit Attendance". A confirmation banner appears. The record is saved immediately and visible to the School Admin and parents (via the parent portal).',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/teacher-attendance.png',
          caption: 'The attendance marking form — period selector, student list, and status controls.',
          alt: 'Attendance form showing class selector, date picker, student list with status buttons',
          annotations: [
            { id: 1, x: 20, y: 12, label: 'Class & Period', description: 'Select the class, section, and period. Only your assigned classes and periods appear.' },
            { id: 2, x: 70, y: 12, label: 'Mark All Present', description: 'One click marks every student Present. Then adjust exceptions individually.' },
            { id: 3, x: 50, y: 54, label: 'Student List', description: 'Each row is a student. Status badges are colour-coded. Click a badge to change the status.' },
            { id: 4, x: 85, y: 54, label: 'Notes Icon', description: 'Add a short note to any attendance record — useful for excused absences.' },
            { id: 5, x: 50, y: 88, label: 'Submit Button', description: 'Saves and locks the attendance for this period. You cannot edit it after 30 minutes.' },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Mark attendance on your phone',
          body: 'Student Diwan is fully responsive. Open it in your phone browser, log in, and mark attendance from the classroom without needing a computer. The interface adapts to smaller screens automatically.',
        },
      ],
    },
    {
      id: 'gradebook',
      number: 5,
      title: 'Gradebook & Exams',
      icon: 'FileSpreadsheet',
      summary: 'Enter assessment scores, manage exam results, add comments, and generate class grade reports.',
      blocks: [
        {
          type: 'text',
          markdown: `## The Gradebook

The gradebook is where you record every assessment score for your students. Navigate to **My Classes → [Class Name] → Gradebook** or via the sidebar.

### Assessment Types

Your School Admin configures the assessment types for each subject. Common types include:

| Type | Abbreviation | Typical weight |
|------|-------------|----------------|
| Class Participation | CP | 10% |
| Homework | HW | 10% |
| Quiz | QZ | 15% |
| Mid-Term Exam | MT | 25% |
| Project / Assignment | PR | 15% |
| Final Exam | FE | 25% |

The weights are set by the School Admin. Your job is to enter the **scores** — the system calculates the weighted total automatically.

### Gradebook Views

- **By Student** — See all assessments and scores for one student
- **By Assessment** — Enter scores for all students for one assessment (most efficient)
- **Summary** — Class average, highest, lowest, and distribution chart for each assessment

### Locking Grades

Once the term ends, the School Admin locks the gradebook. After locking, you can **view** grades but not edit them. If you need to correct a locked grade, request the School Admin to unlock the record.`,
        },
        {
          type: 'steps',
          title: 'Entering scores for an assessment',
          steps: [
            {
              title: 'Open the Gradebook',
              description: 'Go to My Classes → [Your Class] → Gradebook. Alternatively, click "Gradebook" in the sidebar and select your class.',
            },
            {
              title: 'Create or select an assessment',
              description: `If the assessment doesn't exist yet, click "New Assessment". Enter: Assessment Name (e.g., "Quiz 2 — Chapter 4"), Type (Quiz), Date, and Maximum Score (e.g., 20). Click "Save".`,
              tip: 'If your School Admin has pre-created the assessment template, it already appears in the list — just click it to enter scores.',
            },
            {
              title: 'Switch to "Enter Scores" view',
              description: 'With the assessment selected, click the "Enter Scores" button. A table appears with one row per student.',
            },
            {
              title: "Enter each student's score",
              description: `Click the score cell next to a student's name and type their score (0–maximum). Press Tab to move to the next student. Absent students can be marked "Absent" using the checkbox.`,
            },
            {
              title: 'Save and review',
              description: 'Click "Save Scores". The gradebook instantly shows the class average and highlights scores below the pass mark in red. You can add individual student comments by clicking the comment icon on any row.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/teacher-gradebook.png',
          caption: 'The gradebook showing assessments, student scores, and class average.',
          alt: 'Gradebook view with assessment list on the left, student score grid in the centre, and summary statistics',
          annotations: [
            { id: 1, x: 20, y: 30, label: 'Assessment List', description: 'All assessments for this subject and term. Click one to view or enter scores.' },
            { id: 2, x: 60, y: 30, label: 'Score Grid', description: 'One row per student. Click any cell to enter or edit the score.' },
            { id: 3, x: 85, y: 30, label: 'Class Average', description: 'Updates in real time as you enter scores. Red if below the configured passing threshold.' },
            { id: 4, x: 60, y: 88, label: 'Save Scores', description: 'Saves all entered scores. Unsaved scores show a yellow dot on the cell.' },
            { id: 5, x: 20, y: 10, label: 'New Assessment', description: 'Create a new assessment entry for this subject.' },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Adding student comments for report cards',
          body: `Report cards include a teacher's comment per subject. Add comments from the gradebook by clicking a student"s name and selecting "Add Report Card Comment". Keep comments constructive and focused on progress. Comments are locked once the School Admin generates the report cards.`,
        },
      ],
    },
    {
      id: 'leave-communication',
      number: 6,
      title: 'Leave & Communication',
      icon: 'MessageSquare',
      summary: 'Apply for leave, track your leave balance, manage notifications, and communicate within the system.',
      blocks: [
        {
          type: 'text',
          markdown: `## Managing Your Leave

As a teacher, you apply for leave through Student Diwan's HR module. Your School Admin (or HR Manager, depending on your school's setup) reviews and approves or rejects your request.

### Leave Types

| Type | Paid? | Documentation required |
|------|-------|------------------------|
| Annual Leave | Yes | None — planned in advance |
| Sick Leave | Yes (up to policy limit) | Medical certificate for >2 days |
| Emergency Leave | Yes (up to 3 days/year) | None |
| Unpaid Leave | No | Written request |
| Study/Exam Leave | Varies | Exam schedule or institution letter |

### Leave Balance

Your current leave balance is shown on the leave application form and on your profile page. The balance reflects: entitlement for the year minus days taken.

## Notifications and Communication

Student Diwan is used for **role-relevant notifications**:

- **From School Admin** — announcements, timetable changes, meeting notices
- **System-generated** — leave approval/rejection, attendance reminders, gradebook lock alerts
- **Parent messages** — if your school has enabled the parent messaging feature, parents can send queries that appear in your notification centre (bell icon)

All notifications appear in the bell icon (top bar). Click it to open the notification centre. Mark notifications as read individually or use "Mark All as Read".`,
        },
        {
          type: 'steps',
          title: 'Applying for leave',
          steps: [
            {
              title: 'Open the Leave form',
              description: 'Click "Leave" in the left sidebar (under the HR section), or navigate to /hr/staff → My Leave.',
            },
            {
              title: 'Click "Apply for Leave"',
              description: 'The blue "Apply for Leave" button is at the top-right of the leave page.',
            },
            {
              title: 'Fill in the leave details',
              description: 'Select: Leave Type, Start Date, End Date, and a Reason (text field). The number of working days is calculated automatically, excluding weekends and public holidays.',
              tip: 'Apply for leave as early as possible — especially for annual leave. This helps the School Admin arrange substitute teachers in advance.',
            },
            {
              title: 'Attach documentation if required',
              description: 'For sick leave over 2 days, click "Attach File" and upload your medical certificate (PDF or image, max 5 MB).',
            },
            {
              title: 'Submit and monitor status',
              description: 'Click "Submit Application". Your leave request appears on the leave page with status "Pending". You receive a notification when it is approved or rejected.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/hr-leave.png',
          caption: 'The leave application page with leave balance, history, and the apply button.',
          alt: 'Leave page showing leave balance cards, leave history table, and Apply for Leave button',
          annotations: [
            { id: 1, x: 25, y: 20, label: 'Leave Balance', description: 'Shows your remaining days for each leave type (Annual, Sick, Emergency).' },
            { id: 2, x: 85, y: 12, label: 'Apply for Leave', description: 'Opens the leave application form.' },
            { id: 3, x: 50, y: 55, label: 'Leave History', description: 'Past and pending leave requests with status: Pending, Approved, or Rejected.' },
            { id: 4, x: 85, y: 55, label: 'Cancel Leave', description: 'Cancel a pending or future approved leave request. Rejected and past leave cannot be cancelled.' },
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Arrange a substitute in advance',
          body: 'Student Diwan will flag your classes as unattended if you are on leave and no substitute is arranged. Coordinate with your School Admin when you apply for leave, especially for planned absences, so a substitute teacher can be assigned and students are not left without supervision.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'I missed the attendance window for a period. What should I do?',
              a: 'Contact your School Admin immediately. Only School Admins and Super Admins can enter attendance after the 30-minute window has closed. Provide them with the class, period, date, and the status for each student. They will enter it and log the override reason.',
            },
            {
              q: 'A student says I entered their score incorrectly. Can I change it?',
              a: `Yes, as long as the gradebook is not locked (before the term ends). Go to the gradebook, find the assessment, click "Enter Scores", and update the student's score. If the gradebook is locked, ask your School Admin to temporarily unlock it for that assessment.`,
            },
            {
              q: 'My class shows 0 students in the gradebook, but I have 25 students in attendance. Why?',
              a: 'This usually happens when students are enrolled in the class but not yet linked to your subject. Contact your School Admin to verify the subject assignment. Go to /academics/classes → your class → Subjects and confirm your name is listed as the teacher for the relevant subject.',
            },
            {
              q: 'Can parents see the grades I enter?',
              a: 'No — grades are only visible to parents after the School Admin generates and publishes the report card for the term. Day-to-day gradebook entries are visible to teachers and school admins only. Attendance, however, is visible to parents in real time through the parent portal.',
            },
            {
              q: 'How do I see which students have low attendance in my class?',
              a: `Go to /reports → Attendance → Class Attendance Report. Select your class and the date range. Click "Generate Report". The report shows each student's attendance count and percentage. Students with attendance below the school threshold (typically 75%) are highlighted in red.`,
            },
            {
              q: 'My leave was rejected. Can I appeal?',
              a: "Student Diwan does not have a formal appeal workflow — that is handled through your school's HR process. You can see the rejection reason in your leave history (click the leave entry to expand it). Speak directly with your School Admin or HR Manager to discuss the decision.",
            },
          ],
        },
      ],
    },
    {
      id: 'teacher-help',
      number: 7,
      title: 'Help Centre & Support',
      icon: 'LifeBuoy',
      summary: 'Find answers to teaching workflow questions and get help when something is not working.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Your Help Centre\n\nThe Help Centre at `/help` is available to you at all times and gives you access to the Teacher Guide, a searchable article library, and a direct support channel. Whether you need a quick reminder of how to publish grades or need to report a technical issue, the Help Centre is your first stop.\n\nPress **Alt + Z** (Windows) or **⌘ Shift + Z** (Mac) from any page to open it instantly.",
        },
        {
          type: 'steps',
          title: 'How to Open the Help Centre',
          steps: [
            {
              title: 'Press Alt + Z or ⌘ Shift + Z',
              description: 'Jump to the Help Centre from anywhere in the app using this keyboard shortcut — useful during a busy period when you need a quick answer.',
            },
            {
              title: 'Click Help in the Sidebar',
              description: 'The Help icon is at the bottom of the left sidebar. Click it to open the Help Home page at /help.',
            },
            {
              title: 'Open the Teacher Guide',
              description: 'From Help Home, click "Browse All Role Guides" and select the Teacher card, or go directly to /help/guides/teacher.',
            },
            {
              title: 'Use the NeedHelp Widget',
              description: 'Click the floating ✦ button (bottom-right) to report a technical issue, data error, or missing feature to the platform support team.',
            },
          ],
        },
        {
          type: 'table',
          caption: 'Help Resources Available to Teachers',
          headers: ['Resource', 'What It Covers', 'Where to Find It'],
          rows: [
            ['Teacher Guide — Chapter 3', 'My Classes & Timetable: viewing your weekly schedule and assigned subjects', '/help/guides/teacher'],
            ['Teacher Guide — Chapter 4', 'Attendance Management: marking, correcting, and reporting on class attendance', '/help/guides/teacher'],
            ['Teacher Guide — Chapter 5', 'Gradebook & Exams: entering marks, setting up assessments, and publishing results', '/help/guides/teacher'],
            ['Teacher Guide — Chapter 6', 'Leave & Communication: applying for leave and messaging students or parents', '/help/guides/teacher'],
            ['Student Guide', 'Understand the student experience — useful when helping a student navigate their portal', '/help/guides/student'],
            ['Help Category Browser', 'Searchable articles on academic workflows, gradebook issues, and reporting', '/help'],
            ['NeedHelp Widget', 'Report technical problems directly to platform support with one click', 'Floating ✦ button — any page'],
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Quick Chapter Navigation',
          body: 'The Teacher Guide is split into six chapters — use the chapter list on the left panel of the guide to jump directly to Attendance (Ch. 4), Gradebook (Ch. 5), or Leave (Ch. 6) without reading from the beginning.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'I entered wrong marks for a student. Can I correct them after publishing?',
              a: 'Yes — go to Gradebook (/grades), locate the student and assessment, and click the mark to edit it. If the result has already been published to parents, re-publishing after the correction will update what parents see. If your school locks results after a certain date, contact your School Admin to unlock the record.',
            },
            {
              q: 'I marked a student absent by mistake. How do I correct attendance?',
              a: 'Go to Attendance (/attendance), select the date, and click the incorrect status for the student. Change it to the correct status (Present, Late, or Excused) and save. Corrections are logged with your name and timestamp for audit purposes.',
            },
            {
              q: 'I cannot see one of my assigned classes in the timetable. What do I do?',
              a: "If a class is missing from your timetable, the School Admin may not have assigned you to it yet, or the timetable may not have been published for the current term. Contact your School Admin to verify the assignment and confirm the timetable is active.",
            },
            {
              q: 'A student says they cannot see a grade I entered. Why?',
              a: "Grades are only visible to students and parents after the School Admin generates and publishes the report card for that term. Day-to-day gradebook entries are visible only to teachers and school admins. Ask your School Admin to publish the results when all marks are finalised.",
            },
            {
              q: 'Who do I contact if the system is slow or I see an error message?',
              a: 'First, try refreshing the page (Ctrl+R / ⌘+R). If the issue persists, click the floating ✦ button to open the NeedHelp widget and describe the problem — include the page you were on and the exact error text. You can also notify your School Admin, who can escalate to the Super Administrator.',
            },
          ],
        },
      ],
    },
  ],
};
